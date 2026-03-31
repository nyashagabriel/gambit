// supabase/functions/api.ts — GAMBIT TSL
// Core operational data: trips · fleet · drivers
// Extend this file as modules are built out — keep actions prefixed by domain
// e.g. "trip_list", "trip_create", "fleet_list", "driver_list"

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

const hasRole = (actor: string, min: string) =>
  (ROLE_RANK[actor] ?? -1) >= (ROLE_RANK[min] ?? 0);

const scopeToCompany = (claims: Record<string, unknown>, override?: string): string | null => {
  if (claims.role === "super_admin") return (override ?? null) as string | null;
  return claims.company_id as string;
};

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

  // ── TRIP · LIST ───────────────────────────────────────────────────────────────
  if (action === "trip_list") {
    if (!hasRole(claims.role as string, "staff")) return err("Forbidden", 403);

    const companyId = scopeToCompany(claims, body.company_id as string | undefined);

    const { data, error } = await db.rpc("list_trips", {
      p_company_id: companyId,
      p_driver_id: claims.role === "staff" ? String(claims.sub) : null,
    });

    if (error) {
      logDbError("api/trip_list", error);
      return err("Failed to fetch trips", 500);
    }
    return ok({ trips: data });
  }

  // ── TRIP · CREATE ─────────────────────────────────────────────────────────────
  if (action === "trip_create") {
    if (!hasRole(claims.role as string, "company_admin")) return err("Forbidden", 403);

    const { reference, trip_type, horse_id, driver_id, origin, destination,
            cargo_type, cargo_description, tonnage, freight_rate,
            start_date, end_date, company_id: bodyCompany } = body;

    if (!reference || !origin || !destination) {
      return err("reference, origin and destination are required", 400);
    }

    const companyId = scopeToCompany(claims, bodyCompany as string | undefined);
    if (!companyId) return err("company_id is required for super_admin", 400);

    if (claims.role === "company_admin" && companyId !== claims.company_id) {
      return err("Cannot create trip for another company", 403);
    }

    const { data, error } = await db.rpc("create_trip", {
      p_company_id: companyId,
      p_reference: String(reference),
      p_trip_type: (trip_type as string | undefined) ?? null,
      p_horse_id: (horse_id as string | undefined) ?? null,
      p_driver_id: (driver_id as string | undefined) ?? null,
      p_origin: String(origin),
      p_destination: String(destination),
      p_cargo_type: (cargo_type as string | undefined) ?? null,
      p_cargo_description: (cargo_description as string | undefined) ?? null,
      p_tonnage: (tonnage as number | null | undefined) ?? null,
      p_freight_rate: (freight_rate as number | null | undefined) ?? null,
      p_start_date: (start_date as string | null | undefined) ?? null,
      p_end_date: (end_date as string | null | undefined) ?? null,
      p_created_by: String(claims.sub),
    });

    if (error) {
      if (error.code === "23505") return err("Trip reference already exists", 409);
      logDbError("api/trip_create", error);
      return err("Failed to create trip", 500);
    }

    const trip = (data as Array<Record<string, unknown>> | null)?.[0];
    if (!trip) return err("Failed to create trip", 500);

    const { error: auditError } = await db.rpc("insert_audit_log", {
      p_actor_id: String(claims.sub),
      p_actor_role: String(claims.role),
      p_company_id: companyId,
      p_action: "CREATE_TRIP",
      p_target_type: "trip",
      p_target_id: String(trip.id),
      p_details: { reference },
      p_ip_address: ip,
    });
    if (auditError) logDbError("api/trip_create/audit", auditError);

    console.log(`[api/trip_create] ok ref=${reference} company=${companyId}`);
    return ok({ trip }, 201);
  }

  // ── TRIP · UPDATE ─────────────────────────────────────────────────────────────
  if (action === "trip_update") {
    if (!hasRole(claims.role as string, "staff")) return err("Forbidden", 403);

    const tripId = body.trip_id as string | undefined;
    if (!tripId) return err("trip_id is required", 400);

    const { data: existingRows, error: fetchErr } = await db.rpc("get_trip_scope", {
      p_trip_id: tripId,
    });

    const existing = (existingRows as Array<{ id: string; company_id: string; driver_id: string | null; status: string }> | null)?.[0];

    if (fetchErr || !existing) return err("Trip not found", 404);

    // Staff can only update their own trips
    if (claims.role === "staff" && existing.driver_id !== claims.sub) {
      return err("Forbidden", 403);
    }

    const MUTABLE_BY_STAFF   = ["status", "pod_number", "odo_reading", "notes"];
    const MUTABLE_BY_ADMIN   = [...MUTABLE_BY_STAFF, "horse_id", "driver_id", "freight_rate",
                                  "start_date", "end_date"];
    const allowed = hasRole(claims.role as string, "company_admin")
      ? MUTABLE_BY_ADMIN : MUTABLE_BY_STAFF;

    const VALID_STATUSES = ["pending","active","in_transit","delivered","completed","cancelled"];
    const updates: Record<string, unknown> = {};

    for (const field of allowed) {
      if (body[field] !== undefined) updates[field] = body[field];
    }
    if (updates.status && !VALID_STATUSES.includes(updates.status as string)) {
      return err(`Invalid status. Valid values: ${VALID_STATUSES.join(", ")}`, 422);
    }

    if (Object.keys(updates).length === 0) return err("Nothing to update", 400);

    const { data, error } = await db.rpc("update_trip", {
      p_trip_id: tripId,
      p_status: (updates.status as string | undefined) ?? null,
      p_pod_number: (updates.pod_number as string | undefined) ?? null,
      p_odo_reading: (updates.odo_reading as number | undefined) ?? null,
      p_notes: (updates.notes as string | undefined) ?? null,
      p_horse_id: (updates.horse_id as string | undefined) ?? null,
      p_driver_id: (updates.driver_id as string | undefined) ?? null,
      p_freight_rate: (updates.freight_rate as number | undefined) ?? null,
      p_start_date: (updates.start_date as string | undefined) ?? null,
      p_end_date: (updates.end_date as string | undefined) ?? null,
    });

    if (error) {
      logDbError("api/trip_update", error);
      return err("Failed to update trip", 500);
    }

    const trip = (data as Array<Record<string, unknown>> | null)?.[0];
    if (!trip) return err("Failed to update trip", 500);

    const { error: auditError } = await db.rpc("insert_audit_log", {
      p_actor_id: String(claims.sub),
      p_actor_role: String(claims.role),
      p_company_id: existing.company_id,
      p_action: "UPDATE_TRIP",
      p_target_type: "trip",
      p_target_id: tripId,
      p_details: updates,
      p_ip_address: ip,
    });
    if (auditError) logDbError("api/trip_update/audit", auditError);

    return ok({ trip });
  }

  // ── FLEET · LIST ──────────────────────────────────────────────────────────────
  if (action === "fleet_list") {
    if (!hasRole(claims.role as string, "staff")) return err("Forbidden", 403);

    const companyId = scopeToCompany(claims, body.company_id as string | undefined);

    const { data, error } = await db.rpc("list_fleet", {
      p_company_id: companyId,
    });

    if (error) {
      logDbError("api/fleet_list", error);
      return err("Failed to fetch fleet", 500);
    }
    return ok({ fleet: data });
  }

  // ── DRIVER · LIST ─────────────────────────────────────────────────────────────
  if (action === "driver_list") {
    if (!hasRole(claims.role as string, "staff")) return err("Forbidden", 403);

    const companyId = scopeToCompany(claims, body.company_id as string | undefined);

    const { data, error } = await db.rpc("list_drivers", {
      p_company_id: companyId,
    });

    if (error) {
      logDbError("api/driver_list", error);
      return err("Failed to fetch drivers", 500);
    }
    return ok({ drivers: data });
  }

  return err("Unknown action", 400);
});