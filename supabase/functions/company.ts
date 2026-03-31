// supabase/functions/companies.ts — GAMBIT TSL
// Handles: list · create · update · delete
// Access: super_admin only — enforced server-side, not just on the client

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL     = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const JWT_SECRET       = Deno.env.get("GAMBIT_JWT_SECRET");
const FRONTEND_URL     = Deno.env.get("FRONTEND_URL");

if (!JWT_SECRET) throw new Error("GAMBIT_JWT_SECRET env var is not set");

const ISSUER = "gambit-tsl";

const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin":  FRONTEND_URL ?? "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Authorization, Content-Type, apikey",
  "Content-Type": "application/json",
};

// ─── JWT verify (read-only — companies never issues tokens) ────────────────────
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
  if (!claims)                       return err("Unauthorized", 401);
  if (claims.role !== "super_admin") return err("Forbidden", 403);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return err("Invalid JSON", 400);
  }

  const action = body.action as string | undefined;
  if (!action) return err("Missing action", 400);

  const actorId = String(claims.sub ?? "");
  const actorRole = String(claims.role ?? "");
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? null;
  const db = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  // ── LIST ─────────────────────────────────────────────────────────────────────
  if (action === "list") {
    const { data, error } = await db.rpc("list_companies");

    if (error) {
      logDbError("companies/list", error);
      return err("Failed to fetch companies", 500);
    }
    return ok({ companies: data });
  }

  // ── CREATE ───────────────────────────────────────────────────────────────────
  if (action === "create") {
    const name = (body.name as string | undefined)?.trim();
    if (!name) return err("Company name is required", 400);
    if (name.length > 120) return err("Company name too long", 422);

    const { data, error } = await db.rpc("create_company", {
      p_name: name,
      p_actor: actorId,
    });

    if (error) {
      if (error.code === "23505") return err("A company with that name already exists", 409);
      logDbError("companies/create", error);
      return err("Failed to create company", 500);
    }

    const company = (data as Array<Record<string, unknown>> | null)?.[0];
    if (!company) return err("Failed to create company", 500);

    const { error: auditError } = await db.rpc("insert_audit_log", {
      p_actor_id: actorId,
      p_actor_role: actorRole,
      p_company_id: null,
      p_action: "CREATE_COMPANY",
      p_target_type: "company",
      p_target_id: String(company.id),
      p_details: { name },
      p_ip_address: ip,
    });
    if (auditError) logDbError("companies/create/audit", auditError);

    console.log(`[companies/create] ok name="${name}" id=${company.id}`);
    return ok({ company }, 201);
  }

  // ── UPDATE ───────────────────────────────────────────────────────────────────
  if (action === "update") {
    const companyId = body.company_id as string | undefined;
    if (!companyId) return err("company_id is required", 400);

    const VALID_STATUSES = ["active", "warned", "suspended", "banned"];
    let name: string | null = null;
    let status: string | null = null;
    let warningMessage: string | null = null;

    if (body.name !== undefined) {
      name = (body.name as string).trim();
      if (!name || name.length > 120) return err("Invalid company name", 422);
    }

    if (body.status !== undefined) {
      if (!VALID_STATUSES.includes(body.status as string)) {
        return err(`Invalid status. Must be one of: ${VALID_STATUSES.join(", ")}`, 422);
      }
      status = body.status as string;
    }

    if (body.warning_message !== undefined) {
      warningMessage = (body.warning_message as string | null) || null;
    }

    if (name === null && status === null && warningMessage === null) {
      return err("Nothing to update", 400);
    }

    const { data, error } = await db.rpc("update_company", {
      p_company_id: companyId,
      p_name: name,
      p_status: status,
      p_warning_message: warningMessage,
    });

    if (error) {
      if (error.code === "PGRST116") return err("Company not found", 404);
      logDbError("companies/update", error);
      return err("Failed to update company", 500);
    }

    const company = (data as Array<Record<string, unknown>> | null)?.[0];
    if (!company) return err("Company not found", 404);

    const details: Record<string, unknown> = {};
    if (name !== null) details.name = name;
    if (status !== null) details.status = status;
    if (warningMessage !== null) details.warning_message = warningMessage;

    const { error: auditError } = await db.rpc("insert_audit_log", {
      p_actor_id: actorId,
      p_actor_role: actorRole,
      p_company_id: null,
      p_action: "UPDATE_COMPANY",
      p_target_type: "company",
      p_target_id: companyId,
      p_details: details,
      p_ip_address: ip,
    });
    if (auditError) logDbError("companies/update/audit", auditError);

    return ok({ company });
  }

  // ── DELETE ───────────────────────────────────────────────────────────────────
  if (action === "delete") {
    const companyId = body.company_id as string | undefined;
    if (!companyId) return err("company_id is required", 400);

    const { error } = await db.rpc("delete_company", {
      p_company_id: companyId,
    });

    if (error) {
      if (error.code === "PGRST116") return err("Company not found", 404);
      logDbError("companies/delete", error);
      return err("Failed to delete company", 500);
    }

    const { error: auditError } = await db.rpc("insert_audit_log", {
      p_actor_id: actorId,
      p_actor_role: actorRole,
      p_company_id: null,
      p_action: "DELETE_COMPANY",
      p_target_type: "company",
      p_target_id: companyId,
      p_details: null,
      p_ip_address: ip,
    });
    if (auditError) logDbError("companies/delete/audit", auditError);

    console.log(`[companies/delete] ok id=${companyId}`);
    return ok({ message: "Company deleted" });
  }

  return err("Unknown action", 400);
});