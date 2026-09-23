import 'package:flutter/material.dart';

/// Fixed game data + colors for Memory Grid only.
class MgLevel {
  final int size;
  final int dots;
  const MgLevel({required this.size, required this.dots});
}

class MgData {
  MgData._();

  static const Map<String, MgLevel> levels = {
    'easy': MgLevel(size: 3, dots: 4),
    'medium': MgLevel(size: 4, dots: 7),
    'hard': MgLevel(size: 5, dots: 10),
  };

  static const Map<String, int> revealMs = {'easy': 500, 'medium': 1000, 'hard': 1500};

  static const int maxLives = 3;
  static const int maxHints = 3;

  static const int duelSize = 5;
  static const int duelDots = 10;
  static const int duelShowMs = 2500;
  static const int duelHintMs = 1200;

  // Root tokens.
  static const Color accent = Color(0xFF16A34A);
  static const Color accent2 = Color(0xFF22C55E);
  static const Color gold = Color(0xFFFBBF24);
  static const Color green = Color(0xFF15A34A); // correct-tap
  static const Color red = Color(0xFFF87171); // wrong-tap
  static const Color dotLit = Color(0xFF4ADE80);
  static const Color dotIdle = Color(0x33FFFFFF); // rgba(255,255,255,.2)

  static const Color screenBg = Color(0xFF0F3D28);

  // Level-card palettes (top, bottom, shadow, text, text-stroke).
  static const easyPalette = MgLevelPalette(
    top: Color(0xFF4ADE80),
    bottom: Color(0xFF15803D),
    shadow: Color(0xFF0D5228),
    text: Colors.white,
    textStroke: Color(0x33000000),
  );
  static const mediumPalette = MgLevelPalette(
    top: Color(0xFFFDE68A),
    bottom: Color(0xFFC2530A),
    shadow: Color(0xFF7A3406),
    text: Color(0xFF1B2340),
    textStroke: Color(0x59FFFFFF),
  );
  static const hardPalette = MgLevelPalette(
    top: Color(0xFFF87171),
    bottom: Color(0xFF991B1B),
    shadow: Color(0xFF5C1010),
    text: Colors.white,
    textStroke: Color(0x33000000),
  );
  static const duelColor = Color(0xFF8B5CF6);
  static const duelShadow = Color(0xFF3A2B6B);

  static const List<Color> confettiColors = [
    Color(0xFF22C55E),
    Color(0xFFFBBF24),
    Color(0xFF4ADE80),
    Color(0xFFA3E635),
    Color(0xFF60A5FA),
    Colors.white,
  ];
}

class MgLevelPalette {
  final Color top;
  final Color bottom;
  final Color shadow;
  final Color text;
  final Color textStroke;
  const MgLevelPalette({
    required this.top,
    required this.bottom,
    required this.shadow,
    required this.text,
    required this.textStroke,
  });
}
