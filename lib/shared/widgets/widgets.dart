// lib/shared/widgets/widgets.dart — GAMBIT TSL
// Shared widget library. Accessibility: WCAG 2.1 AA throughout.

import "package:flutter/material.dart";
import "package:gambit/core/api/auth_api.dart";
import "package:provider/provider.dart";

import "../../core/auth/auth_provider.dart";
import "../../core/auth/role_guard.dart";
import "../theme/gambit_theme.dart";

// ── GButton ───────────────────────────────────────────────────────────────────
class GButton extends StatelessWidget {

  const GButton({
    required this.label, super.key,
    this.onPressed,
    this.icon,
    this.color,
    this.outline = false,
    this.loading = false,
    this.fullWidth = false,
    this.small = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool outline;
  final bool loading;
  final bool fullWidth;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = color ?? GambitColors.accent;

    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: outline
                  ? c
                  : (c == GambitColors.accent
                        ? const Color(0xFF070400)
                        : Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: small ? 14 : 16),
                const SizedBox(width: 6),
              ],
              Text(label),
            ],
          );

    final vPad = small ? 10.0 : 14.0;
    final hPad = small ? 14.0 : 20.0;

    final style = outline
        ? OutlinedButton.styleFrom(
            foregroundColor: c,
            side: BorderSide(color: c),
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
            textStyle: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: small ? 11 : 13,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: c,
            foregroundColor: c == GambitColors.accent
                ? const Color(0xFF070400)
                : Colors.white,
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
            textStyle: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: small ? 11 : 13,
            ),
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          );

    final btn = outline
        ? OutlinedButton(
            onPressed: loading ? null : onPressed,
            style: style,
            child: child,
          )
        : ElevatedButton(
            onPressed: loading ? null : onPressed,
            style: style,
            child: child,
          );

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

// ── GCard ─────────────────────────────────────────────────────────────────────
class GCard extends StatelessWidget { // for tappable cards

  const GCard({
    required this.child, super.key,
    this.padding,
    this.borderColor,
    this.onTap,
    this.semanticLabel,
  });
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GambitColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? GambitColors.border,
          width: 1.5,
        ),
      ),
      child: child,
    );

    if (onTap == null) return container;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: container,
      ),
    );
  }
}

// ── GBadge ────────────────────────────────────────────────────────────────────
class GBadge extends StatelessWidget {

  const GBadge({required this.label, required this.color, super.key});
  final String label;
  final Color color;

  static Color colorForStatus(String status) {
    switch (status.toLowerCase()) {
      case "active":
      case "valid":
      case "paid":
      case "available":
      case "completed":
        return GambitColors.success;
      case "warned":
      case "expiring":
      case "pending":
      case "in_transit":
        return GambitColors.warn;
      case "banned":
      case "expired":
      case "unpaid":
      case "maintenance":
      case "cancelled":
        return GambitColors.danger;
      case "on_trip":
      case "active_trip":
        return GambitColors.blue;
      default:
        return GambitColors.textSub;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: .8,
          ),
        ),
      ),
    );
  }
}

// ── GChip ─────────────────────────────────────────────────────────────────────
class GChip extends StatelessWidget {

  const GChip({required this.icon, required this.label, super.key, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? GambitColors.textSub;
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c, semanticLabel: ""),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: c, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── GStatCard ─────────────────────────────────────────────────────────────────
class GStatCard extends StatelessWidget {

  const GStatCard({
    required this.icon, required this.label, required this.value, super.key,
    this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? GambitColors.accent;
    return Expanded(
      child: Semantics(
        label: "$label: $value",
        child: GCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: c.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: c, semanticLabel: ""),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: c,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: GambitColors.textMuted,
                  letterSpacing: .5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── GAlert ────────────────────────────────────────────────────────────────────
class GAlert extends StatelessWidget { // danger | warn | info | success

  const GAlert({
    required this.message, super.key,
    this.sub,
    this.type = "info",
  });
  final String message;
  final String? sub;
  final String type;

  @override
  Widget build(BuildContext context) {
    final cfg = {
      "danger": (GambitColors.danger, Icons.error_rounded),
      "warn": (GambitColors.warn, Icons.warning_rounded),
      "info": (GambitColors.blue, Icons.info_rounded),
      "success": (GambitColors.success, Icons.check_circle_rounded),
    };
    final (color, icon) = cfg[type] ?? (GambitColors.blue, Icons.info_rounded);

    return Semantics(
      liveRegion: type == "danger",
      label: sub != null ? "$message. $sub" : message,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color, semanticLabel: ""),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub!,
                      style: const TextStyle(
                        color: GambitColors.textSub,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── GInput ────────────────────────────────────────────────────────────────────
class GInput extends StatelessWidget {

  const GInput({
    required this.label, super.key,
    this.hint,
    this.controller,
    this.focusNode,
    this.obscure = false,
    this.prefixIcon,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscure;
  final IconData? prefixIcon;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: GambitColors.text, fontSize: 13),
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          hintText: hint,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, semanticLabel: "")
              : null,
          errorText: errorText,
        ),
      ),
    );
  }
}

// ── RoleGate ──────────────────────────────────────────────────────────────────
class RoleGate extends StatelessWidget {

  const RoleGate({
    required this.minRole, required this.child, super.key,
    this.fallback,
  });
  final String minRole;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.claims == null) return fallback ?? const SizedBox.shrink();
    return RoleGuard.hasRole(auth.claims!.role, minRole)
        ? child
        : (fallback ?? const SizedBox.shrink());
  }
}

// ── AppShell ──────────────────────────────────────────────────────────────────
class AppShell extends StatelessWidget {

  const AppShell({
    required this.destinations, required this.currentIndex, required this.onDestinationSelected, required this.body, required this.title, super.key,
  });
  final List<ShellDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final String title;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _SideNav(
              destinations: destinations,
              currentIndex: currentIndex,
              onSelected: onDestinationSelected,
              title: title,
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        backgroundColor: GambitColors.surface,
        indicatorColor: GambitColors.accentDim,
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: destinations
            .take(5)
            .map(
              (d) => NavigationDestination(
                icon: Icon(
                  d.icon,
                  color: GambitColors.textMuted,
                  semanticLabel: d.label,
                ),
                selectedIcon: Icon(
                  d.icon,
                  color: GambitColors.accent,
                  semanticLabel: d.label,
                ),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class ShellDestination {

  const ShellDestination({
    required this.label,
    required this.icon,
    required this.screen,
  });
  final String label;
  final IconData icon;
  final Widget screen;
}

class _SideNav extends StatelessWidget {

  const _SideNav({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    required this.title,
  });
  final List<ShellDestination> destinations;
  final int currentIndex;
  final void Function(int) onSelected;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Container(
        color: GambitColors.bg,
        child: Column(
          children: [
            // Brand
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: GambitColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: GambitColors.accentDim,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: GambitColors.accent.withAlpha(50),
                      ),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      size: 16,
                      color: GambitColors.accent,
                      semanticLabel: "",
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "GAMBIT",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: GambitColors.accent,
                        ),
                      ),
                      Text(
                        "TSL",
                        style: TextStyle(
                          fontSize: 8,
                          color: GambitColors.textMuted,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Nav items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: destinations.length,
                itemBuilder: (_, i) {
                  final selected = i == currentIndex;
                  return Semantics(
                    selected: selected,
                    button: true,
                    label: destinations[i].label,
                    child: InkWell(
                      onTap: () => onSelected(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? GambitColors.accentDim
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: selected
                                  ? GambitColors.accent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              destinations[i].icon,
                              size: 16,
                              color: selected
                                  ? GambitColors.accent
                                  : GambitColors.textMuted,
                              semanticLabel: "",
                            ),
                            const SizedBox(width: 10),
                            Text(
                              destinations[i].label,
                              style: TextStyle(
                                color: selected
                                    ? GambitColors.accent
                                    : GambitColors.textSub,
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // User footer
            Consumer<AuthProvider>(
              builder: (_, auth, _) => Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: GambitColors.border)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: GambitColors.elevated,
                      child: Icon(
                        Icons.person,
                        size: 14,
                        color: GambitColors.textSub,
                        semanticLabel: "",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.username,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: GambitColors.text,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            auth.role.replaceAll("_", " "),
                            style: const TextStyle(
                              fontSize: 9,
                              color: GambitColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── GChangePasswordBanner ──────────────────────────────────────────────────────
/// Banner displayed when user must change their password.
/// Intended for display at the top of dashboard screens.
class GChangePasswordBanner extends StatefulWidget {
  const GChangePasswordBanner({super.key});

  @override
  State<GChangePasswordBanner> createState() => _GChangePasswordBannerState();
}

class _GChangePasswordBannerState extends State<GChangePasswordBanner> {
  bool _loading = false;

  Future<void> _changePassword() async {
    setState(() => _loading = true);
    try {
      // Open change password modal
      if (!mounted) return;
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _ChangePasswordDialog(),
      );
      if (result == true && mounted) {
        // Password changed — banner will auto-dismiss when mustChangePw becomes false
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password updated"),
            backgroundColor: GambitColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.mustChangePw) return const SizedBox.shrink();

    return Container(
      color: GambitColors.danger.withAlpha(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.warning_rounded,
            color: GambitColors.danger,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Change Password Required",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: GambitColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Please set a new password for your account",
                  style: TextStyle(
                    fontSize: 11,
                    color: GambitColors.textSub.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GButton(
            label: "Change",
            icon: Icons.key_rounded,
            small: true,
            loading: _loading,
            onPressed: _changePassword,
          ),
        ],
      ),
    );
  }
}

// ── _ChangePasswordDialog ──────────────────────────────────────────────────────
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPass = _oldCtrl.text;
    final newPass = _newCtrl.text;
    final conf = _confCtrl.text;

    if (oldPass.isEmpty || newPass.isEmpty || conf.isEmpty) {
      setState(() => _error = "Fill in all fields");
      return;
    }
    if (newPass != conf) {
      setState(() => _error = "Passwords do not match");
      return;
    }
    if (newPass.length < 8) {
      setState(() => _error = "Password must be at least 8 characters");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthApi.changePassword(oldPassword: oldPass, newPassword: newPass);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: GambitColors.surface,
      title: const Text("Change Password"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GambitColors.danger.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GambitColors.danger.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_rounded,
                      color: GambitColors.danger,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: GambitColors.danger,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _oldCtrl,
              obscureText: true,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: "Current Password",
                prefixIcon: Icon(Icons.lock_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newCtrl,
              obscureText: true,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: "New Password",
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confCtrl,
              obscureText: true,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: "Confirm Password",
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        GButton(
          label: "Update",
          icon: Icons.check_rounded,
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
