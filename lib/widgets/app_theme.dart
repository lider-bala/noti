import 'package:flutter/material.dart';

extension AppThemeColors on BuildContext {
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  Color get shellBackground =>
      isDarkTheme ? const Color(0xFF111827) : const Color(0xFFF9FAFB);

  Color get topBarColor =>
      isDarkTheme ? const Color(0xF21E293B) : Colors.white.withOpacity(0.94);

  Color get panelColor => isDarkTheme ? const Color(0xFF1E293B) : Colors.white;

  Color get panelMutedColor =>
      isDarkTheme ? const Color(0xFF334155) : const Color(0xFFF9FAFB);

  Color get appBorderColor =>
      isDarkTheme ? const Color(0xFF475569) : const Color(0xFFE5E7EB);

  Color get primaryTextColor =>
      isDarkTheme ? const Color(0xFFF8FAFC) : const Color(0xFF111827);

  Color get secondaryTextColor =>
      isDarkTheme ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280);
}
