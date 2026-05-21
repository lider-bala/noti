import 'package:flutter/material.dart';

extension AppThemeColors on BuildContext {
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  // ── backgrounds ──
  Color get shellBackground =>
      isDarkTheme ? const Color(0xFF111827) : const Color(0xFFF9FAFB);

  Color get topBarColor =>
      isDarkTheme ? const Color(0xF21E293B) : Colors.white.withOpacity(0.94);

  Color get panelColor => isDarkTheme ? const Color(0xFF1E293B) : Colors.white;

  Color get panelMutedColor =>
      isDarkTheme ? const Color(0xFF334155) : const Color(0xFFF9FAFB);

  Color get cardColor => isDarkTheme ? const Color(0xFF1E293B) : Colors.white;

  // ── borders ──
  Color get appBorderColor =>
      isDarkTheme ? const Color(0xFF475569) : const Color(0xFFE5E7EB);

  // ── text colors ──
  Color get primaryTextColor =>
      isDarkTheme ? const Color(0xFFF8FAFC) : const Color(0xFF111827);

  Color get secondaryTextColor =>
      isDarkTheme ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280);

  Color get tertiaryTextColor =>
      isDarkTheme ? const Color(0xFF94A3B8) : const Color(0xFF4B5563);

  Color get mutedTextColor =>
      isDarkTheme ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF);

  // ── tinted backgrounds ──
  Color get blueTintBg =>
      isDarkTheme ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF);

  Color get blueTintFg =>
      isDarkTheme ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);

  Color get greenTintBg =>
      isDarkTheme ? const Color(0xFF14532D) : const Color(0xFFF0FDF4);

  Color get greenTintFg =>
      isDarkTheme ? const Color(0xFF6EE7B7) : const Color(0xFF059669);

  Color get redTintBg =>
      isDarkTheme ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);

  Color get redTintFg =>
      isDarkTheme ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);

  Color get orangeTintBg =>
      isDarkTheme ? const Color(0xFF78350F) : const Color(0xFFFFFBEB);

  Color get orangeTintFg =>
      isDarkTheme ? const Color(0xFFFBBF24) : const Color(0xFFEA580C);

  Color get cyanTintBg =>
      isDarkTheme ? const Color(0xFF164E63) : const Color(0xFFECFEFF);

  // ── avatars / chips ──
  Color get avatarBg =>
      isDarkTheme ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE);

  Color get avatarFg =>
      isDarkTheme ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);

  Color get chipSelectedBg =>
      isDarkTheme ? const Color(0xFF1E40AF) : const Color(0xFF2563EB);

  Color get chipUnselectedBg =>
      isDarkTheme ? const Color(0xFF334155) : const Color(0xFFEFF6FF);

  Color get chipUnselectedFg =>
      isDarkTheme ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);

  // ── activity card backgrounds ──
  Color get activityGreenBg =>
      isDarkTheme ? const Color(0xFF14532D) : const Color(0xFFDCFCE7);

  Color get activityBlueBg =>
      isDarkTheme ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE);

  Color get activityOrangeBg =>
      isDarkTheme ? const Color(0xFF78350F) : const Color(0xFFFFEDD5);

  // ── input / search ──
  Color get inputBg =>
      isDarkTheme ? const Color(0xFF1E293B) : Colors.white;

  Color get searchBg =>
      isDarkTheme ? const Color(0xFF334155) : const Color(0xFFF3F4F6);

  // ── snackbar ──
  Color get successSnackBg =>
      isDarkTheme ? const Color(0xFF065F46) : const Color(0xFF047857);

  Color get errorSnackBg =>
      isDarkTheme ? const Color(0xFF991B1B) : const Color(0xFFB91C1C);

  // ── tab bar ──
  Color get tabLabelColor =>
      isDarkTheme ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);

  Color get tabUnselectedColor =>
      isDarkTheme ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

  // ── grade chip colors ──
  Color gradeChipBg(int grade, bool selected) {
    if (selected) {
      switch (grade) {
        case 5: return const Color(0xFF059669);
        case 4: return const Color(0xFF2563EB);
        case 3: return isDarkTheme ? const Color(0xFFB45309) : const Color(0xFFF59E0B);
        default: return isDarkTheme ? const Color(0xFF991B1B) : const Color(0xFFEF4444);
      }
    }
    return isDarkTheme ? const Color(0xFF334155) : const Color(0xFFF3F4F6);
  }

  Color gradeChipFg(int grade, bool selected) {
    if (selected) return Colors.white;
    return isDarkTheme ? const Color(0xFFCBD5E1) : const Color(0xFF374151);
  }

  // ── section header subtitle ──
  Color get sectionSubtitleColor =>
      isDarkTheme ? const Color(0xFFCBD5E1) : Colors.white.withOpacity(0.9);

  // ── status colors ──
  Color get presentColor =>
      isDarkTheme ? const Color(0xFF6EE7B7) : const Color(0xFF10B981);

  Color get lateColor =>
      isDarkTheme ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);

  Color get absentColor =>
      isDarkTheme ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444);
}
