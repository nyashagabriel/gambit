// lib/core/constants.dart — GAMBIT TSL
//
// All runtime config comes from --dart-define at build time.
// Never hard-code credentials in source — rotate the anon key if you must
// check in, then update the GitHub secret immediately.
//
// Local dev: add a launch.json / run configuration with:
//   --dart-define=GAMBIT_BASE_URL=https://xxx.supabase.co/functions/v1
//   --dart-define=GAMBIT_ANON_KEY=sb_publishable_...

class GambitConfig {
  GambitConfig._();

  static const String baseUrl = String.fromEnvironment(
    "GAMBIT_BASE_URL",
    // Fallback only used if dart-define is missing — makes the misconfiguration
    // obvious rather than silently hitting the wrong endpoint.
  );

  static const String anonKey =  String.fromEnvironment(
    "GAMBIT_ANON_KEY",
     // Fallback only used if dart-define is missing — makes the misconfiguration
     // obvious rather than silently using an invalid key.
  );

  // ── Role hierarchy ────────────────────────────────────────────────────────
  // Order matters: higher index → more permissions.
  static const List<String> roleHierarchy = [
    "user",
    "staff",
    "company_admin",
    "super_admin",
  ];

  // ── Networking ────────────────────────────────────────────────────────────
  static const Duration requestTimeout = Duration(seconds: 20);
  static const int tokenRefreshBuffer = 300; // seconds before expiry
}

class GambitRole {
  GambitRole._();
  static const String superAdmin = "super_admin";
  static const String companyAdmin = "company_admin";
  static const String staff = "staff";
  static const String user = "user";
}
