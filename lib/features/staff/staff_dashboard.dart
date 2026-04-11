// lib/features/staff/staff_dashboard.dart — GONYETI TLS
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../core/api/data_api.dart";
import "../../core/auth/auth_provider.dart";
import "../../core/models/models.dart";
import "../../shared/theme/gonyeti_theme.dart";
import "../../shared/widgets/widgets.dart";
import "docs_screen.dart";

// UserDashboard is also exported from here — it is the "user" role screen
class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text("My Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: colors.danger, semanticLabel: "Sign out"),
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "Welcome, ${auth.username}",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colors.text,
            ),
          ),
          Text(
            "DRIVER / USER",
            style: TextStyle(
              fontSize: 10,
              color: colors.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          const GAlert(
            message: "You have an active trip",
            sub: "Tap below to view details",
          ),
          const SizedBox(height: 8),
          _ActionRow(
            icon: Icons.route_rounded,
            label: "My Active Trip",
            sub: "View details & update status",
            color: context.colors.blue,
            onTap: () {},
          ),
          _ActionRow(
            icon: Icons.check_circle_rounded,
            label: "Submit POD",
            sub: "Proof of delivery",
            color: context.colors.success,
            onTap: () {},
          ),
          _ActionRow(
            icon: Icons.speed_rounded,
            label: "ODO Reading",
            sub: "Submit odometer reading",
            color: context.colors.warn,
            onTap: () {},
          ),
          _ActionRow(
            icon: Icons.lock_rounded,
            label: "Change Password",
            sub: "Update your credentials",
            color: context.colors.textSub,
            onTap: () => Navigator.pushNamed(context, "/change-password"),
          ),
        ],
      ),
    );
  }
}

// ── Staff Dashboard ───────────────────────────────────────────────────────────
class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});
  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _tab = 0;

  final _destinations = const [
    ShellDestination(
      label: "Home",
      icon: Icons.dashboard_rounded,
      screen: _StaffHomeTab(),
    ),
    ShellDestination(
      label: "Trips",
      icon: Icons.route_rounded,
      screen: _StaffTripsTab(),
    ),
    ShellDestination(
      label: "Docs",
      icon: Icons.folder_rounded,
      screen: _StaffDocsTab(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: "Operations",
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

// ── Staff Home ────────────────────────────────────────────────────────────────
class _StaffHomeTab extends StatefulWidget {
  const _StaffHomeTab();
  @override
  State<_StaffHomeTab> createState() => _StaffHomeTabState();
}

class _StaffHomeTabState extends State<_StaffHomeTab> {
  List<GambitTrip> _trips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _trips = await TripsApi.list();
    } catch (_) {
      // non-critical on home screen
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = context.colors;
    final activeTrips = _trips.where((t) => t.isActive).length;
    final pending = _trips.where((t) => t.status == "pending").length;

    return Scaffold(
      backgroundColor: colors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: colors.accent,
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
                        "Operations",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: colors.text,
                        ),
                      ),
                      Text(
                        "STAFF · ${auth.username.toUpperCase()}",
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.logout_rounded, color: colors.textSub, size: 20),
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
                  icon: Icons.route_rounded,
                  label: "MY TRIPS",
                  value: "${_trips.length}",
                ),
                const SizedBox(width: 10),
                GStatCard(
                  icon: Icons.local_fire_department_rounded,
                  label: "ACTIVE",
                  value: "$activeTrips",
                  color: context.colors.blue,
                ),
                const SizedBox(width: 10),
                GStatCard(
                  icon: Icons.pending_actions_rounded,
                  label: "PENDING",
                  value: "$pending",
                  color: context.colors.warn,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_loading && _trips.isNotEmpty)
              ..._trips
                  .where((t) => t.isActive)
                  .take(1)
                  .map((t) => _ActiveTripCard(trip: t)),
            const SizedBox(height: 16),
            Text(
              "QUICK ACTIONS",
              style: TextStyle(
                color: context.colors.textSub,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            _ActionRow(
              icon: Icons.route_rounded,
              label: "My Trips",
              sub: "Track & update progress",
              color: context.colors.blue,
              onTap: () {},
            ),
            _ActionRow(
              icon: Icons.folder_rounded,
              label: "Submit Documents",
              sub: "POD, permits & reports",
              color: context.colors.success,
              onTap: () {},
            ),
            _ActionRow(
              icon: Icons.lock_rounded,
              label: "Change Password",
              sub: "Update your credentials",
              color: context.colors.textSub,
              onTap: () => Navigator.pushNamed(context, "/change-password"),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({required this.trip});
  final GambitTrip trip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GCard(
      borderColor: colors.blue.withAlpha(80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.blueDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.route_rounded,
                  size: 18,
                  color: context.colors.blue,
                  semanticLabel: "",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ACTIVE · ${trip.reference}",
                      style: TextStyle(
                        color: context.colors.blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: .8,
                      ),
                    ),
                    Text(
                      "${trip.origin} → ${trip.destination}",
                        style: TextStyle(
                          color: colors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (trip.cargoType != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                GChip(icon: Icons.inventory_2_rounded, label: trip.cargoType!),
                if (trip.tonnage != null) ...[
                  const SizedBox(width: 12),
                  GChip(icon: Icons.scale_rounded, label: "${trip.tonnage}MT"),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              GButton(
                label: "Update POD",
                icon: Icons.check_circle_rounded,
                color: context.colors.success,
                small: true,
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              GButton(
                label: "ODO",
                icon: Icons.speed_rounded,
                outline: true,
                color: context.colors.textSub,
                small: true,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Staff Trips Tab ───────────────────────────────────────────────────────────
class _StaffTripsTab extends StatefulWidget {
  const _StaffTripsTab();
  @override
  State<_StaffTripsTab> createState() => _StaffTripsTabState();
}

class _StaffTripsTabState extends State<_StaffTripsTab> {
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: colors.accent,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "My Trips",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: context.colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${_trips.length} trip(s)",
              style: TextStyle(
                fontSize: 11,
                color: colors.textMuted,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.reference,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: context.colors.text,
                              ),
                            ),
                          ),
                          GBadge(
                            label: t.status,
                            color: GBadge.colorForStatus(context, t.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${t.origin} → ${t.destination}",
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.textSub,
                        ),
                      ),
                      if (t.isActive) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            GButton(
                              label: "Update Status",
                              icon: Icons.edit_rounded,
                              small: true,
                              color: context.colors.blue,
                              onPressed: () => _showUpdateSheet(t),
                            ),
                          ],
                        ),
                      ],
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

  void _showUpdateSheet(GambitTrip trip) {
    String? selectedStatus;
    final podCtrl = TextEditingController();
    final odoCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Update · ${trip.reference}",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: context.colors.text,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "STATUS"),
                dropdownColor: context.colors.elevated,
                initialValue: selectedStatus,
                items: const [
                  DropdownMenuItem(
                    value: "in_transit",
                    child: Text("In Transit"),
                  ),
                  DropdownMenuItem(
                    value: "delivered",
                    child: Text("Delivered"),
                  ),
                  DropdownMenuItem(
                    value: "completed",
                    child: Text("Completed"),
                  ),
                ],
                onChanged: (v) => setSheetState(() => selectedStatus = v),
              ),
              const SizedBox(height: 12),
              GInput(
                label: "POD NUMBER",
                hint: "Optional",
                controller: podCtrl,
                prefixIcon: Icons.receipt_rounded,
                textInputAction: TextInputAction.next,
              ),
              GInput(
                label: "ODO READING (km)",
                hint: "Optional",
                controller: odoCtrl,
                prefixIcon: Icons.speed_rounded,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
              ),
              GButton(
                label: "SAVE UPDATE",
                icon: Icons.check_rounded,
                color: context.colors.success,
                fullWidth: true,
                loading: loading,
                onPressed: () async {
                  setSheetState(() => loading = true);
                  try {
                    await TripsApi.update(
                      tripId: trip.id,
                      status: selectedStatus,
                      podNumber: podCtrl.text.trim().isEmpty
                          ? null
                          : podCtrl.text.trim(),
                      odoReading: odoCtrl.text.trim().isEmpty
                          ? null
                          : odoCtrl.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  } catch (e) {
                    setSheetState(() => loading = false);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: context.colors.danger,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Staff Docs Tab ────────────────────────────────────────────────────────────
class _StaffDocsTab extends StatelessWidget {
  const _StaffDocsTab();
  @override
  Widget build(BuildContext context) => const StaffDocsScreen();
}

// ── Shared action row ─────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label, sub;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GCard(
        semanticLabel: label,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color, semanticLabel: ""),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: context.colors.text,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.textMuted,
              semanticLabel: "",
            ),
          ],
        ),
      ),
    );
  }
}
