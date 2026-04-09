// lib/app.dart — GONYETI TLS
// App entry point: sets up the ChangeNotifierProvider, theme, and named routes.
// _RoleGuarded handles the three redirect cases cleanly:
//   • not authenticated  → /login
//   • must change pw     → /change-password (unless already there)
//   • wrong role for route → correct home for their role

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "core/auth/auth_provider.dart";
import "core/auth/role_guard.dart";
import "features/auth/login_screen.dart";
import "features/company_admin/admin_dashboard.dart";
import "features/staff/staff_dashboard.dart";
import "features/super_admin/super_dashboard.dart";
import "shared/theme/gonyeti_theme.dart";

class GonyetiApp extends StatelessWidget {
  const GonyetiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
      child: MaterialApp(
        title: "Gonyeti TLS",
        debugShowCheckedModeBanner: false,
        theme: GonyetiTheme.light,
        darkTheme: GonyetiTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: "/login",
        routes: _routes,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  static final Map<String, WidgetBuilder> _routes = {
    "/login": (_) => const LoginScreen(),

    "/change-password": (_) =>
        const _Authenticated(child: ChangePasswordScreen()),

    "/super/dashboard": (_) =>
        const _RoleGuarded(minRole: "super_admin", child: SuperDashboard()),
    "/admin/dashboard": (_) =>
        const _RoleGuarded(minRole: "company_admin", child: AdminDashboard()),
    "/staff/dashboard": (_) =>
        const _RoleGuarded(minRole: "staff", child: StaffDashboard()),
    "/user/dashboard": (_) =>
        const _RoleGuarded(minRole: "user", child: UserDashboard()),
  };

  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(
          child: Text(
            "Page not found",
            style: TextStyle(color: GonyetiColors.textSub),
          ),
        ),
      ),
    );
  }
}

// ── _Authenticated ─────────────────────────────────────────────────────────────
// Redirects to /login if the user is not authenticated.
// Use this for routes that don't need a specific role (e.g. change-password).
class _Authenticated extends StatelessWidget {
  const _Authenticated({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.loading) {
      return const _Splash();
    }

    if (!auth.isAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, "/login");
      });
      return const SizedBox.shrink();
    }

    return child;
  }
}

// ── _RoleGuarded ───────────────────────────────────────────────────────────────
// Full guard: auth check + must-change-pw + role check.
class _RoleGuarded extends StatelessWidget {
  const _RoleGuarded({required this.minRole, required this.child});
  final String minRole;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Still booting
    if (auth.status == AuthStatus.loading) return const _Splash();

    // Not authenticated
    if (!auth.isAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, "/login");
      });
      return const SizedBox.shrink();
    }

    // Role insufficient — redirect to their actual home
    if (!RoleGuard.hasRole(auth.role, minRole)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, auth.homeRoute);
      });
      return const SizedBox.shrink();
    }

    return child;
  }
}

// ── Splash ─────────────────────────────────────────────────────────────────────
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: GonyetiColors.accent,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
