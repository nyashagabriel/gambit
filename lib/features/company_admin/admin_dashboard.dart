// lib/features/company_admin/admin_dashboard.dart — GONYETI TLS
import "package:flutter/material.dart";
import "package:gonyeti_tls/core/api/client.dart";
import "package:provider/provider.dart";

import "../../core/api/data_api.dart";
import "../../core/api/files_api.dart";
import "../../core/auth/auth_provider.dart";
import "../../core/auth/role_guard.dart";
import "../../core/models/models.dart";
import "../../shared/theme/gonyeti_theme.dart";
import "../../shared/widgets/widgets.dart";
import "driver_form.dart";
import "fleet_form.dart";
import "inventory_form.dart";
import "trip_form.dart";

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;

  late final List<ShellDestination> _destinations;

  @override
  void initState() {
    super.initState();
    _destinations = [
      const ShellDestination(
        label: "Home",
        icon: Icons.dashboard_rounded,
        screen: _HomeTab(),
      ),
      const ShellDestination(
        label: "Fleet",
        icon: Icons.local_shipping_rounded,
        screen: _FleetTab(),
      ),
      const ShellDestination(
        label: "Trips",
        icon: Icons.route_rounded,
        screen: _TripsTab(),
      ),
      const ShellDestination(
        label: "Drivers",
        icon: Icons.person_rounded,
        screen: _DriversTab(),
      ),
      const ShellDestination(
        label: "Docs",
        icon: Icons.folder_rounded,
        screen: _DocumentsTab(),
      ),
      const ShellDestination(
        label: "Stock",
        icon: Icons.inventory_2_rounded,
        screen: _InventoryTab(),
      ),
      const ShellDestination(
        label: "Invoices",
        icon: Icons.receipt_long_rounded,
        screen: _InvoicesTab(),
      ),
      const ShellDestination(
        label: "Settings",
        icon: Icons.settings_rounded,
        screen: _SettingsTab(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: "Dashboard",
      destinations: _destinations,
      currentIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      body: IndexedStack(
        index: _tab,
        children: _destinations.map((d) => d.screen).toList(),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<GambitTrip> _trips = [];
  List<GambitDocument> _docs = [];
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
      final results = await Future.wait([TripsApi.list(), FilesApi.list()]);
      _trips = results[0] as List<GambitTrip>;
      _docs = results[1] as List<GambitDocument>;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final activeTrips = _trips.where((t) => t.isActive).length;
    final expiringDocs = _docs.where((d) => d.isExpiringSoon()).length;
    final expiredDocs = _docs.where((d) => d.isExpired).length;

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: context.colors.accent,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dashboard",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: context.colors.text,
                        ),
                      ),
                      Text(
                        auth.username.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.logout_rounded,
                    color: context.colors.textSub,
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

            if (_loading)
              Center(
                child: CircularProgressIndicator(
                  color: context.colors.accent,
                  strokeWidth: 2,
                ),
              ),

            if (_error != null) GAlert(message: _error!, type: "danger"),

            if (!_loading) ...[
              Row(
                children: [
                  GStatCard(
                    icon: Icons.route_rounded,
                    label: "ACTIVE TRIPS",
                    value: "$activeTrips",
                    color: context.colors.blue,
                  ),
                  const SizedBox(width: 10),
                  GStatCard(
                    icon: Icons.local_shipping_rounded,
                    label: "TOTAL TRIPS",
                    value: "${_trips.length}",
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  GStatCard(
                    icon: Icons.folder_rounded,
                    label: "DOCUMENTS",
                    value: "${_docs.length}",
                  ),
                  const SizedBox(width: 10),
                  GStatCard(
                    icon: Icons.warning_rounded,
                    label: "EXPIRING",
                    value: "$expiringDocs",
                    color: context.colors.warn,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (expiredDocs > 0)
                GAlert(
                  message: "$expiredDocs document(s) have expired",
                  sub: "Go to Docs to review",
                  type: "danger",
                ),
              if (expiringDocs > 0)
                GAlert(
                  message: "$expiringDocs document(s) expiring soon",
                  sub: "Tap Docs to review",
                  type: "warn",
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Fleet Tab ─────────────────────────────────────────────────────────────────
class _FleetTab extends StatefulWidget {
  const _FleetTab();
  @override
  State<_FleetTab> createState() => _FleetTabState();
}

class _FleetTabState extends State<_FleetTab> {
  List<GambitFleet> _fleet = [];
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
      _fleet = await FleetApi.list();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([GambitFleet? initial]) async {
    final bool? changed = await FleetForm.show(context, initial: initial);
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        backgroundColor: context.colors.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: context.colors.accent,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "Fleet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: context.colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${_fleet.length} vehicle(s)",
              style: TextStyle(
                fontSize: 11,
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              Center(
                child: CircularProgressIndicator(
                  color: context.colors.accent,
                  strokeWidth: 2,
                ),
              ),
            if (_error != null) GAlert(message: _error!, type: "danger"),
            ..._fleet.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _openForm(f),
                  borderRadius: BorderRadius.circular(12),
                  child: GCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.colors.blueDim,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.local_shipping_rounded,
                            size: 18,
                            color: context.colors.blue,
                            semanticLabel: "",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.registration,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: context.colors.text,
                                ),
                              ),
                              Text(
                                f.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GBadge(
                          label: f.status,
                          color: GBadge.colorForStatus(context, f.status),
                        ),
                      ],
                    ),
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

// ── Trips Tab ─────────────────────────────────────────────────────────────────
class _TripsTab extends StatefulWidget {
  const _TripsTab();
  @override
  State<_TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<_TripsTab> {
  List<GambitTrip> _trips = [];
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
      _trips = await TripsApi.list();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm() async {
    setState(() => _loading = true);
    try {
      final fleet = await FleetApi.list();
      final drivers = await DriversApi.list();
      if (mounted) setState(() => _loading = false);
      if (mounted) {
        final changed = await TripForm.show(context, fleet, drivers);
        if (changed == true) _load();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        backgroundColor: context.colors.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: context.colors.accent,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "Trips",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: context.colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${_trips.length} trip(s)",
              style:  TextStyle(
                fontSize: 11,
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
               Center(
                child: CircularProgressIndicator(
                  color: context.colors.accent,
                  strokeWidth: 2,
                ),
              ),
            if (_error != null) GAlert(message: _error!, type: "danger"),
            ..._trips.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GCard(
                  borderColor: t.isActive
                      ? context.colors.blue.withAlpha(60)
                      : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.reference,
                              style:  TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: context.colors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${t.origin} → ${t.destination}",
                              style:  TextStyle(
                                fontSize: 12,
                                color: context.colors.textSub,
                              ),
                            ),
                            if (t.cargoType != null) ...[
                              const SizedBox(height: 4),
                              GChip(
                                icon: Icons.inventory_2_rounded,
                                label: t.cargoType!,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GBadge(
                        label: t.status,
                        color: GBadge.colorForStatus(context, t.status),
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

// ── Documents Tab ─────────────────────────────────────────────────────────────
class _DocumentsTab extends StatefulWidget {
  const _DocumentsTab();
  @override
  State<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<_DocumentsTab> {
  List<GambitDocument> _docs = [];
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
      _docs = await FilesApi.list();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(GambitDocument doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.elevated,
        title:  Text(
          "Delete document?",
          style: TextStyle(
            color: context.colors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Remove "${doc.title}"?',
          style:  TextStyle(color: context.colors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:  Text(
              "Delete",
              style: TextStyle(color: context.colors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FilesApi.delete(documentId: doc.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
  }

  String _expiryLabel(GambitDocument doc) {
    if (doc.expiryDate == null) return "";
    try {
      final d = DateTime.parse(doc.expiryDate!);
      final days = d.difference(DateTime.now()).inDays;
      if (days < 0) return "Expired";
      if (days == 0) return "Expires today";
      if (days <= 30) return "Expires in $days d";
      return "Expires ${doc.expiryDate!.split("T")[0]}";
    } catch (_) {
      return doc.expiryDate ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canDelete =
        auth.claims != null && RoleGuard.canDeleteDocuments(auth.claims!);

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: context.colors.accent,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "Documents",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: context.colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${_docs.length} file(s)",
              style: TextStyle(
                fontSize: 11,
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              Center(
                child: CircularProgressIndicator(
                  color: context.colors.accent,
                  strokeWidth: 2,
                ),
              ),
            if (_error != null) GAlert(message: _error!, type: "danger"),
            ..._docs.map((doc) {
              final expired = doc.isExpired;
              final expiring = doc.isExpiringSoon();
              final borderColor = expired
                  ? context.colors.danger.withAlpha(80)
                  : expiring
                  ? context.colors.warn.withAlpha(80)
                  : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GCard(
                  borderColor: borderColor,
                  child: Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file_rounded,
                        size: 20,
                        color: context.colors.textSub,
                        semanticLabel: "",
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: context.colors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  doc.folder.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: context.colors.textMuted,
                                    letterSpacing: .8,
                                  ),
                                ),
                                if (doc.expiryDate != null) ...[
                                  Text(
                                    " · ",
                                    style: TextStyle(
                                      color: context.colors.textMuted,
                                      fontSize: 9,
                                    ),
                                  ),
                                  Text(
                                    _expiryLabel(doc),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: expired
                                          ? context.colors.danger
                                          : expiring
                                          ? context.colors.warn
                                          : context.colors.textMuted,
                                      fontWeight: (expired || expiring)
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (canDelete)
                        Semantics(
                          button: true,
                          label: "Delete ${doc.title}",
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_rounded,
                              size: 16,
                              color: context.colors.textMuted,
                            ),
                            onPressed: () => _delete(doc),
                            tooltip: "Delete",
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Settings Tab ──────────────────────────────────────────────────────────────
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();
  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  int _section = 0;

  final _oldPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confPwCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _oldPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confPwCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPwCtrl.text != _confPwCtrl.text) {
      setState(() => _error = "Passwords do not match");
      return;
    }
    if (_newPwCtrl.text.length < 8) {
      setState(() => _error = "Password must be at least 8 characters");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      await rpc("auth", {
        "action": "change_password",
        "old_password": _oldPwCtrl.text,
        "new_password": _newPwCtrl.text,
      });
      if (!mounted) return;
      await context.read<AuthProvider>().refreshClaims();
      _oldPwCtrl.clear();
      _newPwCtrl.clear();
      _confPwCtrl.clear();
      setState(() {
        _loading = false;
        _success = "Password updated successfully";
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _saveEmail() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains("@")) {
      setState(() => _error = "Enter a valid email address");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      await rpc("auth", {"action": "set_recovery_email", "email": email});
      setState(() {
        _loading = false;
        _success = "Recovery email saved";
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "Settings",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: context.colors.text,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TabPill(
                "Password",
                0,
                _section,
                (i) => setState(() {
                  _section = i;
                  _error = null;
                  _success = null;
                }),
              ),
              const SizedBox(width: 8),
              _TabPill(
                "Recovery Email",
                1,
                _section,
                (i) => setState(() {
                  _section = i;
                  _error = null;
                  _success = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: GAlert(message: _error!, type: "danger"),
            ),
          if (_success != null)
            Semantics(
              liveRegion: true,
              child: GAlert(message: _success!, type: "success"),
            ),

          if (_section == 0) ...[
            GInput(
              label: "CURRENT PASSWORD",
              obscure: true,
              controller: _oldPwCtrl,
              prefixIcon: Icons.lock_rounded,
              textInputAction: TextInputAction.next,
            ),
            GInput(
              label: "NEW PASSWORD",
              obscure: true,
              controller: _newPwCtrl,
              prefixIcon: Icons.lock_open_rounded,
              textInputAction: TextInputAction.next,
            ),
            GInput(
              label: "CONFIRM NEW PASSWORD",
              obscure: true,
              controller: _confPwCtrl,
              prefixIcon: Icons.lock_open_rounded,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _changePassword(),
            ),
            GButton(
              label: "UPDATE PASSWORD",
              icon: Icons.check_rounded,
              color: context.colors.success,
              fullWidth: true,
              loading: _loading,
              onPressed: _changePassword,
            ),
          ] else ...[
            const GAlert(
              message: "Recovery email is optional",
              sub:
                  "Used only for password reset. You always sign in with your username.",
            ),
            GInput(
              label: "EMAIL ADDRESS",
              hint: "you@company.co.zw",
              controller: _emailCtrl,
              prefixIcon: Icons.mail_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveEmail(),
            ),
            GButton(
              label: "SAVE EMAIL",
              icon: Icons.check_rounded,
              color: context.colors.success,
              fullWidth: true,
              loading: _loading,
              onPressed: _saveEmail,
            ),
          ],
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill(this.label, this.index, this.current, this.onTap);
  final String label;
  final int index, current;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final sel = index == current;
    return Expanded(
      child: Semantics(
        button: true,
        selected: sel,
        label: label,
        child: GestureDetector(
          onTap: () => onTap(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? context.colors.accentDim : context.colors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: sel ? context.colors.accent : context.colors.border,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: sel ? context.colors.accent : context.colors.textSub,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Drivers Tab ───────────────────────────────────────────────────────────────
class _DriversTab extends StatefulWidget {
  const _DriversTab();

  @override
  State<_DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends State<_DriversTab> {
  List<GambitDriver> _drivers = [];
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
      _drivers = await DriversApi.list();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([GambitDriver? initial]) async {
    final bool? changed = await DriverForm.show(context, initial: initial);
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        backgroundColor: context.colors.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: context.colors.accent,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "Drivers",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: context.colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${_drivers.length} driver(s)",
              style: TextStyle(
                fontSize: 11,
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              Center(
                child: CircularProgressIndicator(
                  color: context.colors.accent,
                  strokeWidth: 2,
                ),
              ),
            if (_error != null) GAlert(message: _error!, type: "danger"),
            ..._drivers.map(
              (driver) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _openForm(driver),
                  borderRadius: BorderRadius.circular(12),
                  child: GCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.colors.success.withAlpha(24),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: context.colors.success,
                            semanticLabel: "",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: context.colors.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "License: ${driver.licenseNumber}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GBadge(
                          label: driver.isActive ? "active" : "inactive",
                          color: GBadge.colorForStatus(
                            (driver.isActive ? "active" : "banned") as BuildContext,
                            context as String,
                          ),
                        ),
                      ],
                    ),
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

// ── Inventory Tab ─────────────────────────────────────────────────────────────
class _InventoryTab extends StatefulWidget {
  const _InventoryTab();
  @override
  State<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTab> {
  List<GambitInventory> _items = [];
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
      _items = await InventoryApi.list();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm() async {
    final bool? changed = await InventoryForm.show(context);
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        backgroundColor: context.colors.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: context.colors.accent,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "Inventory",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: context.colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${_items.length} items(s)",
              style: TextStyle(
                fontSize: 11,
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              Center(
                child: CircularProgressIndicator(
                  color: context.colors.accent,
                  strokeWidth: 2,
                ),
              ),
            if (_error != null) GAlert(message: _error!, type: "danger"),
            if (!_loading && _error == null && _items.isEmpty)
              const GAlert(
                message: "No inventory yet",
                sub: "Add your first item",
              ),
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colors.blueDim,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          size: 18,
                          color: context.colors.blue,
                          semanticLabel: "",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: context.colors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Qty: ${item.quantity} ${item.unit} · ${item.category}",
                              style: TextStyle(
                                fontSize: 11,
                                color: context.colors.textMuted,
                              ),
                            ),
                            if (item.note != null && item.note!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.note!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.textMuted,
                                ),
                              ),
                            ],
                          ],
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

// ── Invoices Tab ──────────────────────────────────────────────────────────────
class _InvoicesTab extends StatefulWidget {
  const _InvoicesTab();

  @override
  State<_InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<_InvoicesTab> {
  List<GambitTrip> _trips = [];
  final Set<String> _paidTripIds = <String>{};
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
      _trips = await TripsApi.list();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billableTrips = _trips
        .where(
          (trip) => trip.status == "completed" || trip.status == "delivered",
        )
        .toList();
    final unpaidAmount = billableTrips
        .where((trip) => !_paidTripIds.contains(trip.id))
        .fold<double>(
          0,
          (sum, trip) => sum + ((trip.tonnage ?? 0) * (trip.freightRate ?? 0)),
        );

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: context.colors.accent,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "Invoices",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: context.colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Billable trips: ${billableTrips.length}",
              style: TextStyle(
                fontSize: 11,
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            GAlert(
              message:
                  "Estimated unpaid value: \$${unpaidAmount.toStringAsFixed(2)}",
              sub: "Derived from completed/delivered trips",
            ),
            if (_loading)
              Center(
                child: CircularProgressIndicator(
                  color: context.colors.accent,
                  strokeWidth: 2,
                ),
              ),
            if (_error != null) GAlert(message: _error!, type: "danger"),
            if (!_loading && billableTrips.isEmpty)
              const GAlert(
                message: "No billable trips yet",
                sub: "Completed or delivered trips appear here",
              ),
            ...billableTrips.map((trip) {
              final amount = (trip.tonnage ?? 0) * (trip.freightRate ?? 0);
              final isPaid = _paidTripIds.contains(trip.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.reference,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.colors.text,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${trip.origin} → ${trip.destination}",
                              style: TextStyle(
                                fontSize: 11,
                                color: context.colors.textSub,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "\$${amount.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      GButton(
                        label: isPaid ? "PAID" : "MARK PAID",
                        icon: isPaid
                            ? Icons.check_circle_rounded
                            : Icons.payments_rounded,
                        small: true,
                        color: isPaid
                            ? context.colors.success
                            : context.colors.blue,
                        onPressed: () {
                          setState(() {
                            if (isPaid) {
                              _paidTripIds.remove(trip.id);
                            } else {
                              _paidTripIds.add(trip.id);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
