// lib/core/auth/role_guard.dart — GAMBIT TSL
//
// UI-side role logic. The server enforces the same rules independently.
// If the server rejects a request, it wins — this guard is UX-only.
import "package:gambit/core/models/models.dart";

import "../constants.dart";

class RoleGuard {
  RoleGuard._();

  // ── Hierarchy helpers ──────────────────────────────────────────────────────
  static int rankOf(String role) => GambitConfig.roleHierarchy.indexOf(role);

  /// True if [actorRole] meets or exceeds [requiredRole].
  static bool hasRole(String actorRole, String requiredRole) =>
      rankOf(actorRole) >= rankOf(requiredRole);

  /// True if [actorRole] is strictly more powerful than [targetRole].
  static bool canActOn(String actorRole, String targetRole) =>
      rankOf(actorRole) > rankOf(targetRole);

  // ── Claims shortcuts ───────────────────────────────────────────────────────
  static bool isSuperAdmin(GambitClaims c)     => c.role == "super_admin";
  static bool isAtLeastAdmin(GambitClaims c)   => hasRole(c.role, "company_admin");
  static bool isAtLeastStaff(GambitClaims c)   => hasRole(c.role, "staff");

  // ── Company scope ──────────────────────────────────────────────────────────
  static bool canAccessCompany(GambitClaims c, String companyId) =>
      isSuperAdmin(c) || c.companyId == companyId;

  // ── Home route after login ─────────────────────────────────────────────────
  static String homeRouteFor(GambitClaims c) {
    if (c.mustChangePw) return "/change-password";
    return switch (c.role) {
      "super_admin"   => "/super/dashboard",
      "company_admin" => "/admin/dashboard",
      "staff"         => "/staff/dashboard",
      _               => "/user/dashboard",
    };
  }

  // ── Feature permissions ────────────────────────────────────────────────────
  static bool canCreateRole(GambitClaims actor, String targetRole) =>
      canActOn(actor.role, targetRole);

  static bool canManageUser(GambitClaims actor, GambitUser target) =>
      canAccessCompany(actor, target.companyId ?? "") &&
      canActOn(actor.role, target.role);

  static bool canManageCompanies(GambitClaims actor)  => isSuperAdmin(actor);
  static bool canViewInvoices(GambitClaims actor)     => isAtLeastAdmin(actor);
  static bool canApproveInvoices(GambitClaims actor)  => isAtLeastAdmin(actor);
  static bool canManageFleet(GambitClaims actor)      => isAtLeastAdmin(actor);
  static bool canBookTrips(GambitClaims actor)        => isAtLeastStaff(actor);
  static bool canUploadDocuments(GambitClaims actor)  => isAtLeastStaff(actor);
  static bool canDeleteDocuments(GambitClaims actor)  => isAtLeastAdmin(actor);
}
