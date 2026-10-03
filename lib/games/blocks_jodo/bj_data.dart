import 'dart:math';
import 'dart:ui';

/// Constants, colours and the piece catalogue for Blocks Jodo.
/// Kept entirely inside this game's folder.
class BjData {
  BjData._();

  /// Figma "Blocks Jodo L2" (252:1195) uses background/screen-pink.
  static const Color screenBg = Color(0xFF3D0F1E);

  /// 8×8 board, as in Block Blast.
  static const int size = 8;

  /// Block Blast clears full rows AND full columns. Set to false to clear
  /// horizontal rows only (classic Tetris rule).
  static const bool clearColumns = true;

  static const int maxLives = 3;

  /// Moves allowed between clears before the combo resets (Block Blast-style).
  static const int comboGrace = 3;

  /// Bonus for wiping the whole board.
  static const int allClearBonus = 300;

  static const String bestKey = 'blocks_jodo_best';

  // ---- Board (Figma) ---------------------------------------------------------
  static const Color boardFill = Color(0x59000000); // background/slot-empty rgba(0,0,0,.35)
  static const Color boardBorder = Color(0x66FFFFFF); // rgba(255,255,255,.40)
  static const Color slotFill = Color(0x14D9D9D9); // rgba(217,217,217,.08)
  static const Color blockEdge = Color(0x0A000000); // rgba(0,0,0,.04) inner border

  // ---- Block colours (Figma module tokens) ------------------------------------
  static const List<Color> blockColors = [
    Color(0xFFFF7A45), // module/coral
    Color(0xFFFFC53D), // action/primary (yellow)
    Color(0xFFC3B0F5), // module/purple-light
    Color(0xFFFF5D8F), // module/pink
    Color(0xFF6EE0AC), // module/green-light
    Color(0xFF5B8CFF), // action/secondary (blue)
  ];

  static const Color gold = Color(0xFFFFC53D);
  static const Color deadBlock = Color(0xFF5E4A52);

  /// Points for clearing n lines in one move (before the combo multiplier).
  static int linePoints(int n) => 10 * n * (n + 1) ~/ 2; // 10, 30, 60, 100, …
}

/// One cell offset inside a piece.
class BjCell {
  final int r;
  final int c;
  const BjCell(this.r, this.c);
}

/// A shape from the catalogue. [weight] = how often it is dealt.
class BjShape {
  final List<BjCell> cells;
  final int rows;
  final int cols;
  final double weight;

  BjShape._(this.cells, this.rows, this.cols, this.weight);

  /// Builds a shape from a picture such as 'XX/X.' (rows split by '/').
  factory BjShape.parse(String pattern, double weight) {
    final lines = pattern.split('/');
    final cells = <BjCell>[];
    for (var r = 0; r < lines.length; r++) {
      for (var c = 0; c < lines[r].length; c++) {
        if (lines[r][c] == 'X') cells.add(BjCell(r, c));
      }
    }
    final cols = lines.map((l) => l.length).reduce(max);
    return BjShape._(cells, lines.length, cols, weight);
  }
}

/// A shape dealt into the tray with its colour.
class BjPiece {
  final BjShape shape;
  final Color color;
  const BjPiece(this.shape, this.color);

  List<BjCell> get cells => shape.cells;
  int get rows => shape.rows;
  int get cols => shape.cols;
}

/// Block Blast-style catalogue: lines, squares, rectangles, small and big
/// corners, and the tetrominoes in every orientation.
final List<BjShape> bjShapes = [
  BjShape.parse('X', 1.5),
  BjShape.parse('XX', 2.5),
  BjShape.parse('X/X', 2.5),
  BjShape.parse('XXX', 3),
  BjShape.parse('X/X/X', 3),
  BjShape.parse('XXXX', 2),
  BjShape.parse('X/X/X/X', 2),
  BjShape.parse('XXXXX', 1),
  BjShape.parse('X/X/X/X/X', 1),
  BjShape.parse('XX/XX', 4),
  BjShape.parse('XXX/XXX/XXX', 1.2),
  BjShape.parse('XXX/XXX', 1.5),
  BjShape.parse('XX/XX/XX', 1.5),
  // small corners
  BjShape.parse('XX/X.', 2),
  BjShape.parse('XX/.X', 2),
  BjShape.parse('X./XX', 2),
  BjShape.parse('.X/XX', 2),
  // L / J tetrominoes
  BjShape.parse('X./X./XX', 1.2),
  BjShape.parse('.X/.X/XX', 1.2),
  BjShape.parse('XX/X./X.', 1.2),
  BjShape.parse('XX/.X/.X', 1.2),
  BjShape.parse('XXX/X..', 1.2),
  BjShape.parse('XXX/..X', 1.2),
  BjShape.parse('X../XXX', 1.2),
  BjShape.parse('..X/XXX', 1.2),
  // T
  BjShape.parse('XXX/.X.', 1.2),
  BjShape.parse('.X./XXX', 1.2),
  BjShape.parse('X./XX/X.', 1.2),
  BjShape.parse('.X/XX/.X', 1.2),
  // S / Z
  BjShape.parse('.XX/XX.', 1),
  BjShape.parse('XX./.XX', 1),
  BjShape.parse('X./XX/.X', 1),
  BjShape.parse('.X/XX/X.', 1),
  // big corners
  BjShape.parse('XXX/X../X..', 1),
  BjShape.parse('XXX/..X/..X', 1),
  BjShape.parse('X../X../XXX', 1),
  BjShape.parse('..X/..X/XXX', 1),
];
