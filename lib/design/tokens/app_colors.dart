import 'package:flutter/material.dart';

/// The NovAiShop colour palette. Single source of truth — do not redeclare
/// colours in feature code.
class AppColors {
  const AppColors._();

  /// Brand accent — lime green.
  static const lime = Color(0xFF9CF239);

  /// Primary dark surface (nav bar, dark cards).
  static const deepInk = Color(0xFF202623);

  /// Default text colour.
  static const ink = Color(0xFF151816);

  /// Secondary / muted text colour.
  static const muted = Color(0xFF6F766F);

  /// Pure white surface.
  static const surface = Color(0xFFFFFFFF);

  /// Soft background tint.
  static const mist = Color(0xFFF2F8EC);

  /// Soft purple accent.
  static const lavender = Color(0xFFE8DDFE);

  /// Soft pink accent.
  static const blush = Color(0xFFFBE4DE);

  /// Soft yellow accent.
  static const butter = Color(0xFFF3F8D8);

  // Semantic colours.
  static const success = Color(0xFF2E9E5B);
  static const warning = Color(0xFFE0A106);
  static const danger = Color(0xFFD8492B);
  static const info = Color(0xFF3B7DDA);

  /// Hairline borders.
  static const border = Color(0xFFD7E2CC);

  /// Soft background gradient used by [SoftGradientScaffold] in light mode.
  static const softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEFFFF0), Color(0xFFDDF8B8), mist],
  );

  // ---------------------------------------------------------------------
  // Dark-mode neutral palette.
  //
  // Brand accents (lime, semantic colours) stay constant; only the neutral
  // surfaces / backgrounds / text / borders flip in dark mode. These
  // constants feed the dark [NovaColors] theme extension.
  // ---------------------------------------------------------------------

  /// Deep neutral app background for dark mode (not pure black).
  static const darkBackground = Color(0xFF14171A);

  /// Raised surface (cards, sheets) for dark mode.
  static const darkSurface = Color(0xFF1F242A);

  /// Slightly lighter muted surface for dark mode.
  static const darkSurfaceMuted = Color(0xFF272E35);

  /// Primary text colour for dark mode.
  static const darkTextPrimary = Color(0xFFEDF1F0);

  /// Secondary / muted text colour for dark mode.
  static const darkTextSecondary = Color(0xFF9BA4A8);

  /// Hairline borders for dark mode.
  static const darkBorder = Color(0xFF333B42);

  /// Dark-mode equivalents of the pastel tints, desaturated and darkened
  /// so text laid over them stays legible.
  static const darkLavender = Color(0xFF35304A);
  static const darkBlush = Color(0xFF3F3331);
  static const darkButter = Color(0xFF383C2C);

  /// Soft background gradient for dark mode.
  static const softGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B2420), Color(0xFF1A1F22), darkBackground],
  );
}
