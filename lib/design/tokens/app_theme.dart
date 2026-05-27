import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'nova_colors.dart';

/// The application [ThemeData], rebuilt entirely from design tokens.
///
/// Two variants are exposed — [light] and [dark] — each registering the
/// matching [NovaColors] theme extension. Brand accents (lime, semantic
/// colours) stay constant; only neutral surfaces / text / borders flip.
class AppTheme {
  const AppTheme._();

  /// The light theme — the app's original look.
  static ThemeData get light => _build(
        brightness: Brightness.light,
        novaColors: NovaColors.light,
      );

  /// The dark theme — deep neutral surfaces, brand accents preserved.
  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        novaColors: NovaColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required NovaColors novaColors,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = AppTypography.themed(novaColors.textPrimary);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.lime,
      brightness: brightness,
      primary: AppColors.lime,
      onPrimary: AppColors.ink,
      secondary: AppColors.deepInk,
      surface: novaColors.surface,
      onSurface: novaColors.textPrimary,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: novaColors.background,
      canvasColor: novaColors.background,
      dividerColor: novaColors.border,
      iconTheme: IconThemeData(color: novaColors.textPrimary),
      textTheme: textTheme,
      extensions: [novaColors],
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: novaColors.textPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: novaColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      dividerTheme: DividerThemeData(color: novaColors.border),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.deepInk,
        contentTextStyle: TextStyle(color: AppColors.surface),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.ink
              : (isDark ? AppColors.darkTextSecondary : null),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.lime
              : (isDark ? AppColors.darkSurfaceMuted : null),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: novaColors.surface,
        hintStyle: TextStyle(color: novaColors.textSecondary),
        prefixIconColor: novaColors.textSecondary,
        suffixIconColor: novaColors.textSecondary,
        helperStyle: TextStyle(color: novaColors.textSecondary),
        labelStyle: TextStyle(color: novaColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.lime : AppColors.deepInk,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
