import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography tokens built on Plus Jakarta Sans.
///
/// [base]/[themed] feed the [ThemeData.textTheme]; the named getters are
/// convenient shorthands for one-off styles in feature code.
///
/// The structural getters ([display], [headline], [title], [subtitle],
/// [body], [price], [button]) deliberately do **not** bake in a text
/// colour — they inherit it from the surrounding [DefaultTextStyle], so
/// they adapt automatically to the active light/dark theme.
///
/// [bodyMuted], [caption] and [label] use the brand muted grey, which has
/// adequate contrast on both light and dark surfaces.
class AppTypography {
  const AppTypography._();

  /// The Plus Jakarta Sans text theme tinted to the brand ink colour.
  ///
  /// Kept for backwards compatibility — prefer [themed] which adapts the
  /// text colour to the active light/dark theme.
  static TextTheme get base => themed(AppColors.ink);

  /// The Plus Jakarta Sans text theme tinted to [textColor].
  ///
  /// Used by [AppTheme] to build the light and dark text themes.
  static TextTheme themed(Color textColor) =>
      GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      );

  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        height: 1.1,
      );

  static TextStyle get headline => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        height: 1.15,
      );

  static TextStyle get title => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get subtitle => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get bodyMuted => body.copyWith(color: AppColors.muted);

  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.muted,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
      );

  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get price => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w900,
      );
}
