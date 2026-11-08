import 'package:flutter/material.dart';

/// All the colours of the app in one place.
class AppColors {
  static const Color primary = Color(0xFF5B34B8);
  static const Color primaryDark = Color(0xFF3B1E80);
  static const Color primarySoft = Color(0xFFE9E2FB);
  static const Color background = Color(0xFFF5F2FF);
  static const Color textDark = Color(0xFF1F1A33);
  static const Color textMuted = Color(0xFF6E6A80);
  static const Color success = Color(0xFF2EAD6D);
  static const Color danger = Color(0xFFE5484D);
}

/// The light and dark theme of the app.
class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDark,
      surface: Colors.white,
      onSurface: AppColors.textDark,
      onSurfaceVariant: AppColors.textMuted,
      error: AppColors.danger,
    );
    return _build(scheme, AppColors.background);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );
    return _build(scheme, const Color(0xFF14111F));
  }

  static ThemeData _build(ColorScheme scheme, Color background) {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: buttonShape,
        ),
      ),
    );
  }
}
