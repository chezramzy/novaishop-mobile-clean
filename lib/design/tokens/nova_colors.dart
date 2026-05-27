import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A [ThemeExtension] holding every *mode-dependent* neutral colour of the
/// design system.
///
/// Brand accents (lime, semantic colours) live in [AppColors] and never
/// change. The neutrals here — backgrounds, surfaces, text, borders and the
/// pastel tints — flip between [light] and [dark].
///
/// Read it from a [BuildContext] with the [BuildContextNovaColors.colors]
/// getter, e.g. `context.colors.surface`.
@immutable
class NovaColors extends ThemeExtension<NovaColors> {
  const NovaColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.scaffoldGradient,
    required this.lavender,
    required this.blush,
    required this.butter,
    required this.shadow,
    required this.isDark,
  });

  /// The app background tint.
  final Color background;

  /// Raised surface — cards, sheets, inputs.
  final Color surface;

  /// A slightly recessed / muted surface (chips, soft fills).
  final Color surfaceMuted;

  /// Primary text colour.
  final Color textPrimary;

  /// Secondary / muted text colour.
  final Color textSecondary;

  /// Hairline border colour.
  final Color border;

  /// The [SoftGradientScaffold] background gradient.
  final LinearGradient scaffoldGradient;

  /// Tinted-card colour — soft purple. Kept legible in dark mode.
  final Color lavender;

  /// Tinted-card colour — soft pink. Kept legible in dark mode.
  final Color blush;

  /// Tinted-card colour — soft yellow. Kept legible in dark mode.
  final Color butter;

  /// Shadow colour for elevated surfaces.
  final Color shadow;

  /// Whether this instance is the dark variant.
  final bool isDark;

  /// The light-mode neutrals — the app's original look.
  static const light = NovaColors(
    background: AppColors.mist,
    surface: AppColors.surface,
    surfaceMuted: AppColors.mist,
    textPrimary: AppColors.ink,
    textSecondary: AppColors.muted,
    border: AppColors.border,
    scaffoldGradient: AppColors.softGradient,
    lavender: AppColors.lavender,
    blush: AppColors.blush,
    butter: AppColors.butter,
    shadow: AppColors.deepInk,
    isDark: false,
  );

  /// The dark-mode neutrals.
  static const dark = NovaColors(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceMuted: AppColors.darkSurfaceMuted,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    border: AppColors.darkBorder,
    scaffoldGradient: AppColors.softGradientDark,
    lavender: AppColors.darkLavender,
    blush: AppColors.darkBlush,
    butter: AppColors.darkButter,
    shadow: Colors.black,
    isDark: true,
  );

  @override
  NovaColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    LinearGradient? scaffoldGradient,
    Color? lavender,
    Color? blush,
    Color? butter,
    Color? shadow,
    bool? isDark,
  }) {
    return NovaColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      scaffoldGradient: scaffoldGradient ?? this.scaffoldGradient,
      lavender: lavender ?? this.lavender,
      blush: blush ?? this.blush,
      butter: butter ?? this.butter,
      shadow: shadow ?? this.shadow,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  NovaColors lerp(ThemeExtension<NovaColors>? other, double t) {
    if (other is! NovaColors) return this;
    return NovaColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      scaffoldGradient:
          LinearGradient.lerp(scaffoldGradient, other.scaffoldGradient, t)!,
      lavender: Color.lerp(lavender, other.lavender, t)!,
      blush: Color.lerp(blush, other.blush, t)!,
      butter: Color.lerp(butter, other.butter, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// Convenient access to the [NovaColors] of the current theme.
extension BuildContextNovaColors on BuildContext {
  /// The mode-dependent neutral palette of the active theme.
  ///
  /// Falls back to [NovaColors.light] if — for any reason — the extension
  /// has not been registered on the current [ThemeData].
  NovaColors get colors =>
      Theme.of(this).extension<NovaColors>() ?? NovaColors.light;
}
