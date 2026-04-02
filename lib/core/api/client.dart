// lib/core/api/client.dart — GAMBIT TSL
//
// Every API call in the app goes through rpc().
// Rules:
//   1. apikey header on every request — required by the Supabase gateway
//   2. Authorization: Bearer <jwt> on authenticated requests
//   3. All errors surface as GambitApiException — callers never see raw http errors
//   4. Timeout is enforced; network errors are caught and re-thrown uniformly
//   5. JWT is held in memory only — no persistence here (AuthProvider owns persistence)

import "dart:convert";
import "package:http/http.dart" as http;
import "../constants.dart";

// ─── Exception ────────────────────────────────────────────────────────────────
class GambitApiException implements Exception {
  const GambitApiException({required this.statusCode, required this.message});
  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isUnprocessable => statusCode == 422;
  bool get isServerError => statusCode >= 500;

  @override
  String toString() => message;
}

// ─── In-memory JWT store ──────────────────────────────────────────────────────
// Only AuthProvider calls setJwt(). All other code calls rpc().
String? _jwt;

void setJwt(String? token) => _jwt = token;
String? getJwt() => _jwt;

// ─── Core RPC function ────────────────────────────────────────────────────────
/// POSTs to a Gambit TSL Supabase edge function.
///
/// [endpoint]    — function file name without extension: "auth", "users", etc.
/// [body]        — JSON payload; must include an "action" key
/// [requiresAuth]— false only for the login action
Future<Map<String, dynamic>> rpc(
  String endpoint,
  Map<String, dynamic> body, {
  bool requiresAuth = true,
}) async {
  if (GambitConfig.anonKey.isEmpty) {
    throw const GambitApiException(
      statusCode: 0,
      message: "App is misconfigured: GAMBIT_ANON_KEY is not set.",
    );
  }

  final url = Uri.parse("${GambitConfig.baseUrl}/$endpoint");

  final headers = <String, String>{
    "Content-Type": "application/json",
    "apikey": GambitConfig.anonKey,
  };

  if (requiresAuth) {
    final token = _jwt;
    if (token == null) {
      throw const GambitApiException(
        statusCode: 401,
        message: "Not signed in.",
      );
    }
    headers["Authorization"] = "Bearer $token";
  }

  http.Response response;
  try {
    response = await http
        .post(url, headers: headers, body: jsonEncode(body))
        .timeout(GambitConfig.requestTimeout);
  } on Exception catch (e) {
    throw GambitApiException(
      statusCode: 0,
      message: "Network error. Please check your connection. ($e)",
    );
  }

  Map<String, dynamic> data;
  try {
    data = jsonDecode(response.body) as Map<String, dynamic>;
  } catch (_) {
    throw GambitApiException(
      statusCode: response.statusCode,
      message: "Unexpected server response (${response.statusCode}).",
    );
  }

  if (response.statusCode < 200 || response.statusCode >= 300) {
    final msg =
        data["error"] as String? ??
        data["message"] as String? ??
        "Request failed (${response.statusCode}).";
    throw GambitApiException(statusCode: response.statusCode, message: msg);
  }

  return data;
}
