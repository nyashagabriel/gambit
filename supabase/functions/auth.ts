// supabase/functions/auth.ts — GAMBIT TSL
// Handles: login · me · change_password · set_recovery_email · create_company_admin
//
// Security model:
//   • login is the only unauthenticated action
//   • every other action requires a valid JWT in Authorization: Bearer <token>
//   • JWT is HS256 signed with GAMBIT_JWT_SECRET (server-only env var)
//   • passwords never appear in logs or error responses
//   • brute-force surface minimised — same error shape for bad user + bad password

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── Environment ───────────────────────────────────────────────────────────────
const SUPABASE_URL       = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY   = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const JWT_SECRET         = Deno.env.get("GAMBIT_JWT_SECRET");
const FRONTEND_URL       = Deno.env.get("FRONTEND_URL");

if (!JWT_SECRET) {
  // Fail loudly at boot — never use a default secret in production
  throw new Error("GAMBIT_JWT_SECRET env var is not set");
}

const ISSUER     = "gambit-tsl";
const TTL        = 60 * 60 * 24 * 7; // 7 days

// ─── CORS ──────────────────────────────────────────────────────────────────────
const VERCEL_GONYETI_ORIGIN = /^https:\/\/gonyeti-tls(?:-[a-z0-9-]+)*\.vercel\.app$/i;

function isAllowedOrigin(origin: string): boolean {
  if (FRONTEND_URL && origin === FRONTEND_URL) return true;
  return VERCEL_GONYETI_ORIGIN.test(origin);
}

function cors(req: Request): Record<string, string> {
  const origin = req.headers.get("origin")?.trim();
  const allowOrigin = origin && isAllowedOrigin(origin)
    ? origin
    : (FRONTEND_URL ?? "*");

  return {
    "Access-Control-Allow-Origin": allowOrigin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type, apikey",
    "Vary": "Origin",
    "Content-Type": "application/json",
  };
}

// ─── JWT ───────────────────────────────────────────────────────────────────────
function b64uEncode(buf: ArrayBuffer | string): string {
  const bytes = typeof buf === "string" ? new TextEncoder().encode(buf) : new Uint8Array(buf);
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

function b64uDecode(s: string): Uint8Array {
  const b64 = s.replace(/-/g, "+").replace(/_/g, "/");
  const pad = b64.length % 4;
  return Uint8Array.from(atob(pad ? b64 + "=".repeat(4 - pad) : b64), (c) => c.charCodeAt(0));
}

async function importHmac(usage: "sign" | "verify"): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(JWT_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    [usage],
  );
}

async function signJwt(payload: Record<string, unknown>): Promise<string> {
  const now    = Math.floor(Date.now() / 1000);
  const claims = { ...payload, iss: ISSUER, iat: now, exp: now + TTL };
  const hdr    = b64uEncode(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const bdy    = b64uEncode(JSON.stringify(claims));
  const msg    = `${hdr}.${bdy}`;
  const key    = await importHmac("sign");
  const sig    = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(msg));
  return `${msg}.${b64uEncode(sig)}`;
}

async function verifyJwt(token: string): Promise<Record<string, unknown> | null> {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    const [hdr, bdy, sig] = parts;
    const key   = await importHmac("verify");
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
  const headers = cors(req);
  const ok  = (data: unknown, status = 200) =>
    new Response(JSON.stringify(data), { status, headers });

  const err = (message: string, status = 400) =>
    new Response(JSON.stringify({ error: message }), { status, headers });

  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers });
  if (req.method !== "POST")    return err("Method not allowed", 405);

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

  // ── LOGIN (public) ───────────────────────────────────────────────────────────
  if (action === "login") {
    const username = (body.username as string | undefined)?.trim().toLowerCase();
    const password = body.password as string | undefined;

    if (!username || !password) return err("Missing credentials", 400);

    const { data, error } = await db.rpc("login", {
      p_username: username,
      p_password: password,
      p_ip:       ip,
    });

    if (error) {
      console.error("[auth/login] rpc error:", error.code);
      return err("Service unavailable", 503);
    }

    const row = data?.[0];
    if (!row || row.error) {
      // Intentionally vague — prevents username enumeration
      return err("Invalid credentials", 401);
    }

    const token = await signJwt({
      sub:           row.user_id,
      username:      row.username,
      full_name:     row.full_name ?? null,
      role:          row.role,
      company_id:    row.company_id ?? null,
      must_change_pw: row.must_change_pw ?? false,
    });

    console.log(`[auth/login] ok user=${row.username} role=${row.role}`);
    return ok({ token, user: row }, 200);
  }

  // All remaining actions require a valid JWT ────────────────────────────────
  const bearer = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!bearer) return err("Unauthorized", 401);

  const claims = await verifyJwt(bearer);
  if (!claims) return err("Unauthorized", 401);

  // ── ME ───────────────────────────────────────────────────────────────────────
  if (action === "me") {
    const { data, error } = await db.rpc("auth_me", {
      p_user_id: String(claims.sub),
    });

    if (error) {
      logDbError("auth/me", error);
      return err("Not found", 404);
    }

    const user = (data as Array<Record<string, unknown>> | null)?.[0];
    if (!user) return err("Not found", 404);
    return ok({ user });
  }

  // ── CHANGE PASSWORD ──────────────────────────────────────────────────────────
  if (action === "change_password") {
    const oldPassword = body.old_password as string | undefined;
    const newPassword = body.new_password as string | undefined;

    if (!oldPassword || !newPassword) return err("Missing passwords", 400);
    if (newPassword.length < 8)        return err("Password must be at least 8 characters", 422);

    const { data, error } = await db.rpc("change_password", {
      p_user_id:     claims.sub,
      p_old_password: oldPassword,
      p_new_password: newPassword,
    });

    if (error) {
      console.error("[auth/change_password] rpc error:", error.code);
      return err("Service unavailable", 503);
    }
    if (data?.error) return err(data.error, 400);

    console.log(`[auth/change_password] ok user=${claims.username}`);
    return ok({ message: "Password updated" });
  }

  // ── SET RECOVERY EMAIL ───────────────────────────────────────────────────────
  if (action === "set_recovery_email") {
    const email = (body.email as string | undefined)?.trim().toLowerCase();
    if (!email || !email.includes("@")) return err("Invalid email", 422);

    const { error } = await db.rpc("set_recovery_email", {
      p_user_id: String(claims.sub),
      p_email: email,
    });

    if (error) {
      logDbError("auth/set_recovery_email", error);
      return err("Failed to update email", 500);
    }
    return ok({ message: "Recovery email saved" });
  }

  // ── CREATE COMPANY ADMIN (super_admin only) ───────────────────────────────────
  if (action === "create_company_admin") {
    if (claims.role !== "super_admin") return err("Forbidden", 403);

    const companyId = body.company_id as string | undefined;
    const username  = (body.username as string | undefined)?.trim().toLowerCase();
    const password  = body.password as string | undefined;
    const fullName  = (body.full_name as string | undefined)?.trim() || null;

    if (!companyId || !username || !password) return err("Missing required fields", 400);
    if (password.length < 8) return err("Password must be at least 8 characters", 422);

    const { data: hashData, error: hashErr } = await db.rpc("hash_password", {
      raw_password: password,
    });
    if (hashErr) return err("Service unavailable", 503);

    const { data, error } = await db.rpc("create_company_admin_user", {
      p_company_id: companyId,
      p_username: username,
      p_password_hash: String(hashData),
      p_full_name: fullName,
      p_created_by: String(claims.sub),
    });

    if (error) {
      if (error.code === "23505") return err("Username already taken", 409);
      logDbError("auth/create_company_admin", error);
      return err("Failed to create admin", 500);
    }

    const user = (data as Array<Record<string, unknown>> | null)?.[0];
    if (!user) return err("Failed to create admin", 500);

    const { error: auditError } = await db.rpc("insert_audit_log", {
      p_actor_id: String(claims.sub),
      p_actor_role: String(claims.role),
      p_company_id: companyId,
      p_action: "CREATE_COMPANY_ADMIN",
      p_target_type: "user",
      p_target_id: String(user.id),
      p_details: { username, company_id: companyId },
      p_ip_address: ip,
    });
    if (auditError) logDbError("auth/create_company_admin/audit", auditError);

    console.log(`[auth/create_company_admin] ok user=${username} company=${companyId}`);
    return ok({ user }, 201);
  }

  return err("Unknown action", 400);
});