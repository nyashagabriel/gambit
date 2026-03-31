// supabase/functions/users.ts — GAMBIT TSL
// Handles: list · create · update · reset_pw · delete
// Role hierarchy enforced on the server: super_admin > company_admin > staff > user

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL     = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const JWT_SECRET       = Deno.env.get("GAMBIT_JWT_SECRET");
const FRONTEND_URL     = Deno.env.get("FRONTEND_URL");

if (!JWT_SECRET) throw new Error("GAMBIT_JWT_SECRET env var is not set");

const ISSUER = "gambit-tsl";
const ROLE_RANK: Record<string, number> = {
  user: 0, staff: 1, company_admin: 2, super_admin: 3,
};

const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin":  FRONTEND_URL ?? "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Authorization, Content-Type, apikey",
  "Content-Type": "application/json",
};

// ─── JWT verify ────────────────────────────────────────────────────────────────
function b64uDecode(s: string): Uint8Array {
  const b64 = s.replace(/-/g, "+").replace(/_/g, "/");
  const pad = b64.length % 4;
  return Uint8Array.from(atob(pad ? b64 + "=".repeat(4 - pad) : b64), (c) => c.charCodeAt(0));
}

async function verifyJwt(token: string): Promise<Record<string, unknown> | null> {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    const [hdr, bdy, sig] = parts;
    const key = await crypto.subtle.importKey(
      "raw", new TextEncoder().encode(JWT_SECRET),
      { name: "HMAC", hash: "SHA-256" }, false, ["verify"],
    );
    const valid = await crypto.subtle.verify(
      "HMAC", key, b64uDecode(sig), new TextEncoder().encode(`${hdr}.${bdy}`),
    );
    if (!valid) return null;
    const claims = JSON.parse(new TextDecoder().decode(b64uDecode(bdy)));
    if (claims.exp < Date.now() / 1000 || claims.iss !== ISSUER) return null;
    return claims;
  } catch {
    return null;
  }
}

// ─── Guards ────────────────────────────────────────────────────────────────────
// Actor can act on target only if actor has strictly higher rank
const canActOn = (actor: string, target: string) =>
  (ROLE_RANK[actor] ?? -1) > (ROLE_RANK[target] ?? -1);

// Actor can see/modify data for companyId — super_admin bypasses
const sameCompany = (claims: Record<string, unknown>, companyId: string) =>
  claims.role === "super_admin" || claims.company_id === companyId;

const ok  = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: CORS });

const err = (message: string, status = 400) =>
  new Response(JSON.stringify({ error: message }), { status, headers: CORS });

const logDbError = (scope: string, error: { code?: string; message?: string; details?: string; hint?: string } | null) => {
  if (!error) return;
  console.error(`[${scope}] error:`, {
    code: error.code,
    message: error.message,
    details: error.details,
    hint: error.hint,
  });
};

// ─── Handler ───────────────────────────────────────────────────────────────────
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
  if (req.method !== "POST")    return err("Method not allowed", 405);

  const bearer = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!bearer) return err("Unauthorized", 401);

  const claims = await verifyJwt(bearer);
  if (!claims) return err("Unauthorized", 401);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return err("Invalid JSON", 400);
  }

  const action = body.action as string | undefined;
  if (!action) return err("Missing action", 400);

  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? null;
  const db = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  // ── LIST ─────────────────────────────────────────────────────────────────────
  if (action === "list") {
    // company_admin sees their own company; super_admin sees all (or filtered by company_id)
    if (claims.role !== "super_admin" && claims.role !== "company_admin") {
      return err("Forbidden", 403);
    }

    const companyId = claims.role === "company_admin"
      ? String(claims.company_id)
      : (body.company_id as string | undefined) ?? null;

    const { data, error } = await db.rpc("list_users", {
      p_company_id: companyId,
    });

    if (error) {
      logDbError("users/list", error);
      return err("Failed to fetch users", 500);
    }
    return ok({ users: data });
  }

  // ── CREATE ───────────────────────────────────────────────────────────────────
  if (action === "create") {
    if (claims.role !== "super_admin" && claims.role !== "company_admin") {
      return err("Forbidden", 403);
    }

    const username  = (body.username as string | undefined)?.trim().toLowerCase();
    const password  = body.password as string | undefined;
    const role      = body.role as string | undefined;
    const fullName  = (body.full_name as string | undefined)?.trim() || null;
    const phone     = (body.phone as string | undefined)?.trim() || null;

    if (!username || !password || !role) return err("username, password and role are required", 400);
    if (password.length < 8)            return err("Password must be at least 8 characters", 422);
    if (!(role in ROLE_RANK))           return err("Invalid role", 422);
    if (!canActOn(claims.role as string, role)) return err("Cannot create a user with that role", 403);

    const targetCompany = claims.role === "super_admin"
      ? (body.company_id as string | undefined)
      : (claims.company_id as string);

    if (!targetCompany) return err("company_id is required", 400);
    if (!sameCompany(claims, targetCompany)) return err("Cannot create user outside your company", 403);

    const { data: hashData, error: hashErr } = await db.rpc("hash_password", {
      raw_password: password,
    });
    if (hashErr) return err("Service unavailable", 503);

    const { data, error } = await db.rpc("create_user", {
      p_company_id: targetCompany,
      p_username: username,
      p_password_hash: String(hashData),
      p_role: role,
      p_full_name: fullName,
      p_phone: phone,
      p_created_by: String(claims.sub),
    });

    if (error) {
      if (error.code === "23505") return err("Username already taken", 409);
      logDbError("users/create", error);
      return err("Failed to create user", 500);
    }

    const user = (data as Array<Record<string, unknown>> | null)?.[0];
    if (!user) return err("Failed to create user", 500);

    const { error: auditError } = await db.rpc("insert_audit_log", {
      p_actor_id: String(claims.sub),
      p_actor_role: String(claims.role),
      p_company_id: targetCompany,
      p_action: "CREATE_USER",
      p_target_type: "user",
      p_target_id: String(user.id),
      p_details: { username, role },
      p_ip_address: ip,
    });
    if (auditError) logDbError("users/create/audit", auditError);

    console.log(`[users/create] ok user=${username} role=${role}`);
    return ok({ user }, 201);
  }

  // ── UPDATE ───────────────────────────────────────────────────────────────────
  if (action === "update") {
    const userId = body.user_id as string | undefined;
    if (!userId) return err("user_id is required", 400);

    const { data: targetRows, error: fetchErr } = await db.rpc("get_user_scope", {
      p_user_id: userId,
    });

    const target = (targetRows as Array<{ id: string; role: string; company_id: string }> | null)?.[0];

    if (fetchErr || !target) return err("User not found", 404);

    // Users can update themselves; actors can update lower-rank users in same company
    const isSelf   = claims.sub === userId;
    const canManage = sameCompany(claims, target.company_id) &&
                      canActOn(claims.role as string, target.role);

    if (!isSelf && !canManage) return err("Forbidden", 403);

    const updates: Record<string, unknown> = {};
    if (body.is_active !== undefined && canManage) updates.is_active = Boolean(body.is_active);
    if (body.full_name !== undefined) updates.full_name = (body.full_name as string).trim() || null;
    if (body.phone     !== undefined) updates.phone     = (body.phone as string).trim() || null;

    if (Object.keys(updates).length === 0) return err("Nothing to update", 400);

    const { data, error } = await db.rpc("update_user", {
      p_user_id: userId,
      p_is_active: updates.is_active ?? null,
      p_full_name: updates.full_name ?? null,
      p_phone: updates.phone ?? null,
    });

    if (error) {
      logDbError("users/update", error);
      return err("Failed to update user", 500);
    }

    const user = (data as Array<Record<string, unknown>> | null)?.[0];
    if (!user) return err("Failed to update user", 500);

    const { error: auditError } = await db.rpc("insert_audit_log", {
      p_actor_id: String(claims.sub),
      p_actor_role: String(claims.role),
      p_company_id: (claims.company_id as string | undefined) ?? null,
      p_action: "UPDATE_USER",
      p_target_type: "user",
      p_target_id: userId,
      p_details: updates,
      p_ip_address: ip,
    });
    if (auditError) logDbError("users/update/audit", auditError);

    return ok({ user });
  }

  // ── RESET PASSWORD (admin-initiated) ─────────────────────────────────────────
  if (action === "reset_pw") {
    const userId      = body.user_id as string | undefined;
    const newPassword = body.new_password as string | undefined;

    if (!userId || !newPassword)  return err("user_id and new_password are required", 400);
    if (newPassword.length < 8)   return err("Password must be at least 8 characters", 422);

    const { data: targetRows, error: fetchErr } = await db.rpc("get_user_scope", {
      p_user_id: userId,
    });

    const target = (targetRows as Array<{ id: string; role: string; company_id: string }> | null)?.[0];

    if (fetchErr || !target) return err("User not found", 404);
    if (!sameCompany(claims, target.company_id) || !canActOn(claims.role as string, target.role)) {
      return err("Forbidden", 403);
    }

    const { data: hashData, error: hashErr } = await db.rpc("hash_password", {
      raw_password: newPassword,
    });
    if (hashErr) return err("Service unavailable", 503);

    const { error } = await db.rpc("reset_user_password", {
      p_user_id: userId,
      p_password_hash: String(hashData),
    });

    if (error) {
      logDbError("users/reset_pw", error);
      return err("Failed to reset password", 500);
    }

    const { error: auditError } = await db.rpc("insert_audit_log", {
      p_actor_id: String(claims.sub),
      p_actor_role: String(claims.role),
      p_company_id: (claims.company_id as string | undefined) ?? null,
      p_action: "RESET_USER_PASSWORD",
      p_target_type: "user",
      p_target_id: userId,
      p_details: null,
      p_ip_address: ip,
    });
    if (auditError) logDbError("users/reset_pw/audit", auditError);

    console.log(`[users/reset_pw] ok target=${userId}`);
    return ok({ message: "Password reset. User must change it on next login." });
  }

  // ── DELETE ───────────────────────────────────────────────────────────────────
  if (action === "delete") {
    const userId = body.user_id as string | undefined;
    if (!userId) return err("user_id is required", 400);

    const { data: targetRows, error: fetchErr } = await db.rpc("get_user_scope", {
      p_user_id: userId,
    });

    const target = (targetRows as Array<{ id: string; role: string; company_id: string }> | null)?.[0];

    if (fetchErr || !target) return err("User not found", 404);
    if (!sameCompany(claims, target.company_id) || !canActOn(claims.role as string, target.role)) {
      return err("Forbidden", 403);
    }

    const { error } = await db.rpc("delete_user", {
      p_user_id: userId,
    });

    if (error) {
      logDbError("users/delete", error);
      return err("Failed to delete user", 500);
    }

    const { error: auditError } = await db.rpc("insert_audit_log", {
      p_actor_id: String(claims.sub),
      p_actor_role: String(claims.role),
      p_company_id: (claims.company_id as string | undefined) ?? null,
      p_action: "DELETE_USER",
      p_target_type: "user",
      p_target_id: userId,
      p_details: null,
      p_ip_address: ip,
    });
    if (auditError) logDbError("users/delete/audit", auditError);

    console.log(`[users/delete] ok target=${userId}`);
    return ok({ message: "User deleted" });
  }

  return err("Unknown action", 400);
});