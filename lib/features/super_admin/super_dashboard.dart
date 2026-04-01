// lib/features/super_admin/super_dashboard.dart — GAMBIT TSL
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../core/api/auth_api.dart";
import "../../core/api/data_api.dart";
import "../../core/auth/auth_provider.dart";
import "../../core/models/models.dart";
import "../../shared/theme/gambit_theme.dart";
import "../../shared/widgets/widgets.dart";

class SuperDashboard extends StatefulWidget {
  const SuperDashboard({super.key});
  @override
  State<SuperDashboard> createState() => _SuperDashboardState();
}

class _SuperDashboardState extends State<SuperDashboard> {
  int _tab = 0;

  final _destinations = const [
    ShellDestination(
      label: "Companies",
      icon: Icons.business_rounded,
      screen: _CompaniesTab(),
    ),
    ShellDestination(
      label: "Add Co.",
      icon: Icons.add_business_rounded,
      screen: _CreateCompanyTab(),
    ),
    ShellDestination(
      label: "Audit",
      icon: Icons.history_rounded,
      screen: _AuditTab(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: "Platform Control",
      destinations: _destinations,
      currentIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      body: Column(
        children: [
          const GChangePasswordBanner(),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: _destinations.map((d) => d.screen).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Companies Tab ─────────────────────────────────────────────────────────────
class _CompaniesTab extends StatefulWidget {
  const _CompaniesTab();
  @override
  State<_CompaniesTab> createState() => _CompaniesTabState();
}

class _CompaniesTabState extends State<_CompaniesTab> {
  List<GambitCompany> _companies = [];
  bool _loading = true;
  String? _error;

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
      _companies = await CompaniesApi.list();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(
    GambitCompany co,
    String status, {
    String? warningMsg,
  }) async {
    try {
      await CompaniesApi.update(
        companyId: co.id,
        status: status,
        warningMessage: warningMsg,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${co.name} → $status"),
            backgroundColor: GambitColors.success,
          ),
        );
      }
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

  void _showActions(GambitCompany co) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GambitColors.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              co.name,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: GambitColors.text,
              ),
            ),
            const SizedBox(height: 6),
            GBadge(label: co.status, color: GBadge.colorForStatus(co.status)),
            const SizedBox(height: 20),
            if (!co.isActive)
              GButton(
                label: "Reinstate",
                icon: Icons.check_circle_rounded,
                color: GambitColors.success,
                fullWidth: true,
                onPressed: () {
                  Navigator.pop(context);
                  _updateStatus(co, "active");
                },
              ),
            const SizedBox(height: 8),
            if (co.isActive)
              GButton(
                label: "Send Warning",
                icon: Icons.warning_rounded,
                color: GambitColors.warn,
                outline: true,
                fullWidth: true,
                onPressed: () {
                  Navigator.pop(context);
                  _updateStatus(
                    co,
                    "warned",
                    warningMsg: "Platform warning issued",
                  );
                },
              ),
            const SizedBox(height: 8),
            if (!co.isBanned)
              GButton(
                label: "Ban Company",
                icon: Icons.block_rounded,
                color: GambitColors.danger,
                outline: true,
                fullWidth: true,
                onPressed: () {
                  Navigator.pop(context);
                  _updateStatus(co, "banned");
                },
              ),
            const SizedBox(height: 8),
            GButton(
              label: "Cancel",
              color: GambitColors.textSub,
              outline: true,
              fullWidth: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _companies.where((c) => c.isActive).length;
    final issues = _companies.where((c) => !c.isActive).length;

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
                        "Platform Control",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: GambitColors.text,
                        ),
                      ),
                      Text(
                        "SUPER ADMIN",
                        style: TextStyle(
                          fontSize: 10,
                          color: GambitColors.textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: GambitColors.textSub,
                    size: 20,
                  ),
                  tooltip: "Sign out",
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, "/login");
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                GStatCard(
                  icon: Icons.business_rounded,
                  label: "TOTAL",
                  value: "${_companies.length}",
                ),
                const SizedBox(width: 10),
                GStatCard(
                  icon: Icons.check_circle_rounded,
                  label: "ACTIVE",
                  value: "$active",
                  color: GambitColors.success,
                ),
                const SizedBox(width: 10),
                GStatCard(
                  icon: Icons.warning_rounded,
                  label: "ISSUES",
                  value: "$issues",
                  color: issues > 0
                      ? GambitColors.danger
                      : GambitColors.textSub,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_error != null) GAlert(message: _error!, type: "danger"),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(
                  color: GambitColors.accent,
                  strokeWidth: 2,
                ),
              ),
            ..._companies.map(
              (co) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GCard(
                  borderColor: !co.isActive
                      ? GBadge.colorForStatus(co.status).withAlpha(80)
                      : null,
                  semanticLabel:
                      "${co.name}, status: ${co.status}. Tap for actions.",
                  onTap: () => _showActions(co),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    co.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: GambitColors.text,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GBadge(
                                  label: co.status,
                                  color: GBadge.colorForStatus(co.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Joined: ${co.createdAt.split("T")[0]}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: GambitColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: GambitColors.textMuted,
                        semanticLabel: "",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Company Tab ────────────────────────────────────────────────────────
class _CreateCompanyTab extends StatefulWidget {
  const _CreateCompanyTab();
  @override
  State<_CreateCompanyTab> createState() => _CreateCompanyTabState();
}

class _CreateCompanyTabState extends State<_CreateCompanyTab> {
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();

  bool _loading = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;

    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      setState(
        () => _error = "Company name, username and password are required",
      );
      return;
    }
    if (password.length < 8) {
      setState(() => _error = "Password must be at least 8 characters");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final company = await CompaniesApi.create(name);
      await AuthApi.createCompanyAdmin(
        companyId: company.id,
        username: username,
        password: password,
        fullName: _fullNameCtrl.text.trim().isEmpty
            ? null
            : _fullNameCtrl.text.trim(),
      );
      setState(() {
        _loading = false;
        _done = true;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _reset() {
    _nameCtrl.clear();
    _userCtrl.clear();
    _passCtrl.clear();
    _fullNameCtrl.clear();
    setState(() {
      _done = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GambitColors.bg,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Register Company",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: GambitColors.text,
            ),
          ),
          const Text(
            "New Gambit TSL tenant",
            style: TextStyle(fontSize: 11, color: GambitColors.textMuted),
          ),
          const SizedBox(height: 20),

          if (_done) ...[
            const GAlert(
              message: "Company and admin created!",
              sub: "Admin must change their password on first login.",
              type: "success",
            ),
            GButton(
              label: "Register Another",
              icon: Icons.add_rounded,
              fullWidth: true,
              onPressed: _reset,
            ),
          ] else ...[
            if (_error != null)
              Semantics(
                liveRegion: true,
                child: GAlert(message: _error!, type: "danger"),
              ),
            const Text(
              "COMPANY",
              style: TextStyle(
                color: GambitColors.textSub,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            GInput(
              label: "COMPANY NAME",
              hint: "e.g. Cancrit Enterprises",
              controller: _nameCtrl,
              prefixIcon: Icons.business_rounded,
              textInputAction: TextInputAction.next,
            ),
            const Divider(color: GambitColors.border, height: 24),
            const Text(
              "ADMIN ACCOUNT",
              style: TextStyle(
                color: GambitColors.textSub,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            GInput(
              label: "ADMIN USERNAME",
              hint: "e.g. cancrit_admin",
              controller: _userCtrl,
              prefixIcon: Icons.person_rounded,
              textInputAction: TextInputAction.next,
            ),
            GInput(
              label: "ADMIN FULL NAME",
              hint: "Optional",
              controller: _fullNameCtrl,
              prefixIcon: Icons.badge_rounded,
              textInputAction: TextInputAction.next,
            ),
            GInput(
              label: "TEMP PASSWORD",
              hint: "Min 8 characters",
              controller: _passCtrl,
              prefixIcon: Icons.lock_rounded,
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: GambitColors.accentDim,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GambitColors.accent.withAlpha(50)),
              ),
              child: const Text(
                "Admin will be required to change this password on first login.",
                style: TextStyle(color: GambitColors.accent, fontSize: 11),
              ),
            ),
            GButton(
              label: "CREATE COMPANY",
              icon: Icons.add_business_rounded,
              loading: _loading,
              fullWidth: true,
              onPressed: _submit,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Audit Tab ─────────────────────────────────────────────────────────────────
class _AuditTab extends StatefulWidget {
  const _AuditTab();

  @override
  State<_AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends State<_AuditTab> {
  List<GambitCompany> _companies = [];
  List<GambitUser> _users = [];
  bool _loading = true;
  String? _error;

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
      final results = await Future.wait([CompaniesApi.list(), UsersApi.list()]);
      _companies = results[0] as List<GambitCompany>;
      _users = results[1] as List<GambitUser>;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime _safeParse(String input) =>
      DateTime.tryParse(input) ?? DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Widget build(BuildContext context) {
    final events =
        <({DateTime at, String title, String sub, IconData icon, Color color})>[
          ..._companies.map(
            (c) => (
              at: _safeParse(c.createdAt),
              title: "Company onboarded",
              sub: "${c.name} · ${c.status.toUpperCase()}",
              icon: Icons.business_rounded,
              color: GambitColors.blue,
            ),
          ),
          ..._users.map(
            (u) => (
              at: _safeParse(u.createdAt),
              title: "User created",
              sub: "@${u.username} · ${u.role.replaceAll("_", " ")}",
              icon: Icons.person_add_alt_rounded,
              color: GambitColors.success,
            ),
          ),
        ]..sort((a, b) => b.at.compareTo(a.at));

    final warnedOrBlocked = _companies
        .where((c) => c.isWarned || c.isSuspended || c.isBanned)
        .length;

    return Scaffold(
      backgroundColor: GambitColors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: GambitColors.accent,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "Audit",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: GambitColors.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Recent platform activity",
              style: TextStyle(fontSize: 11, color: GambitColors.textMuted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                GStatCard(
                  icon: Icons.business_rounded,
                  label: "COMPANIES",
                  value: "${_companies.length}",
                  color: GambitColors.blue,
                ),
                const SizedBox(width: 10),
                GStatCard(
                  icon: Icons.people_alt_rounded,
                  label: "USERS",
                  value: "${_users.length}",
                  color: GambitColors.success,
                ),
                const SizedBox(width: 10),
                GStatCard(
                  icon: Icons.warning_rounded,
                  label: "ATTENTION",
                  value: "$warnedOrBlocked",
                  color: GambitColors.warn,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: GambitColors.accent,
                    strokeWidth: 2,
                  ),
                ),
              ),
            if (_error != null) GAlert(message: _error!, type: "danger"),
            if (!_loading && events.isEmpty)
              const GAlert(
                message: "No events yet",
                sub: "Create companies or users to populate this stream",
              ),
            if (!_loading && events.isNotEmpty)
              ...events
                  .take(20)
                  .map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: event.color.withAlpha(28),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                event.icon,
                                size: 16,
                                color: event.color,
                                semanticLabel: "",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: GambitColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    event.sub,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: GambitColors.textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${event.at.year}-${event.at.month.toString().padLeft(2, "0")}-${event.at.day.toString().padLeft(2, "0")}",
                              style: const TextStyle(
                                fontSize: 10,
                                color: GambitColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
