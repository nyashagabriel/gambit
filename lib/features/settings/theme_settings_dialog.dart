import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme_provider.dart';
import '../../shared/theme/gonyeti_theme.dart';

class ThemeSettingsDialog extends StatelessWidget {
  const ThemeSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentMode = themeProvider.themeMode;
    final colors = context.colors;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Appearance",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Select your preferred app theme.",
              style: TextStyle(
                fontSize: 13,
                color: colors.textSub,
              ),
            ),
            const SizedBox(height: 24),
            _ThemeOptionTile(
              title: "System Default",
              icon: Icons.brightness_auto,
              isSelected: currentMode == ThemeMode.system,
              onTap: () => themeProvider.setThemeMode(ThemeMode.system),
            ),
            const SizedBox(height: 12),
            _ThemeOptionTile(
              title: "Light Theme",
              icon: Icons.light_mode,
              isSelected: currentMode == ThemeMode.light,
              onTap: () => themeProvider.setThemeMode(ThemeMode.light),
            ),
            const SizedBox(height: 12),
            _ThemeOptionTile(
              title: "Dark Theme",
              icon: Icons.dark_mode,
              isSelected: currentMode == ThemeMode.dark,
              onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("CLOSE"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? colors.accent : colors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? colors.accentDim : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colors.accent : colors.textSub,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? colors.text : colors.textSub,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colors.accent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
