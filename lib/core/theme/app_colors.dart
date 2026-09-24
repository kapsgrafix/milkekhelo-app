import 'package:flutter/material.dart';

/// App-wide color tokens shared by the home screen and every game's shared
/// chrome (header, language toggle, primary CTA button).
///
/// Colors that belong to ONE game only (board colors, card palettes, etc.)
/// live inside that game's own folder instead — keep it that way so a future
/// change to one game's palette never touches this file.
class AppColors {
  AppColors._();

  /// App shell / launcher background.
  static const Color shell = Color(0xFF1A1A2E);

  /// Figma Styleguide tokens used by the home screen ("Home - L0").
  static const Color screenBackground = Color(0xFF0F1A3D); // background/screen
  static const Color surface = Color(0x24FFFFFF); // background/surface  rgba(255,255,255,.14)
  static const Color borderDefault = Color(0x47FFFFFF); // border/default rgba(255,255,255,.28)
  static const Color brandYellow = Color(0xFFFFC53D); // brand/yellow
  static const Color textPrimary = Color(0xFFFFFFFF); // text/primary
  static const Color textOnLight = Color(0xFF1B2340); // text/on-light
  static const Color textMuted = Color(0xFFBABABA); // text/muted

  /// background/surface composited over background/screen — used for the
  /// Android system navigation bar so it blends with the home bottom bar.
  static const Color surfaceOnScreen = Color(0xFF313A58);

  /// Per-game screen backgrounds (Figma background/screen-*).
  static const Color screenPurple = Color(0xFF1B0F3D); // First
  static const Color screenCoral = Color(0xFF3D1C0F); // Thank You

  /// Figma action/* tokens for the chunky CTA buttons.
  static const Color actionPrimary = Color(0xFFFFC53D); // action/primary (also prompt text)
  static const List<Color> primaryGradient = [Color(0xFFFFE08A), Color(0xFFC97F00)];
  static const Color primaryShadow = Color(0xFF7A4B00); // action/primary-shadow
  static const List<Color> secondaryGradient = [Color(0xFF5B8CFF), Color(0xFF16307A)];
  static const Color secondaryShadow = Color(0xFF0C1A42); // action/secondary-shadow

  /// Shared header icon-button background + border (the 32x32 back/help
  /// buttons used by every game screen).
  static const Color headerIconBg = Color(0x24FFFFFF); // rgba(255,255,255,.14)
  static const Color headerIconBorder = Color(0x47FFFFFF); // rgba(255,255,255,.28)

  /// Language toggle chrome.
  static const Color langToggleBg = Color(0x24FFFFFF);
  static const Color langToggleBorder = Color(0x47FFFFFF);
  static const Color langActiveBg = Color(0xFFFFC53D);
  static const Color langActiveText = Color(0xFF1B2340);
  static const Color langInactiveText = Color(0xFFBABABA); // text/muted

  /// Shared primary CTA button gradient ("Play Again" / "Start" everywhere).
  static const List<Color> ctaGradient = [Color(0xFFFFE08A), Color(0xFFC97F00)];
  static const Color ctaShadow = Color(0xFF7A4B00);
  static const Color ctaText = Color(0xFF1B2340);

  /// Home-screen game card gradients: light-top -> dark-bottom, plus a solid
  /// "pressed button" shadow tone. Matches the web app's Figma card colours.
  static const snakesAndLadders = GameCardPalette(
    top: Color(0xFFFF93B3),
    bottom: Color(0xFFCC2F63),
    shadow: Color(0xFF701A36),
  );
  static const memoryGrid = GameCardPalette(
    top: Color(0xFF6EE0AC),
    bottom: Color(0xFF1E8A5C),
    shadow: Color(0xFF114C33),
  );
  static const first = GameCardPalette(
    top: Color(0xFFC3B0F5),
    bottom: Color(0xFF6A4FC2),
    shadow: Color(0xFF3A2B6B),
  );
  static const thankYou = GameCardPalette(
    top: Color(0xFFFFA57D),
    bottom: Color(0xFFCC4E1E),
    shadow: Color(0xFF702B11),
  );

  static const Color goldAccent = Color(0xFFFFD700);
}

/// A light-top / dark-bottom / shadow-ledge trio used by the bouncy 3D game
/// cards throughout the app (home screen tiles, Memory Grid level cards).
class GameCardPalette {
  final Color top;
  final Color bottom;
  final Color shadow;
  const GameCardPalette({required this.top, required this.bottom, required this.shadow});
}
