// lib/core/models/models.dart — GONYETI TLS
// Single file for all domain value objects.
//
// fromMap rules:
//   • Truly required fields (id, username, role) cast strictly — a missing
//     value here means the server sent garbage and we WANT the crash to be loud.
//   • Optional fields use null-coalescing or a safe default.
//   • GambitUser handles both "id" (DB queries) and "user_id" (login RPC row).

// ─── User ──────────────────────────────────────────────────────────────────
class GambitUser {
  const GambitUser({
    required this.id,
    required this.username,
    required this.role,
    required this.isActive,
    required this.mustChangePw,
    required this.createdAt,
    this.fullName,
    this.companyId,
    this.recoveryEmail,
  });

  /// Handles both field name shapes:
  ///   "id"      — rows from gambit.users (list, me, create)
  ///   "user_id" — row returned by the gambit.login() RPC
  factory GambitUser.fromMap(Map<String, dynamic> m) {
    final id = (m["id"] ?? m["user_id"]) as String?;
    if (id == null) {
      throw ArgumentError(
        'GambitUser.fromMap: neither "id" nor "user_id" found in $m',
      );
    }
    return GambitUser(
      id: id,
      username: m["username"] as String,
      fullName: m["full_name"] as String?,
      role: m["role"] as String,
      companyId: m["company_id"] as String?,
      isActive: m["is_active"] as bool? ?? true,
      mustChangePw: m["must_change_pw"] as bool? ?? false,
      recoveryEmail: m["recovery_email"] as String?,
      createdAt: m["created_at"] as String? ?? "",
    );
  }
  final String id;
  final String username;
  final String? fullName;
  final String role;
  final String? companyId;
  final bool isActive;
  final bool mustChangePw;
  final String? recoveryEmail;
  final String createdAt;

  String get displayName =>
      fullName != null && fullName!.isNotEmpty ? fullName! : username;
}

// ─── Company ──────────────────────────────────────────────────────────────
class GambitCompany {
  const GambitCompany({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    this.warningMessage,
  });

  factory GambitCompany.fromMap(Map<String, dynamic> m) => GambitCompany(
    id: m["id"] as String,
    name: m["name"] as String,
    status: m["status"] as String? ?? "active",
    warningMessage: m["warning_message"] as String?,
    createdAt: m["created_at"] as String? ?? "",
  );
  final String id;
  final String name;
  final String status; // active | warned | suspended | banned
  final String? warningMessage;
  final String createdAt;

  bool get isActive => status == "active";
  bool get isWarned => status == "warned";
  bool get isSuspended => status == "suspended";
  bool get isBanned => status == "banned";
}

// ─── JWT Claims ───────────────────────────────────────────────────────────
class GambitClaims {
  const GambitClaims({
    required this.sub,
    required this.username,
    required this.role,
    required this.mustChangePw,
    required this.iat,
    required this.exp,
    this.fullName,
    this.companyId,
  });

  factory GambitClaims.fromMap(Map<String, dynamic> m) => GambitClaims(
    sub: m["sub"] as String,
    username: m["username"] as String,
    fullName: m["full_name"] as String?,
    role: m["role"] as String,
    companyId: m["company_id"] as String?, // nullable — OK
    mustChangePw: m["must_change_pw"] as bool? ?? false,
    iat: m["iat"] as int,
    exp: m["exp"] as int,
  );
  final String sub;
  final String username;
  final String? fullName;
  final String role;
  final String? companyId; // null for super_admin — valid, not an error
  final bool mustChangePw;
  final int iat;
  final int exp;

  bool get isValid => DateTime.now().millisecondsSinceEpoch ~/ 1000 < exp;

  int get secondsUntilExpiry =>
      exp - DateTime.now().millisecondsSinceEpoch ~/ 1000;

  bool get isSuperAdmin => role == "super_admin";
  bool get isCompanyAdmin => role == "company_admin";
  bool get isStaff => role == "staff";
  bool get isUser => role == "user";
}

// ─── Document ─────────────────────────────────────────────────────────────
class GambitDocument {
  const GambitDocument({
    required this.id,
    required this.title,
    required this.folder,
    required this.storagePath,
    required this.createdAt,
    this.url,
    this.expiryDate,
  });

  factory GambitDocument.fromMap(Map<String, dynamic> m) => GambitDocument(
    id: m["id"] as String,
    title: m["title"] as String,
    folder: m["folder"] as String? ?? "general",
    storagePath: m["storage_path"] as String,
    url: m["url"] as String?,
    expiryDate: m["expiry_date"] as String?,
    createdAt: m["created_at"] as String? ?? "",
  );
  final String id;
  final String title;
  final String folder;
  final String storagePath;
  final String? url; // signed URL — null until explicitly fetched
  final String? expiryDate; // ISO date string e.g. "2026-12-31"
  final String createdAt;

  bool isExpiringSoon({int daysAhead = 30}) {
    if (expiryDate == null) return false;
    try {
      final expiry = DateTime.parse(expiryDate!);
      final daysLeft = expiry.difference(DateTime.now()).inDays;
      return daysLeft >= 0 && daysLeft <= daysAhead;
    } catch (_) {
      return false;
    }
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    try {
      return DateTime.parse(expiryDate!).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String get statusLabel {
    if (isExpired) return "expired";
    if (isExpiringSoon()) return "expiring";
    return "valid";
  }
}

// ─── Trip ─────────────────────────────────────────────────────────────────
class GambitTrip {
  const GambitTrip({
    required this.id,
    required this.reference,
    required this.status,
    required this.origin,
    required this.destination,
    required this.createdAt,
    this.tripType,
    this.cargoType,
    this.cargoDescription,
    this.tonnage,
    this.freightRate,
    this.startDate,
    this.endDate,
  });

  // origin and destination are required by the DB schema.
  // Defensive empty-string default prevents a parse crash if
  // a partial/stub response is returned during development.
  factory GambitTrip.fromMap(Map<String, dynamic> m) => GambitTrip(
    id: m["id"] as String,
    reference: m["reference"] as String,
    tripType: m["trip_type"] as String?,
    status: m["status"] as String? ?? "pending",
    origin: m["origin"] as String? ?? "",
    destination: m["destination"] as String? ?? "",
    cargoType: m["cargo_type"] as String?,
    cargoDescription: m["cargo_description"] as String?,
    tonnage: (m["tonnage"] as num?)?.toDouble(),
    freightRate: (m["freight_rate"] as num?)?.toDouble(),
    startDate: m["start_date"] as String?,
    endDate: m["end_date"] as String?,
    createdAt: m["created_at"] as String? ?? "",
  );
  final String id;
  final String reference;
  final String? tripType;
  final String status;
  final String origin;
  final String destination;
  final String? cargoType;
  final String? cargoDescription;
  final double? tonnage;
  final double? freightRate;
  final String? startDate;
  final String? endDate;
  final String createdAt;

  bool get isActive => status == "active" || status == "in_transit";
  bool get isCompleted => status == "completed" || status == "delivered";
  bool get isPending => status == "pending";
  bool get isCancelled => status == "cancelled";

  String get routeLabel => "$origin → $destination";

  double? get totalFreight =>
      (tonnage != null && freightRate != null) ? tonnage! * freightRate! : null;
}

// ─── Fleet ──────────────────────────────────────────────────────────────────
class GambitFleet {
  const GambitFleet({
    required this.id,
    required this.registration,
    required this.vehicleType,
    required this.status,
    required this.createdAt,
    this.make,
    this.model,
    this.year,
  });

  factory GambitFleet.fromMap(Map<String, dynamic> m) => GambitFleet(
    id: m["id"] as String,
    registration: m["registration"] as String,
    vehicleType: m["vehicle_type"] as String,
    status: m["status"] as String,
    make: m["make"] as String?,
    model: m["model"] as String?,
    year: m["year"] as int?,
    createdAt: m["created_at"] as String? ?? "",
  );

  final String id;
  final String registration;
  final String vehicleType;
  final String status;
  final String? make;
  final String? model;
  final int? year;
  final String createdAt;

  String get displayName =>
      "$registration · $vehicleType${make != null ? ' ($make)' : ''}";
}

// ─── Driver ─────────────────────────────────────────────────────────────────
class GambitDriver {
  const GambitDriver({
    required this.id,
    required this.fullName,
    required this.licenseNumber,
    required this.isActive,
    required this.createdAt,
    this.phone,
  });

  factory GambitDriver.fromMap(Map<String, dynamic> m) => GambitDriver(
    id: m["id"] as String,
    fullName: m["full_name"] as String,
    licenseNumber: m["license_number"] as String,
    phone: m["phone"] as String?,
    isActive: m["is_active"] as bool? ?? true,
    createdAt: m["created_at"] as String? ?? "",
  );

  final String id;
  final String fullName;
  final String licenseNumber;
  final String? phone;
  final bool isActive;
  final String createdAt;
}

// ─── Inventory ──────────────────────────────────────────────────────────────
class GambitInventory {
  const GambitInventory({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.createdAt,
    this.note,
  });

  factory GambitInventory.fromMap(Map<String, dynamic> m) => GambitInventory(
    id: m["id"] as String,
    name: m["name"] as String,
    category: m["category"] as String,
    unit: m["unit"] as String,
    quantity: (m["quantity"] as num?)?.toDouble() ?? 0.0,
    note: m["note"] as String?,
    createdAt: m["created_at"] as String? ?? "",
  );

  final String id;
  final String name;
  final String category;
  final String unit;
  final double quantity;
  final String? note;
  final String createdAt;
}
