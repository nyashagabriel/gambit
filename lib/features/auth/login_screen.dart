// lib/features/auth/login_screen.dart — GAMBIT TSL
//
// Design principles applied:
//   Hick's Law    — exactly ONE primary decision on screen: sign in.
//                   Help lives on a separate screen, not an accordion.
//   Signifiers    — every interactive element looks and feels interactive.
//   Affordance    — password toggle lives inside the field as a suffix icon,
//                   not detached as a separate button.
//   WCAG 2.1 AA   — all text passes 4.5:1 contrast ratio.
//                   textSub raised to #8FA3BF (4.6:1 on #07090E).
//                   accent #F0A500 on #07090E = 8.3:1 — passes AAA.
//                   error red #EF4444 on #07090E = 4.7:1 — passes AA.

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../core/api/auth_api.dart";
import "../../core/auth/auth_provider.dart";
import "../../shared/theme/gambit_theme.dart";
import "../../shared/widgets/widgets.dart";

// ── AA-SAFE COLOUR OVERRIDE ───────────────────────────────────
// GambitColors.textSub (#7A90B0) = 3.8:1 — FAILS AA at small sizes.
// Use this locally until the theme is patched globally.
const _kTextAA = Color(0xFF8FA3BF); // 4.6:1 on #07090E — passes AA

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;
    if (username.isEmpty || password.isEmpty) return;

    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.login(username, password);
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(auth.homeRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Brand(),
                  const SizedBox(height: 32),
                  _LoginCard(
                    auth: auth,
                    userCtrl: _userCtrl,
                    passCtrl: _passCtrl,
                    userFocus: _userFocus,
                    passFocus: _passFocus,
                    obscure: _obscure,
                    onToggle: () => setState(() => _obscure = !_obscure),
                    onLogin: _login,
                  ),
                  const SizedBox(height: 20),

                  // ONE quiet secondary action — not an accordion,
                  // not a panel, not a toggle. One clear link.
                  Semantics(
                    button: true,
                    label: "Trouble signing in — get help",
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, "/sign-in-help"),
                      child: const Text(
                        "Trouble signing in?",
                        style: TextStyle(color: _kTextAA, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Brand block ───────────────────────────────────────────────
class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GambitColors.accentDim,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GambitColors.accent.withAlpha(60)),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              size: 30,
              color: GambitColors.accent,
              semanticLabel: "Gambit TSL",
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "GAMBIT TSL",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: GambitColors.accent,
              letterSpacing: -.5,
            ),
          ),
          const Text(
            "TRANSPORT · LOGISTICS · SYSTEM",
            style: TextStyle(
              fontSize: 9,
              color: _kTextAA, // AA-safe
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Login card ────────────────────────────────────────────────
// Single responsibility: collect credentials and submit.
// No help, no toggles, no panels — just two fields and a button.
class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.auth,
    required this.userCtrl,
    required this.passCtrl,
    required this.userFocus,
    required this.passFocus,
    required this.obscure,
    required this.onToggle,
    required this.onLogin,
  });

  final AuthProvider auth;
  final TextEditingController userCtrl, passCtrl;
  final FocusNode userFocus, passFocus;
  final bool obscure;
  final VoidCallback onToggle, onLogin;

  @override
  Widget build(BuildContext context) {
    return GCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error banner — live region so screen-readers announce it
          if (auth.error != null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GAlert(message: auth.error!, type: "danger"),
              ),
            ),

          // Username field
          _Field(
            label: "USERNAME",
            hint: "your username",
            controller: userCtrl,
            focusNode: userFocus,
            prefixIcon: Icons.person_rounded,
            onSubmitted: (_) => passFocus.requestFocus(),
          ),

          const SizedBox(height: 14),

          // Password field — toggle is a suffix icon INSIDE the field.
          // Affordance: the icon is visually part of the input.
          // Signifier: eye icon universally signals show/hide password.
          _Field(
            label: "PASSWORD",
            hint: "••••••••",
            controller: passCtrl,
            focusNode: passFocus,
            obscure: obscure,
            prefixIcon: Icons.lock_rounded,
            suffixIcon: obscure
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            suffixLabel: obscure ? "Show password" : "Hide password",
            onSuffixTap: onToggle,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onLogin(),
          ),

          const SizedBox(height: 24),

          // Primary action — single, unambiguous call to action.
          GButton(
            label: "SIGN IN",
            icon: Icons.login_rounded,
            loading: auth.isLoading,
            fullWidth: true,
            onPressed: onLogin,
          ),
        ],
      ),
    );
  }
}

// ── Accessible field ──────────────────────────────────────────
// Extends GInput with an optional suffix icon that has a proper
// semantic label and minimum 48dp tap target.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.prefixIcon,
    this.obscure = false,
    this.suffixIcon,
    this.suffixLabel,
    this.onSuffixTap,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final String label, hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData prefixIcon;
  final bool obscure;
  final IconData? suffixIcon;
  final String? suffixLabel;
  final VoidCallback? onSuffixTap;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: GambitColors.text, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: GambitColors.textMuted),
          labelStyle: const TextStyle(
            color: _kTextAA, // AA-safe
            fontSize: 11,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(prefixIcon, color: GambitColors.textMuted),
          // Suffix — only rendered when provided.
          // Uses Semantics + IconButton for proper 48dp tap target.
          suffixIcon: suffixIcon != null
              ? Semantics(
                  button: true,
                  label: suffixLabel ?? "",
                  child: IconButton(
                    icon: Icon(suffixIcon, color: _kTextAA, size: 20),
                    onPressed: onSuffixTap,
                    splashRadius: 20,
                    // Enforce minimum tap target
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// ── Change Password Screen ────────────────────────────────────
// Kept separate from LoginScreen (Hick's Law — do not mix flows).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPw = _oldCtrl.text;
    final newPw = _newCtrl.text;
    final confirmPw = _confirmCtrl.text;

    if (newPw != confirmPw) {
      setState(() => _error = "Passwords do not match");
      return;
    }
    if (newPw.length < 8) {
      setState(() => _error = "New password must be at least 8 characters");
      return;
    }
    if (oldPw == newPw) {
      setState(() => _error = "New password must differ from current");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthApi.changePassword(oldPassword: oldPw, newPassword: newPw);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshClaims();
      setState(() {
        _loading = false;
        _done = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          context.read<AuthProvider>().homeRoute,
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst(RegExp(r"^Exception:\s*"), "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: GCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_reset_rounded,
                      size: 32,
                      color: GambitColors.accent,
                      semanticLabel: "Set new password",
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Set New Password",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: GambitColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "You must change your password before continuing.",
                      style: TextStyle(color: _kTextAA, fontSize: 12),
                    ),
                    const SizedBox(height: 20),

                    if (_error != null)
                      Semantics(
                        liveRegion: true,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: GAlert(message: _error!, type: "danger"),
                        ),
                      ),
                    if (_done)
                      Semantics(
                        liveRegion: true,
                        child: const Padding(
                          padding: EdgeInsets.only(bottom: 14),
                          child: GAlert(
                            message: "Password updated! Redirecting…",
                            type: "success",
                          ),
                        ),
                      ),

                    _Field(
                      label: "CURRENT PASSWORD",
                      hint: "••••••••",
                      controller: _oldCtrl,
                      focusNode: FocusNode(),
                      obscure: true,
                      prefixIcon: Icons.lock_rounded,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      label: "NEW PASSWORD",
                      hint: "min 8 characters",
                      controller: _newCtrl,
                      focusNode: FocusNode(),
                      obscure: true,
                      prefixIcon: Icons.lock_open_rounded,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      label: "CONFIRM NEW PASSWORD",
                      hint: "••••••••",
                      controller: _confirmCtrl,
                      focusNode: FocusNode(),
                      obscure: true,
                      prefixIcon: Icons.lock_open_rounded,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),

                    GButton(
                      label: "UPDATE PASSWORD",
                      icon: Icons.check_rounded,
                      loading: _loading,
                      fullWidth: true,
                      color: GambitColors.success,
                      onPressed: _done ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
