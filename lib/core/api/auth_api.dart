// lib/core/api/auth_api.dart — GONYETI TLS
// Typed wrappers around the /auth edge function.
// AuthProvider calls these — nothing else should.
import "package:gonyeti_tls/core/models/models.dart";

import "client.dart";

class AuthApi {
  AuthApi._();

  /// Returns the raw JWT and the user record.
  /// AuthProvider is responsible for storing the JWT and parsing claims.
  static Future<({String token, GambitUser user})> login({
    required String username,
    required String password,
  }) async {
    final data = await rpc("auth", {
      "action": "login",
      "username": username.trim().toLowerCase(),
      "password": password,
    }, requiresAuth: false);
    return (
      token: data["token"] as String,
      user: GambitUser.fromMap(data["user"] as Map<String, dynamic>),
    );
  }

  static Future<GambitUser> me() async {
    final data = await rpc("auth", {"action": "me"});
    return GambitUser.fromMap(data["user"] as Map<String, dynamic>);
  }

  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await rpc("auth", {
      "action": "change_password",
      "old_password": oldPassword,
      "new_password": newPassword,
    });
  }

  static Future<void> setRecoveryEmail(String email) async {
    await rpc("auth", {
      "action": "set_recovery_email",
      "email": email.trim().toLowerCase(),
    });
  }

  static Future<GambitUser> createCompanyAdmin({
    required String companyId,
    required String username,
    required String password,
    String? fullName,
  }) async {
    final data = await rpc("auth", {
      "action": "create_company_admin",
      "company_id": companyId,
      "username": username,
      "password": password,
      if (fullName != null) "full_name": fullName,
    });
    return GambitUser.fromMap(data["user"] as Map<String, dynamic>);
  }
}
