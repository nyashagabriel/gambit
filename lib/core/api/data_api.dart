// lib/core/api/data_api.dart — GAMBIT TSL
// Typed wrappers for companies, users, trips, fleet, drivers.
// All calls go through rpc() in client.dart.

import "package:gambit/core/models/models.dart";
import "client.dart";

// ─── Companies (super_admin only) ─────────────────────────────────────────────
class CompaniesApi {
  CompaniesApi._();

  static Future<List<GambitCompany>> list() async {
    final data = await rpc("companies", {"action": "list"});
    return (data["companies"] as List)
        .map((c) => GambitCompany.fromMap(c as Map<String, dynamic>))
        .toList();
  }

  static Future<GambitCompany> create(String name) async {
    final data = await rpc("companies", {"action": "create", "name": name});
    return GambitCompany.fromMap(data["company"] as Map<String, dynamic>);
  }

  static Future<GambitCompany> update({
    required String companyId,
    String? name,
    String? status,
    String? warningMessage,
  }) async {
    final data = await rpc("companies", {
      "action": "update",
      "company_id": companyId,
      if (name != null) "name": name,
      if (status != null) "status": status,
      if (warningMessage != null) "warning_message": warningMessage,
    });
    return GambitCompany.fromMap(data["company"] as Map<String, dynamic>);
  }

  static Future<void> delete(String companyId) async {
    await rpc("companies", {"action": "delete", "company_id": companyId});
  }
}

// ─── Users ────────────────────────────────────────────────────────────────────
class UsersApi {
  UsersApi._();

  static Future<List<GambitUser>> list({String? companyId}) async {
    final data = await rpc("users", {
      "action": "list",
      if (companyId != null) "company_id": companyId,
    });
    return (data["users"] as List)
        .map((u) => GambitUser.fromMap(u as Map<String, dynamic>))
        .toList();
  }

  static Future<GambitUser> create({
    required String username,
    required String password,
    required String role,
    String? fullName,
    String? phone,
    String? companyId,
  }) async {
    final data = await rpc("users", {
      "action": "create",
      "username": username,
      "password": password,
      "role": role,
      if (fullName != null) "full_name": fullName,
      if (phone != null) "phone": phone,
      if (companyId != null) "company_id": companyId,
    });
    return GambitUser.fromMap(data["user"] as Map<String, dynamic>);
  }

  static Future<GambitUser> update({
    required String userId,
    bool? isActive,
    String? fullName,
    String? phone,
  }) async {
    final data = await rpc("users", {
      "action": "update",
      "user_id": userId,
      if (isActive != null) "is_active": isActive,
      if (fullName != null) "full_name": fullName,
      if (phone != null) "phone": phone,
    });
    return GambitUser.fromMap(data["user"] as Map<String, dynamic>);
  }

  static Future<void> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    await rpc("users", {
      "action": "reset_pw",
      "user_id": userId,
      "new_password": newPassword,
    });
  }

  static Future<void> delete(String userId) async {
    await rpc("users", {"action": "delete", "user_id": userId});
  }
}

// ─── Trips ────────────────────────────────────────────────────────────────────
class TripsApi {
  TripsApi._();

  static Future<List<GambitTrip>> list({String? companyId}) async {
    final data = await rpc("api", {
      "action": "trip_list",
      if (companyId != null) "company_id": companyId,
    });
    return (data["trips"] as List)
        .map((t) => GambitTrip.fromMap(t as Map<String, dynamic>))
        .toList();
  }

  static Future<GambitTrip> create({
    required String reference,
    required String origin,
    required String destination,
    String? tripType,
    String? horseId,
    String? driverId,
    String? cargoType,
    String? cargoDescription,
    double? tonnage,
    double? freightRate,
    String? startDate,
    String? endDate,
    String? companyId,
  }) async {
    final data = await rpc("api", {
      "action": "trip_create",
      "reference": reference,
      "origin": origin,
      "destination": destination,
      if (tripType != null) "trip_type": tripType,
      if (horseId != null) "horse_id": horseId,
      if (driverId != null) "driver_id": driverId,
      if (cargoType != null) "cargo_type": cargoType,
      if (cargoDescription != null) "cargo_description": cargoDescription,
      if (tonnage != null) "tonnage": tonnage,
      if (freightRate != null) "freight_rate": freightRate,
      if (startDate != null) "start_date": startDate,
      if (endDate != null) "end_date": endDate,
      if (companyId != null) "company_id": companyId,
    });
    return GambitTrip.fromMap(data["trip"] as Map<String, dynamic>);
  }

  static Future<GambitTrip> update({
    required String tripId,
    String? status,
    String? podNumber,
    String? odoReading,
    String? notes,
    String? horseId,
    String? driverId,
  }) async {
    final data = await rpc("api", {
      "action": "trip_update",
      "trip_id": tripId,
      if (status != null) "status": status,
      if (podNumber != null) "pod_number": podNumber,
      if (odoReading != null) "odo_reading": odoReading,
      if (notes != null) "notes": notes,
      if (horseId != null) "horse_id": horseId,
      if (driverId != null) "driver_id": driverId,
    });
    return GambitTrip.fromMap(data["trip"] as Map<String, dynamic>);
  }
}

// ─── Fleet ────────────────────────────────────────────────────────────────────
class FleetApi {
  FleetApi._();

  static Future<List<GambitFleet>> list({String? companyId}) async {
    final data = await rpc("api", {
      "action": "fleet_list",
      if (companyId != null) "company_id": companyId,
    });
    return (data["fleet"] as List)
        .map((f) => GambitFleet.fromMap(f as Map<String, dynamic>))
        .toList();
  }

  static Future<GambitFleet> create({
    required String regNumber,
    required String vehicleType,
    String? make,
    String? model,
    int? year,
    String? companyId,
  }) async {
    final data = await rpc("api", {
      "action": "fleet_create",
      "reg_number": regNumber,
      "vehicle_type": vehicleType,
      if (make != null) "make": make,
      if (model != null) "model": model,
      if (year != null) "year": year,
      if (companyId != null) "company_id": companyId,
    });
    return GambitFleet.fromMap(data["fleet"] as Map<String, dynamic>);
  }

  static Future<GambitFleet> update({
    required String fleetId,
    String? regNumber,
    String? vehicleType,
    String? model,
    int? year,
    String? status,
  }) async {
    final data = await rpc("api", {
      "action": "fleet_update",
      "fleet_id": fleetId,
      if (regNumber != null) "reg_number": regNumber,
      if (vehicleType != null) "vehicle_type": vehicleType,
      if (model != null) "model": model,
      if (year != null) "year": year,
      if (status != null) "status": status,
    });
    return GambitFleet.fromMap(data["fleet"] as Map<String, dynamic>);
  }
}

// ─── Drivers ──────────────────────────────────────────────────────────────────
class DriversApi {
  DriversApi._();

  static Future<List<GambitDriver>> list({String? companyId}) async {
    final data = await rpc("api", {
      "action": "driver_list",
      if (companyId != null) "company_id": companyId,
    });
    return (data["drivers"] as List)
        .map((d) => GambitDriver.fromMap(d as Map<String, dynamic>))
        .toList();
  }

  static Future<GambitDriver> create({
    required String firstName,
    required String lastName,
    required String licenseNumber,
    String? phone,
    String? companyId,
  }) async {
    final data = await rpc("api", {
      "action": "driver_create",
      "first_name": firstName,
      "last_name": lastName,
      "license_number": licenseNumber,
      if (phone != null) "phone": phone,
      if (companyId != null) "company_id": companyId,
    });
    return GambitDriver.fromMap(data["driver"] as Map<String, dynamic>);
  }

  static Future<GambitDriver> update({
    required String driverId,
    String? firstName,
    String? lastName,
    String? licenseNumber,
    String? phone,
    String? status,
  }) async {
    final data = await rpc("api", {
      "action": "driver_update",
      "driver_id": driverId,
      if (firstName != null) "first_name": firstName,
      if (lastName != null) "last_name": lastName,
      if (licenseNumber != null) "license_number": licenseNumber,
      if (phone != null) "phone": phone,
      if (status != null) "status": status,
    });
    return GambitDriver.fromMap(data["driver"] as Map<String, dynamic>);
  }
}

// ─── Inventory ────────────────────────────────────────────────────────────────
class InventoryApi {
  InventoryApi._();

  static Future<List<GambitInventory>> list({String? companyId}) async {
    final data = await rpc("api", {
      "action": "inventory_list",
      if (companyId != null) "company_id": companyId,
    });
    return (data["inventory"] as List)
        .map((i) => GambitInventory.fromMap(i as Map<String, dynamic>))
        .toList();
  }

  static Future<GambitInventory> create({
    required String name,
    required String category,
    required String unit,
    required num quantity,
    String? note,
    String? companyId,
  }) async {
    final data = await rpc("api", {
      "action": "inventory_create",
      "name": name,
      "category": category,
      "unit": unit,
      "quantity": quantity,
      if (note != null) "note": note,
      if (companyId != null) "company_id": companyId,
    });
    return GambitInventory.fromMap(data["item"] as Map<String, dynamic>);
  }
}
