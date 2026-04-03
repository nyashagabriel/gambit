// lib/core/api/files_api.dart — GONYETI TLS
// Typed wrappers for the /files edge function.
//
// Upload flow (no binary through the edge function):
//   1. Call requestUploadUrl() → get signed PUT URL + storage_path
//   2. PUT the file bytes directly to the signed URL (plain HTTP)
//   3. Call confirm() → creates the DB record, returns the Document

import "dart:typed_data";
import "package:http/http.dart" as http;
import "../models/models.dart";
import "client.dart";

class FilesApi {
  FilesApi._();

  // ── Step 1: get signed upload URL ──────────────────────────────────────────
  static Future<({String uploadUrl, String storagePath})> requestUploadUrl({
    required String filename,
    required String mimeType,
    required int fileSize,
    String folder = "general",
    String? companyId,
  }) async {
    final data = await rpc("files", {
      "action": "upload_url",
      "filename": filename,
      "mime_type": mimeType,
      "file_size": fileSize,
      "folder": folder,
      if (companyId != null) "company_id": companyId,
    });
    return (
      uploadUrl: data["upload_url"] as String,
      storagePath: data["storage_path"] as String,
    );
  }

  // ── Step 2: PUT bytes directly to signed URL ───────────────────────────────
  /// Returns true on success, throws on HTTP error.
  static Future<void> uploadBytes({
    required String signedUrl,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final response = await http
        .put(
          Uri.parse(signedUrl),
          headers: {"Content-Type": mimeType},
          body: bytes,
        )
        .timeout(const Duration(minutes: 5)); // large files need more time

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GonyetiApiException(
        statusCode: response.statusCode,
        message: "File upload failed (${response.statusCode}).",
      );
    }
  }

  // ── Step 3: confirm upload and save metadata ───────────────────────────────
  static Future<GambitDocument> confirm({
    required String storagePath,
    required String title,
    String folder = "general",
    String? expiryDate, // ISO date string "2026-12-31"
    String? companyId,
  }) async {
    final data = await rpc("files", {
      "action": "confirm",
      "storage_path": storagePath,
      "title": title,
      "folder": folder,
      if (expiryDate != null) "expiry_date": expiryDate,
      if (companyId != null) "company_id": companyId,
    });
    return GambitDocument.fromMap(data["document"] as Map<String, dynamic>);
  }

  // ── Convenience: upload in one call ───────────────────────────────────────
  /// Combines the three steps above. Progress reporting is not available in
  /// this method — use the individual steps if you need a progress indicator.
  static Future<GambitDocument> upload({
    required String title,
    required String filename,
    required String mimeType,
    required Uint8List bytes,
    String folder = "general",
    String? expiryDate,
    String? companyId,
  }) async {
    final urls = await requestUploadUrl(
      filename: filename,
      mimeType: mimeType,
      fileSize: bytes.length,
      folder: folder,
      companyId: companyId,
    );

    await uploadBytes(
      signedUrl: urls.uploadUrl,
      bytes: bytes,
      mimeType: mimeType,
    );

    return confirm(
      storagePath: urls.storagePath,
      title: title,
      folder: folder,
      expiryDate: expiryDate,
      companyId: companyId,
    );
  }

  // ── List documents ─────────────────────────────────────────────────────────
  static Future<List<GambitDocument>> list({
    String? folder,
    String? companyId,
  }) async {
    final data = await rpc("files", {
      "action": "list",
      if (folder != null) "folder": folder,
      if (companyId != null) "company_id": companyId,
    });
    return (data["documents"] as List)
        .map((d) => GambitDocument.fromMap(d as Map<String, dynamic>))
        .toList();
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  static Future<void> delete({
    required String documentId,
    String? companyId,
  }) async {
    await rpc("files", {
      "action": "delete",
      "document_id": documentId,
      if (companyId != null) "company_id": companyId,
    });
  }
}
