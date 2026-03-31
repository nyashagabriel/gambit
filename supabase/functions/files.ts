// supabase/functions/files.ts — GAMBIT TSL
// Handles: upload_url · confirm · list · delete
//
// Strategy: signed upload URLs (no binary through the edge function)
//   1. Client calls upload_url → gets a short-lived signed PUT URL
//   2. Client PUTs the file directly to Supabase Storage (no proxy)
//   3. Client calls confirm → we write the metadata record to gambit.documents
//
// Bucket name: gambit-docs  (create in Supabase dashboard, private)
// Path pattern: {company_id}/{folder}/{uuid}.{ext}

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL     = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const JWT_SECRET       = Deno.env.get("GAMBIT_JWT_SECRET");
const FRONTEND_URL     = Deno.env.get("FRONTEND_URL");
const BUCKET           = "gambit-docs";

// Max upload size: 25 MB (enforced in bucket policy — this is a belt-and-braces check)
const MAX_BYTES = 25 * 1024 * 1024;

// Allowed MIME types for document uploads
const ALLOWED_MIME = new Set([
  "application/pdf",
  "image/jpeg",
  "image/png",
  "image/webp",
  "application/msword",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  "application/vnd.ms-excel",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
]);

if (!JWT_SECRET) throw new Error("GAMBIT_JWT_SECRET env var is not set");

const ISSUER = "gambit-tsl";

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

// Sanitise a folder name: alphanumeric + hyphens/underscores only
function sanitiseFolder(raw: string): string {
  return raw.replace(/[^a-zA-Z0-9_\-]/g, "_").slice(0, 80);
}

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

  // Resolve the company scope for this request
  const companyId: string | null =
    claims.role === "super_admin"
      ? ((body.company_id as string | undefined) ?? null)
      : (claims.company_id as string);

  if (!companyId) return err("company_id is required", 400);

  // ── UPLOAD URL ─────────────────────────────────────────────────────────────
  // Returns a signed URL the client uses to PUT the file directly into storage.
  if (action === "upload_url") {
    const filename  = body.filename as string | undefined;
    const mimeType  = body.mime_type as string | undefined;
    const fileSize  = body.file_size as number | undefined;
    const folder    = sanitiseFolder((body.folder as string | undefined) ?? "general");

    if (!filename || !mimeType) return err("filename and mime_type are required", 400);

    if (!ALLOWED_MIME.has(mimeType)) {
      return err("File type not permitted", 415);
    }

    if (fileSize !== undefined && fileSize > MAX_BYTES) {
      return err("File exceeds the 25 MB limit", 413);
    }

    // Derive extension safely
    const ext  = filename.split(".").pop()?.replace(/[^a-zA-Z0-9]/g, "") ?? "bin";
    const uuid = crypto.randomUUID();
    const path = `${companyId}/${folder}/${uuid}.${ext}`;

    const { data, error } = await db.storage
      .from(BUCKET)
      .createSignedUploadUrl(path);

    if (error) {
      console.error("[files/upload_url] storage error:", error.message);
      return err("Failed to create upload URL", 500);
    }

    return ok({
      upload_url: data.signedUrl,
      storage_path: path,
      token: data.token,
    });
  }

  // ── CONFIRM ────────────────────────────────────────────────────────────────
  // Called after the client successfully PUTs the file. Writes the metadata record.
  if (action === "confirm") {
    const storagePath = body.storage_path as string | undefined;
    const title       = (body.title as string | undefined)?.trim();
    const folder      = sanitiseFolder((body.folder as string | undefined) ?? "general");
    const expiryDate  = body.expiry_date as string | undefined ?? null;

    if (!storagePath || !title) return err("storage_path and title are required", 400);

    // Verify the path is scoped to this company (prevents cross-tenant injection)
    if (!storagePath.startsWith(`${companyId}/`)) {
      return err("Invalid storage path", 403);
    }

    // Get a permanent public/signed URL for retrieval
    const { data: urlData, error: urlErr } = await db.storage
      .from(BUCKET)
      .createSignedUrl(storagePath, 60 * 60 * 24 * 365); // 1 year — refresh on read

    if (urlErr) {
      console.error("[files/confirm] signed url error:", urlErr.message);
      return err("Failed to generate document URL", 500);
    }

    const { data, error } = await db.rpc("create_document", {
      p_company_id: companyId,
      p_folder: folder,
      p_title: title,
      p_storage_path: storagePath,
      p_expiry_date: expiryDate,
      p_uploaded_by: String(claims.sub),
    });

    if (error) {
      logDbError("files/confirm", error);
      return err("Failed to save document record", 500);
    }

    const document = (data as Array<Record<string, unknown>> | null)?.[0];
    if (!document) return err("Failed to save document record", 500);

    const { error: auditError } = await db.rpc("insert_audit_log", {
      p_actor_id: String(claims.sub),
      p_actor_role: String(claims.role),
      p_company_id: companyId,
      p_action: "UPLOAD_DOCUMENT",
      p_target_type: "document",
      p_target_id: String(document.id),
      p_details: { title, folder, storage_path: storagePath },
      p_ip_address: ip,
    });
    if (auditError) logDbError("files/confirm/audit", auditError);

    console.log(`[files/confirm] ok doc="${title}" company=${companyId}`);
    return ok({ document: { ...document, url: urlData.signedUrl } }, 201);
  }

  // ── LIST ───────────────────────────────────────────────────────────────────
  if (action === "list") {
    const folder = body.folder
      ? sanitiseFolder(body.folder as string)
      : undefined;

    const { data, error } = await db.rpc("list_documents", {
      p_company_id: companyId,
      p_folder: folder ?? null,
    });

    if (error) {
      logDbError("files/list", error);
      return err("Failed to fetch documents", 500);
    }

    // Attach fresh signed URLs (avoids storing them — they expire anyway)
    const enriched = await Promise.all(
      ((data as Array<Record<string, unknown>> | null) ?? []).map(async (doc) => {
        const { data: u } = await db.storage
          .from(BUCKET)
          .createSignedUrl(String(doc.storage_path), 60 * 60); // 1-hour read URL
        return { ...doc, url: u?.signedUrl ?? null };
      }),
    );

    return ok({ documents: enriched });
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────
  if (action === "delete") {
    const docId = body.document_id as string | undefined;
    if (!docId) return err("document_id is required", 400);

    // Fetch first to verify ownership
    const { data: docRows, error: fetchErr } = await db.rpc("get_document_scope", {
      p_document_id: docId,
    });

    const doc = (docRows as Array<{ id: string; storage_path: string; company_id: string }> | null)?.[0];

    if (fetchErr || !doc) return err("Document not found", 404);

    // company_admin can only delete their own company's documents
    if (claims.role !== "super_admin" && doc.company_id !== companyId) {
      return err("Forbidden", 403);
    }

    // Remove from storage first — if this fails, keep the DB record
    const { error: storageErr } = await db.storage
      .from(BUCKET)
      .remove([doc.storage_path]);

    if (storageErr) {
      console.error("[files/delete] storage remove error:", storageErr.message);
      return err("Failed to remove file from storage", 500);
    }

    const { error } = await db.rpc("delete_document", {
      p_document_id: docId,
    });

    if (error) {
      logDbError("files/delete", error);
      return err("Failed to delete document record", 500);
    }

    const { error: auditError } = await db.rpc("insert_audit_log", {
      p_actor_id: String(claims.sub),
      p_actor_role: String(claims.role),
      p_company_id: companyId,
      p_action: "DELETE_DOCUMENT",
      p_target_type: "document",
      p_target_id: docId,
      p_details: { storage_path: doc.storage_path },
      p_ip_address: ip,
    });
    if (auditError) logDbError("files/delete/audit", auditError);

    console.log(`[files/delete] ok doc=${docId}`);
    return ok({ message: "Document deleted" });
  }

  return err("Unknown action", 400);
});