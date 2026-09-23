import 'package:flutter/material.dart';

/// Fixed game data + colors for Snakes & Ladders only. Nothing here is
/// imported by any other game.
class SnlData {
  SnlData._();

  /// Snake head -> tail square mapping (1-100 board).
  static const Map<int, int> snakes = {
    99: 41,
    89: 53,
    76: 58,
    66: 45,
    54: 31,
    43: 18,
    40: 3,
    27: 5,
  };

  /// Ladder bottom -> top square mapping.
  static const Map<int, int> ladders = {
    4: 25,
    13: 46,
    33: 49,
    42: 63,
    50: 69,
    62: 81,
    74: 92,
  };

  static const List<String> diceFaces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];

  // Goti (piece) colors.
  static const Color yellowGotiLight = Color(0xFFFDE68A);
  static const Color yellowGotiDark = Color(0xFFF59E0B);
  static const Color redGotiLight = Color(0xFFFCA5A5);
  static const Color redGotiDark = Color(0xFFDC2626);

  // Player chip active-border colors.
  static const Color yellowActiveBorder = Color(0xFFFFC53D);
  static const Color redActiveBorder = Color(0xFFFF7A45);

  // Player chip icon-swatch fill colors (also win-title colors).
  static const Color yellowSwatch = Color(0xFFFBBF24);
  static const Color redSwatch = Color(0xFFEF4444);

  // Dice gradients per turn.
  static const List<Color> diceIdle = [Color(0xFFFFFFFF), Color(0xFFE5E5E5)];
  static const List<Color> diceYellow = [Color(0xFFFDE68A), Color(0xFFF59E0B)];
  static const List<Color> diceRed = [Color(0xFFFCA5A5), Color(0xFFDC2626)];

  // Screen backgrounds (this game's own warm dark-brown family).
  static const Color screenBg = Color(0xFF3D0F1E);
  static const Color endOverlayBg = Color(0xF7331A02); // rgba(61,26,2,.97)
  static const Color howOverlayBg = Color(0xE0281202); // rgba(40,18,2,.88)
  static const Color howAccent = Color(0xFF60A5FA);
}

/// Maps a square number (1-100) to its center position as a fraction (0-1)
/// of the square board's width/height, using the standard boustrophedon
/// (snake-path) Snakes & Ladders layout: row 1 (squares 1-10) runs left to
/// right along the bottom, row 2 (11-20) runs right to left, and so on.
Offset snlCellFraction(int n) {
  final idx = n - 1;
  final rowFromBottom = idx ~/ 10; // 0 = bottom row, 9 = top row
  final posInRow = idx % 10;
  final leftToRight = rowFromBottom % 2 == 0;
  final col = leftToRight ? posInRow : (9 - posInRow);
  final rowFromTop = 9 - rowFromBottom;
  final x = (col * 10 + 5) / 100;
  final y = (rowFromTop * 10 + 5) / 100;
  return Offset(x, y);
}
