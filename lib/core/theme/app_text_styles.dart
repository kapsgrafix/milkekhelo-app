import 'package:flutter/material.dart';

/// Typography. The whole app uses **Baloo 2**, bundled locally in
/// assets/fonts/ (weights 400 / 500 / 600 / 700 / 800) so text renders correctly
/// offline on first launch — no runtime font download.
///
/// Two layers:
///  * [AppText] — the named text styles from the Figma file. Use these
///    wherever a Figma style exists so the app matches the design exactly.
///  * [AppFonts.baloo] — the low-level helper for one-off sizes that have
///    no named Figma style yet (e.g. in-game card copy).
class AppFonts {
  AppFonts._();

  /// Family name registered in pubspec.yaml.
  static const String family = 'Baloo2';

  /// Baloo 2 at any size/weight. When [height] is set, leading is split
  /// evenly above and below the glyphs, which is how Figma (and CSS)
  /// apply line height — so text sits in the same place as in the design.
  static TextStyle baloo({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color color = Colors.white,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontFamily: family,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        leadingDistribution: height == null ? null : TextLeadingDistribution.even,
      );
}

/// Named text styles, 1:1 with the Figma design (MilkeKhelo-Design).
/// `height: null` = Figma "line height: auto/normal".
class AppText {
  AppText._();

  /// Figma `label/card` — ExtraBold 16 / 125%. Game card labels, game
  /// header titles, the card-deck prompt line.
  static TextStyle labelCard({Color color = Colors.white}) =>
      AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w800, height: 1.25, color: color);

  /// Figma `caption/default` — SemiBold 11 / 130% / +0.4. Hints under cards.
  static TextStyle caption({Color color = const Color(0xFFBABABA)}) =>
      AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: 0.4, color: color);

  /// Button label (Primary CTA) — Bold 20 / 100% / +0.2.
  static TextStyle button({Color color = const Color(0xFF1B2340)}) =>
      AppFonts.baloo(fontSize: 20, fontWeight: FontWeight.w700, height: 1.0, letterSpacing: 0.2, color: color);

  /// Progress counter ("1/51") — SemiBold 13 / 14px.
  static TextStyle progress({Color color = const Color(0xFFBABABA)}) =>
      AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w600, height: 14 / 13, color: color);

  /// Language toggle segments (EN / हिं) — Bold 15 / auto.
  static TextStyle toggle({required Color color}) =>
      AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w700, color: color);

  /// Figma `stat/number` — ExtraBold 32 / 105%. Big numbers (match timer).
  static TextStyle statNumber({Color color = const Color(0xFFFFC53D)}) =>
      AppFonts.baloo(fontSize: 32, fontWeight: FontWeight.w800, height: 1.05, color: color);

  /// Logo tagline — SemiBold 12 / auto.
  static TextStyle tagline({Color color = Colors.white}) =>
      AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w600, color: color);
}
