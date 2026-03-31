// ── GAMBIT TSL · COMPANIES API ────────────────────────────────
// All calls to /functions/v1/companies (super_admin only)

import 'package:gambit/core/models/models.dart';

import 'client.dart';

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
    String? status,
    String? warningMessage,
  }) async {
    final data = await rpc("companies", {
      "action": "update",
      "company_id": companyId,
      if (status != null) "status": status,
      if (warningMessage != null) "warning_message": warningMessage,
    });
    return GambitCompany.fromMap(data["company"] as Map<String, dynamic>);
  }

  static Future<void> delete(String companyId) async {
    await rpc("companies", {"action": "delete", "company_id": companyId});
  }
}

// ── GAMBIT TSL · USERS API ────────────────────────────────────
// All calls to /functions/v1/users

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
    String? companyId, // only needed when super_admin specifies a company
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
