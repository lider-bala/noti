import 'package:flutter/material.dart';

import '../app/app_state.dart';
import 'app_theme.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool light;

  const ThemeToggleButton({
    super.key,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final isDark = appState.themeMode == ThemeMode.dark ||
        (appState.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final color = light ? Colors.white : context.primaryTextColor;
    final background =
        light ? Colors.white.withOpacity(0.18) : context.panelMutedColor;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        appState.setThemePreference(
          isDark ? AppThemePreference.light : AppThemePreference.dark,
        );
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                light ? Colors.white.withOpacity(0.24) : context.appBorderColor,
          ),
        ),
        child: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          size: 20,
          color: color,
        ),
      ),
    );
  }
}
