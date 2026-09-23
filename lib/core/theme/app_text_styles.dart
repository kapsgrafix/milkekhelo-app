import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared font helpers. The web app uses 'Baloo 2' for game/headline text,
/// 'Montserrat' for card titles/how-to-play headings, and 'Nunito Sans' for
/// general body chrome. Every game module should pull its fonts from here
/// rather than hardcoding GoogleFonts.* calls, so a font swap only ever
/// happens in one place.
class AppFonts {
  AppFonts._();

  static TextStyle baloo({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color color = Colors.white,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.baloo2(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle montserrat({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color color = Colors.white,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.montserrat(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle nunito({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color color = Colors.white,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.nunitoSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
}
