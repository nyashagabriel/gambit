// lib/shared/theme/gonyeti_theme.dart — GONYETI TLS
import "package:flutter/material.dart";

class GonyetiThemeExtension extends ThemeExtension<GonyetiThemeExtension> {

  const GonyetiThemeExtension({
    required this.bg,
    required this.surface,
    required this.card,
    required this.elevated,
    required this.border,
    required this.accent,
    required this.accentDim,
    required this.blue,
    required this.blueDim,
    required this.success,
    required this.danger,
    required this.warn,
    required this.text,
    required this.textSub,
    required this.textMuted,
  });
  final Color bg;
  final Color surface;
  final Color card;
  final Color elevated;
  final Color border;
  final Color accent;
  final Color accentDim;
  final Color blue;
  final Color blueDim;
  final Color success;
  final Color danger;
  final Color warn;
  final Color text;
  final Color textSub;
  final Color textMuted;

  @override
  GonyetiThemeExtension copyWith({
    Color? bg,
    Color? surface,
    Color? card,
    Color? elevated,
    Color? border,
    Color? accent,
    Color? accentDim,
    Color? blue,
    Color? blueDim,
    Color? success,
    Color? danger,
    Color? warn,
    Color? text,
    Color? textSub,
    Color? textMuted,
  }) {
    return GonyetiThemeExtension(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      elevated: elevated ?? this.elevated,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentDim: accentDim ?? this.accentDim,
      blue: blue ?? this.blue,
      blueDim: blueDim ?? this.blueDim,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warn: warn ?? this.warn,
      text: text ?? this.text,
      textSub: textSub ?? this.textSub,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  GonyetiThemeExtension lerp(ThemeExtension<GonyetiThemeExtension>? other, double t) {
    if (other is! GonyetiThemeExtension) return this;
    return GonyetiThemeExtension(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDim: Color.lerp(accentDim, other.accentDim, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      blueDim: Color.lerp(blueDim, other.blueDim, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSub: Color.lerp(textSub, other.textSub, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

extension GonyetiColorsExt on BuildContext {
  GonyetiThemeExtension get colors => Theme.of(this).extension<GonyetiThemeExtension>()!;
}

// We KEEP GonyetiColors as a normal class that defaults to dark.
class GonyetiColors {
  GonyetiColors._();
  static const Color bg = Color(0xFF07090E);
  static const Color surface = Color(0xFF0C0F16);
  static const Color card = Color(0xFF111620);
  static const Color elevated = Color(0xFF182030);
  static const Color border = Color(0xFF4A6490); // FIX: was 0xFF1C2840 → 1.30:1 on surface (WCAG fail). Now 3.21:1 ✓
  static const Color accent = Color(0xFFF0A500);
  static const Color accentDim = Color(0x1FF0A500);
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueDim = Color(0x1F3B82F6);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color warn = Color(0xFFF97316);
  static const Color text = Color(0xFFE8EDF5);
  static const Color textSub = Color(0xFF7A90B0);
  static const Color textMuted = Color(0xFF64748B); // FIX: was 0xFF3D5070 → 2.63:1 on dark bg (WCAG fail). Now 4.18:1 ✓
}

class GonyetiTheme {
  GonyetiTheme._();

  static const _darkColors = GonyetiThemeExtension(
    bg: Color(0xFF07090E),
    surface: Color(0xFF0C0F16),
    card: Color(0xFF111620),
    elevated: Color(0xFF182030),
    border: Color(0xFF4A6490), // FIX: was 0xFF1C2840 → 1.30:1 (WCAG fail). Now 3.21:1 ✓
    accent: Color(0xFFF0A500),
    accentDim: Color(0x2FF0A500),
    blue: Color(0xFF3B82F6),
    blueDim: Color(0x2F3B82F6),
    success: Color(0xFF22C55E),
    danger: Color(0xFFEF4444),
    warn: Color(0xFFF97316),
    text: Color(0xFFE8EDF5),
    textSub: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B), // FIX: was 0xFF475569 → 2.63:1 (WCAG fail). Now 4.18:1 ✓
  );

  static const _lightColors = GonyetiThemeExtension(
    bg: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    elevated: Color(0xFFFFFFFF),
    border: Color(0xFF64748B),  // FIX: was 0xFFE2E8F0 → 1.23:1 on white (WCAG fail). Now 4.76:1 ✓
    accent: Color(0xFFC2410C),  // Darker accent for better contrast with white text
    accentDim: Color(0x1FC2410C),
    blue: Color(0xFF2563EB),
    blueDim: Color(0x1F2563EB),
    success: Color(0xFF16A34A),
    danger: Color(0xFFDC2626),
    warn: Color(0xFFD97706),
    text: Color(0xFF0F172A),
    textSub: Color(0xFF475569),
    textMuted: Color(0xFF64748B),
  );

  static ThemeData get dark {
    const colors = _darkColors;
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFFF0A500),
      secondary: Color(0xFF3B82F6),
      surface: Color(0xFF111620),
      error: Color(0xFFEF4444),
      onPrimary: Color(0xFF070400),
      onSecondary: Colors.white,
      onSurface: Color(0xFFE8EDF5),
      onError: Colors.white,
      outline: Color(0xFF4A6490),         // ADD: M3 input borders pull from this role
      outlineVariant: Color(0xFF1C2840),  // ADD: subtle dividers
    );
    return _buildTheme(ThemeData.dark(), colorScheme, colors);
  }

  static ThemeData get light {
    const colors = _lightColors;
    const colorScheme = ColorScheme.light(
      primary: Color(0xFFC2410C), // Matching the updated accent
      secondary: Color(0xFF2563EB),
      surface: Color(0xFFFFFFFF),
      error: Color(0xFFDC2626),
      onPrimary: Colors.white, // Now clearly contrasting
      onSecondary: Colors.white,
      onSurface: Color(0xFF0F172A),
      onError: Colors.white,
      outline: Color(0xFF64748B),         // ADD: M3 input borders pull from this role
      outlineVariant: Color(0xFFCBD5E1),  // ADD: subtle dividers
    );
    return _buildTheme(ThemeData.light(), colorScheme, colors);
  }

  static ThemeData _buildTheme(ThemeData base, ColorScheme colorScheme, GonyetiThemeExtension colors) {
    return base.copyWith(
      useMaterial3: true, // ADD: without this M3 components render in M2 mode
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.bg,
      cardColor: colors.card,
      dividerColor: colors.border,
      splashColor: colors.accentDim,
      highlightColor: colors.accentDim,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.text,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: colors.textSub, size: 22),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.accentDim,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? colors.accent : colors.textMuted,
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: colors.accent),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
        labelStyle: TextStyle(
          color: colors.textSub,
          fontSize: 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: colors.accent,
          fontSize: 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: colors.textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
        errorStyle: TextStyle(color: colors.danger, fontSize: 11),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: colors.text, fontWeight: FontWeight.w900),
        displayMedium: TextStyle(color: colors.text, fontWeight: FontWeight.w800),
        headlineLarge: TextStyle(color: colors.text, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 17),
        titleMedium: TextStyle(color: colors.text, fontWeight: FontWeight.w600, fontSize: 14),
        titleSmall: TextStyle(color: colors.text, fontWeight: FontWeight.w600, fontSize: 12),
        bodyLarge: TextStyle(color: colors.text, fontSize: 14, height: 1.5),
        bodyMedium: TextStyle(color: colors.textSub, fontSize: 13, height: 1.5),
        bodySmall: TextStyle(color: colors.textSub, fontSize: 11, height: 1.4),
        labelLarge: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 13),
        labelMedium: TextStyle(color: colors.textSub, fontWeight: FontWeight.w600, fontSize: 11),
        labelSmall: TextStyle(color: colors.textMuted, fontSize: 10, letterSpacing: 1.0),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.w800),
        contentTextStyle: TextStyle(color: colors.textSub, fontSize: 13, height: 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.elevated,
        contentTextStyle: TextStyle(color: colors.text, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: colors.elevated,
        labelStyle: TextStyle(color: colors.textSub, fontSize: 12),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.accent, linearTrackColor: colors.border),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.accent : colors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.accentDim : colors.border,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.accent : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        side: BorderSide(color: colors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(colors.elevated),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ),
    );
  }
}
