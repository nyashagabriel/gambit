// lib/features/staff/docs_screen.dart — GAMBIT TSL
// Document list + upload for staff.
// Upload uses the three-step signed URL flow (no binary through the edge function).
// file_picker opens the system file browser; we read bytes in-memory and PUT
// them directly to Supabase Storage via the signed URL.

import "dart:typed_data";
import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../core/api/files_api.dart";
import "../../core/auth/auth_provider.dart";
import "../../core/auth/role_guard.dart";
import "../../core/models/models.dart";
import "../../shared/theme/gambit_theme.dart";
import "../../shared/widgets/widgets.dart";

class StaffDocsScreen extends StatefulWidget {
  const StaffDocsScreen({super.key});

  @override
  State<StaffDocsScreen> createState() => _StaffDocsScreenState();
}

class _StaffDocsScreenState extends State<StaffDocsScreen> {
  List<GambitDocument> _docs = [];
  bool _loading = true;
  String? _error;

  // Upload state
  bool _uploading = false;
  double? _uploadProgress;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _docs = await FilesApi.list();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Upload flow ─────────────────────────────────────────────────────────────
  Future<void> _pickAndUpload() async {
    setState(() {
      _uploadError = null;
    });

    // 1. Open file picker (restricts to supported types)
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        "pdf",
        "jpg",
        "jpeg",
        "png",
        "webp",
        "doc",
        "docx",
        "xls",
        "xlsx",
      ],
      withData: true, // load bytes immediately (required for web)
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    final filename = file.name;
    final extension = filename.split(".").last.toLowerCase();

    if (bytes == null) {
      setState(() => _uploadError = "Could not read file. Please try again.");
      return;
    }

    // Size guard (25 MB — mirrors the server-side limit)
    if (bytes.length > 25 * 1024 * 1024) {
      setState(
        () => _uploadError = "File is too large. Maximum size is 25 MB.",
      );
      return;
    }

    final mimeMap = {
      "pdf": "application/pdf",
      "jpg": "image/jpeg",
      "jpeg": "image/jpeg",
      "png": "image/png",
      "webp": "image/webp",
      "doc": "application/msword",
      "docx":
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "xls": "application/vnd.ms-excel",
      "xlsx":
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    };

    final mimeType = mimeMap[extension];
    if (mimeType == null) {
      setState(() => _uploadError = "Unsupported file type: .$extension");
      return;
    }

    // Show the metadata sheet before uploading
    final meta = await _showMetadataSheet(filename);
    if (meta == null) return; // user cancelled

    setState(() {
      _uploading = true;
      _uploadProgress = 0.1;
    });

    try {
      // Step 1: get signed upload URL
      final urls = await FilesApi.requestUploadUrl(
        filename: filename,
        mimeType: mimeType,
        fileSize: bytes.length,
        folder: meta.folder,
      );

      setState(() => _uploadProgress = 0.4);

      // Step 2: PUT bytes directly to Supabase Storage
      await FilesApi.uploadBytes(
        signedUrl: urls.uploadUrl,
        bytes: Uint8List.fromList(bytes),
        mimeType: mimeType,
      );

      setState(() => _uploadProgress = 0.8);

      // Step 3: confirm and save metadata
      await FilesApi.confirm(
        storagePath: urls.storagePath,
        title: meta.title,
        folder: meta.folder,
        expiryDate: meta.expiryDate,
      );

      setState(() {
        _uploading = false;
        _uploadProgress = null;
      });
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Document uploaded successfully"),
            backgroundColor: GambitColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _uploading = false;
        _uploadProgress = null;
        _uploadError = e.toString();
      });
    }
  }

  // ── Metadata sheet ──────────────────────────────────────────────────────────
  Future<_UploadMeta?> _showMetadataSheet(String defaultTitle) async {
    final titleCtrl = TextEditingController(
      text: defaultTitle.split(".").first.replaceAll("_", " "),
    );
    final expCtrl = TextEditingController();
    String selectedFolder = "general";

    return showModalBottomSheet<_UploadMeta>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GambitColors.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Document details",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: GambitColors.text,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              GInput(
                label: "DOCUMENT TITLE",
                controller: titleCtrl,
                prefixIcon: Icons.title_rounded,
                textInputAction: TextInputAction.next,
              ),

              // Folder selector
              const Text(
                "FOLDER",
                style: TextStyle(
                  color: GambitColors.textSub,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _kFolders.map((f) {
                  final sel = f == selectedFolder;
                  return Semantics(
                    selected: sel,
                    button: true,
                    label: f,
                    child: GestureDetector(
                      onTap: () => setSheet(() => selectedFolder = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? GambitColors.accentDim
                              : GambitColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel
                                ? GambitColors.accent
                                : GambitColors.border,
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                            color: sel
                                ? GambitColors.accent
                                : GambitColors.textSub,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Expiry date (optional)
              GInput(
                label: "EXPIRY DATE (optional)",
                hint: "yyyy-mm-dd",
                controller: expCtrl,
                prefixIcon: Icons.calendar_today_rounded,
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 8),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: GButton(
                      label: "Cancel",
                      outline: true,
                      color: GambitColors.textSub,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GButton(
                      label: "Upload",
                      icon: Icons.upload_rounded,
                      color: GambitColors.success,
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) return;
                        Navigator.pop(
                          ctx,
                          _UploadMeta(
                            title: title,
                            folder: selectedFolder,
                            expiryDate: expCtrl.text.trim().isEmpty
                                ? null
                                : expCtrl.text.trim(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delete ──────────────────────────────────────────────────────────────────
  Future<void> _delete(GambitDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete document?"),
        content: Text('Remove "${doc.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: GambitColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FilesApi.delete(documentId: doc.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: GambitColors.danger,
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canUpload =
        auth.claims != null && RoleGuard.canUploadDocuments(auth.claims!);
    final canDelete =
        auth.claims != null && RoleGuard.canDeleteDocuments(auth.claims!);

    return Scaffold(
      backgroundColor: GambitColors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: GambitColors.accent,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Documents",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: GambitColors.text,
                        ),
                      ),
                      Text(
                        "Licences, permits, PODs & reports",
                        style: TextStyle(
                          fontSize: 11,
                          color: GambitColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canUpload)
                  Semantics(
                    button: true,
                    label: "Upload new document",
                    child: GButton(
                      label: "Upload",
                      icon: Icons.upload_file_rounded,
                      small: true,
                      loading: _uploading,
                      onPressed: _uploading ? null : _pickAndUpload,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Upload progress
            if (_uploading && _uploadProgress != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: GambitColors.border,
                  color: GambitColors.accent,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Uploading…",
                style: TextStyle(fontSize: 11, color: GambitColors.textSub),
              ),
              const SizedBox(height: 12),
            ],

            if (_uploadError != null)
              Semantics(
                liveRegion: true,
                child: GAlert(message: _uploadError!, type: "danger"),
              ),

            if (_error != null) GAlert(message: _error!, type: "danger"),

            if (_loading)
              const Center(
                child: CircularProgressIndicator(
                  color: GambitColors.accent,
                  strokeWidth: 2,
                ),
              ),

            if (!_loading && _docs.isEmpty)
              const GAlert(
                message: "No documents yet",
                sub: "Tap Upload to add your first document.",
              ),

            ..._docs.map(
              (doc) =>
                  _DocTile(doc: doc, canDelete: canDelete, onDelete: _delete),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Document tile ─────────────────────────────────────────────────────────────
class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.doc,
    required this.canDelete,
    required this.onDelete,
  });
  final GambitDocument doc;
  final bool canDelete;
  final void Function(GambitDocument) onDelete;

  String get _expiryLabel {
    if (doc.expiryDate == null) return "";
    try {
      final d = DateTime.parse(doc.expiryDate!);
      final days = d.difference(DateTime.now()).inDays;
      if (days < 0) return "EXPIRED";
      if (days == 0) return "EXPIRES TODAY";
      if (days <= 7) return "EXPIRES IN $days DAYS";
      if (days <= 30) return "EXPIRES IN $days DAYS";
      return "EXPIRES ${doc.expiryDate!.split("T")[0]}";
    } catch (_) {
      return doc.expiryDate ?? "";
    }
  }

  Color get _expiryColor {
    if (doc.isExpired) return GambitColors.danger;
    if (doc.isExpiringSoon(daysAhead: 7)) return GambitColors.danger;
    if (doc.isExpiringSoon()) return GambitColors.warn;
    return GambitColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = doc.isExpired
        ? GambitColors.danger.withAlpha(80)
        : doc.isExpiringSoon(daysAhead: 7)
        ? GambitColors.danger.withAlpha(50)
        : doc.isExpiringSoon()
        ? GambitColors.warn.withAlpha(50)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GCard(
        borderColor: borderColor,
        child: Row(
          children: [
            // File type icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GambitColors.elevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _iconForFolder(doc.folder),
                size: 18,
                color: GambitColors.textSub,
                semanticLabel: "",
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: GambitColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        doc.folder.replaceAll("_", " ").toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          color: GambitColors.textMuted,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (doc.expiryDate != null) ...[
                        const Text(
                          " · ",
                          style: TextStyle(
                            color: GambitColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          _expiryLabel,
                          style: TextStyle(
                            fontSize: 9,
                            color: _expiryColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            if (canDelete)
              Semantics(
                button: true,
                label: "Delete ${doc.title}",
                child: IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: GambitColors.textMuted,
                  ),
                  onPressed: () => onDelete(doc),
                  tooltip: "Delete",
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForFolder(String folder) {
    return switch (folder) {
      "permits" => Icons.article_rounded,
      "insurance" => Icons.shield_rounded,
      "port_permits" => Icons.anchor_rounded,
      "pod" => Icons.receipt_rounded,
      "maintenance" => Icons.build_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }
}

// ── Constants ────────────────────────────────────────────────────────────────
const List<String> _kFolders = [
  "general",
  "permits",
  "insurance",
  "port_permits",
  "pod",
  "maintenance",
];

// ── Upload metadata ───────────────────────────────────────────────────────────
class _UploadMeta {
  const _UploadMeta({
    required this.title,
    required this.folder,
    this.expiryDate,
  });
  final String title;
  final String folder;
  final String? expiryDate;
}
