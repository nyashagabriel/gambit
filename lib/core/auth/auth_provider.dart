// lib/core/auth/auth_provider.dart — GONYETI TLS

import "dart:convert";

import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../api/auth_api.dart";
import "../api/client.dart" as api;
// FIX 1: claims_model.dart no longer exists as a separate file.
// GambitClaims now lives in models.dart alongside all other models.
import "../models/models.dart";
import "role_guard.dart";

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.loading;
  GambitClaims? _claims;
  String? _error;

  // FIX 2: Remove the dead `final bool _isLoading = false` field.
  // It was declared final so it could never be set to true — any widget
  // reading isLoading would always get false regardless of what was happening.
  // _busy is the real loading flag. isLoading now points to it.
  bool _busy = false;

  // ── Getters ──────────────────────────────────────────────
  AuthStatus get status => _status;
  GambitClaims? get claims => _claims;
  String? get error => _error;
  bool get isBusy => _busy;
  bool get isLoading => _busy; // unified — was always false before
  bool get isAuth => _status == AuthStatus.authenticated;

  String get role => _claims?.role ?? "";
  String get username => _claims?.username ?? "";
  String get userId => _claims?.sub ?? "";
  String? get companyId => _claims?.companyId;
  bool get mustChangePw => _claims?.mustChangePw ?? false;
  String get homeRoute =>
      _claims != null ? RoleGuard.homeRouteFor(_claims!) : "/login";

  // ── Boot ─────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString("gambit_jwt");

    if (stored == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final parsed = _parseClaims(stored);
      if (!parsed.isValid) {
        await _clearSession(prefs);
        return;
      }

      api.setJwt(stored);
      _claims = parsed;

      // Verify server-side — also refreshes mustChangePw
      await refreshClaims();

      _status = AuthStatus.authenticated;
    } catch (_) {
      await _clearSession(prefs);
    }

    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────
  Future<bool> login(String username, String password) async {
    _setBusy(true);
    _error = null;

    try {
      final result = await AuthApi.login(
        username: username,
        password: password,
      );

      debugPrint(
        "[AUTH] login raw user: ${result.user.id} role=${result.user.role}",
      );

      api.setJwt(result.token);
      _claims = _parseClaims(result.token);

      debugPrint(
        "[AUTH] claims after parse: role=${_claims?.role} username=${_claims?.username} mustChangePw=${_claims?.mustChangePw}",
      );
      debugPrint("[AUTH] homeRoute: $homeRoute");

      _status = AuthStatus.authenticated;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("gambit_jwt", result.token);

      _setBusy(false);
      notifyListeners();
      return true;
    } on api.GonyetiApiException catch (e) {
      debugPrint("[AUTH] login api error: ${e.statusCode} ${e.message}");
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      api.setJwt(null);
      _setBusy(false);
      notifyListeners();
      return false;
    } catch (e, st) {
      debugPrint("[AUTH] login unexpected: $e\n$st");
      _error = "An unexpected error occurred. Please try again.";
      _status = AuthStatus.unauthenticated;
      _setBusy(false);
      notifyListeners();
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────
  Future<void> logout() async {
    api.setJwt(null);
    _claims = null;
    _error = null;
    _status = AuthStatus.unauthenticated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("gambit_jwt");

    notifyListeners();
  }

  // ── Refresh claims ────────────────────────────────────────
  Future<void> refreshClaims() async {
    if (_claims == null) return;
    try {
      final user = await AuthApi.me();
      _claims = GambitClaims(
        sub: _claims!.sub,
        username: _claims!.username,
        fullName: user.fullName,
        role: _claims!.role,
        companyId: _claims!.companyId,
        mustChangePw: user.mustChangePw,
        iat: _claims!.iat,
        exp: _claims!.exp,
      );
      notifyListeners();
    } on api.GonyetiApiException catch (e) {
      if (e.isUnauthorized) await logout();
    } catch (_) {
      // Non-critical network hiccup — keep existing claims
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    api.setJwt(null);
    await prefs.remove("gambit_jwt");
    _claims = null;
    _status = AuthStatus.unauthenticated;
  }

  GambitClaims _parseClaims(String token) {
    final parts = token.split(".");
    if (parts.length != 3) throw const FormatException("Invalid JWT format");

    final norm = parts[1].replaceAll("-", "+").replaceAll("_", "/");
    final padded = norm.padRight((norm.length + 3) ~/ 4 * 4, "=");
    final decoded = utf8.decode(base64Decode(padded));

    final Map<String, dynamic> payload =
        jsonDecode(decoded) as Map<String, dynamic>;

    // DEBUG: Print full JWT payload
    if (kDebugMode) {
      debugPrint("[JWT] Decoded payload: $payload");
      debugPrint("[JWT] role field: ${payload['role']}");
      debugPrint("[JWT] Keys: ${payload.keys.toList()}");
    }

    return GambitClaims.fromMap(payload);
  }
}
