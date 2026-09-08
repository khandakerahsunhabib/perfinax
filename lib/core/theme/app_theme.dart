import 'package:flutter/material.dart';

class AppTheme {
  // Dark Theme - Exact match for the app's current dark design
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF030A08),
      cardColor: const Color(0xFF0A221C),
      primaryColor: const Color(0xFF10B981),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF0A221C),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF10B981),
        surface: Color(0xFF0A221C),
        secondary: Color(0xFF14B8A6),
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF030A08),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF030A08),
        selectedItemColor: Color(0xFF10B981),
        unselectedItemColor: Color(0xFF64748B),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF0A221C),
      ),
    );
  }

  // Light Theme - Crisp light design aligned with emerald identity
  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      cardColor: const Color(0xFFFFFFFF),
      primaryColor: const Color(0xFF059669),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFFFFFFFF),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF059669),
        surface: Color(0xFFFFFFFF),
        secondary: Color(0xFF0D9488),
        onSurface: Color(0xFF0F172A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF1F5F9),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: Color(0xFF059669),
        unselectedItemColor: Color(0xFF64748B),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFFFF),
      ),
    );
  }

  // Theme-aware helper methods
  static Color getScaffoldBg(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color getCardBg(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getTextSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  }

  static Color getSubtleBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF10B981).withValues(alpha: 0.2)
        : const Color(0xFFE2E8F0);
  }

  static Color getModalInputBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF030A08) : const Color(0xFFF8FAFC);
  }
}
