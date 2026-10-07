import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'chess_engine.dart';

/// The 12 chess pieces, drawn in code (no image files). Each piece is a few
/// vector shapes on a 100 × 100 grid, painted back to front: a soft
/// gradient fill with a fine outline — dark on the ivory White pieces, light
/// on the ebony Black pieces — so both read clearly on light and dark wood.
/// A small blurred shadow lifts each piece off the board.
enum _Kind { body, line, dot }

class ChessPieceArt {
  ChessPieceArt._();

  static const Color whiteTop = Color(0xFFFFFDF7);
  static const Color whiteBottom = Color(0xFFE4D3B4);
  static const Color whiteEdge = Color(0xFF3A2416);
  static const Color blackTop = Color(0xFF57493F);
  static const Color blackBottom = Color(0xFF1C1512);
  static const Color blackEdge = Color(0xFFF3E7D2);

  static const Map<int, List<(String, _Kind)>> _src = {
    // pawn
    ChessPiece.pawn: [
      ('M39,44 C39,58 31,66 28,77 L72,77 C69,66 61,58 61,44 Z', _Kind.body),
      ('M18,92 C18,84 22,78 30,76 L70,76 C78,78 82,84 82,92 C82,95 80,96 77,96 L23,96 C20,96 18,95 18,92 Z', _Kind.body),
      ('M37.5,40 L62.5,40 C64.99,40 67,42.01 67,44.5 C67,46.99 64.99,49 62.5,49 L37.5,49 C35.01,49 33,46.99 33,44.5 C33,42.01 35.01,40 37.5,40 Z', _Kind.body),
      ('M63,27 C63,34.18 57.18,40 50,40 C42.82,40 37,34.18 37,27 C37,19.82 42.82,14 50,14 C57.18,14 63,19.82 63,27 Z', _Kind.body),
    ],
    // knight
    ChessPiece.knight: [
      ('M18,92 C18,84 22,78 30,76 L70,76 C78,78 82,84 82,92 C82,95 80,96 77,96 L23,96 C20,96 18,95 18,92 Z', _Kind.body),
      ('M31,77 C31,62 40,54 45,47 C41,47 35,49 29,53 C23,56 17,52 19,45 C21,38 30,33 35,27 C39,21 42,16 46,14 L49,7 L54,15 C65,17 73,28 73,44 C73,58 69,67 71,77 Z', _Kind.body),
      ('M55,16 C63,24 67,34 67,47', _Kind.line),
      ('M45.6,26 C45.6,27.44 44.44,28.6 43,28.6 C41.56,28.6 40.4,27.44 40.4,26 C40.4,24.56 41.56,23.4 43,23.4 C44.44,23.4 45.6,24.56 45.6,26 Z', _Kind.dot),
      ('M24,47 L27,46', _Kind.line),
    ],
    // bishop
    ChessPiece.bishop: [
      ('M40,50 C38,62 32,68 29,77 L71,77 C68,68 62,62 60,50 Z', _Kind.body),
      ('M18,92 C18,84 22,78 30,76 L70,76 C78,78 82,84 82,92 C82,95 80,96 77,96 L23,96 C20,96 18,95 18,92 Z', _Kind.body),
      ('M38.5,46 L61.5,46 C63.99,46 66,48.01 66,50.5 C66,52.99 63.99,55 61.5,55 L38.5,55 C36.01,55 34,52.99 34,50.5 C34,48.01 36.01,46 38.5,46 Z', _Kind.body),
      ('M50,13 C62,20 67,30 65,38 C63,45 57,48 50,48 C43,48 37,45 35,38 C33,30 38,20 50,13 Z', _Kind.body),
      ('M56,24 L48,35', _Kind.line),
      ('M55,10 C55,12.76 52.76,15 50,15 C47.24,15 45,12.76 45,10 C45,7.24 47.24,5 50,5 C52.76,5 55,7.24 55,10 Z', _Kind.body),
    ],
    // rook
    ChessPiece.rook: [
      ('M33,40 L67,40 L64,75 L36,75 Z', _Kind.body),
      ('M18,92 C18,84 22,78 30,76 L70,76 C78,78 82,84 82,92 C82,95 80,96 77,96 L23,96 C20,96 18,95 18,92 Z', _Kind.body),
      ('M33.5,71 L66.5,71 C68.99,71 71,73.01 71,75.5 C71,77.99 68.99,80 66.5,80 L33.5,80 C31.01,80 29,77.99 29,75.5 C29,73.01 31.01,71 33.5,71 Z', _Kind.body),
      ('M27,14 L38,14 L38,22 L45,22 L45,14 L55,14 L55,22 L62,22 L62,14 L73,14 L73,36 C73,40 71,43 67,43 L33,43 C29,43 27,40 27,36 Z', _Kind.body),
      ('M31,36 L69,36', _Kind.line),
    ],
    // queen
    ChessPiece.queen: [
      ('M36,48 C38,61 32,68 29,77 L71,77 C68,68 62,61 64,48 Z', _Kind.body),
      ('M18,92 C18,84 22,78 30,76 L70,76 C78,78 82,84 82,92 C82,95 80,96 77,96 L23,96 C20,96 18,95 18,92 Z', _Kind.body),
      ('M30,50 L21,24 L31,38 L36,17 L44,34 L50,12 L56,34 L64,17 L69,38 L79,24 L70,50 Z', _Kind.body),
      ('M35.5,46 L64.5,46 C66.99,46 69,48.01 69,50.5 C69,52.99 66.99,55 64.5,55 L35.5,55 C33.01,55 31,52.99 31,50.5 C31,48.01 33.01,46 35.5,46 Z', _Kind.body),
      ('M25.5,22 C25.5,24.49 23.49,26.5 21,26.5 C18.51,26.5 16.5,24.49 16.5,22 C16.5,19.51 18.51,17.5 21,17.5 C23.49,17.5 25.5,19.51 25.5,22 Z', _Kind.body),
      ('M40.5,15 C40.5,17.49 38.49,19.5 36,19.5 C33.51,19.5 31.5,17.49 31.5,15 C31.5,12.51 33.51,10.5 36,10.5 C38.49,10.5 40.5,12.51 40.5,15 Z', _Kind.body),
      ('M54.5,10 C54.5,12.49 52.49,14.5 50,14.5 C47.51,14.5 45.5,12.49 45.5,10 C45.5,7.51 47.51,5.5 50,5.5 C52.49,5.5 54.5,7.51 54.5,10 Z', _Kind.body),
      ('M68.5,15 C68.5,17.49 66.49,19.5 64,19.5 C61.51,19.5 59.5,17.49 59.5,15 C59.5,12.51 61.51,10.5 64,10.5 C66.49,10.5 68.5,12.51 68.5,15 Z', _Kind.body),
      ('M83.5,22 C83.5,24.49 81.49,26.5 79,26.5 C76.51,26.5 74.5,24.49 74.5,22 C74.5,19.51 76.51,17.5 79,17.5 C81.49,17.5 83.5,19.51 83.5,22 Z', _Kind.body),
    ],
    // king
    ChessPiece.king: [
      ('M36,48 C38,61 32,68 29,77 L71,77 C68,68 62,61 64,48 Z', _Kind.body),
      ('M18,92 C18,84 22,78 30,76 L70,76 C78,78 82,84 82,92 C82,95 80,96 77,96 L23,96 C20,96 18,95 18,92 Z', _Kind.body),
      ('M29,48 C24,36 32,26 50,31 C68,26 76,36 71,48 Z', _Kind.body),
      ('M34.5,44 L65.5,44 C67.99,44 70,46.01 70,48.5 C70,50.99 67.99,53 65.5,53 L34.5,53 C32.01,53 30,50.99 30,48.5 C30,46.01 32.01,44 34.5,44 Z', _Kind.body),
      ('M46,6 L54,6 L54,13 L61,13 L61,20 L54,20 L54,31 L46,31 L46,20 L39,20 L39,13 L46,13 Z', _Kind.body),
    ],
  };

  static final Map<int, List<(Path, _Kind)>> _cache = {};
  static final Map<int, Path> _silhouette = {};

  static List<(Path, _Kind)> _shapes(int type) => _cache.putIfAbsent(
        type,
        () => [for (final s in _src[type]!) (_parse(s.$1), s.$2)],
      );

  static Path _outline(int type) => _silhouette.putIfAbsent(type, () {
        final p = Path();
        for (final s in _shapes(type)) {
          if (s.$2 == _Kind.body) p.addPath(s.$1, Offset.zero);
        }
        return p;
      });

  /// Paints [piece] (signed: + White, − Black) filling [rect].
  /// [shadow] = false for tiny icons (captured-pieces tray).
  static void paint(Canvas canvas, Rect rect, int piece, {bool shadow = true, double opacity = 1}) {
    if (piece == 0 || opacity <= 0) return;
    final type = piece.abs();
    final white = piece > 0;
    final k = rect.width / 100;
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.scale(k);
    int a(double v) => (v * 255 * opacity).round().clamp(0, 255);

    if (shadow) {
      canvas.save();
      canvas.translate(0, 3);
      canvas.drawPath(
        _outline(type),
        Paint()
          ..color = Color.fromARGB(a(0.32), 0, 0, 0)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
      canvas.restore();
    }

    final fill = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(0, 100),
        [
          (white ? whiteTop : blackTop).withAlpha(a(1)),
          (white ? whiteBottom : blackBottom).withAlpha(a(1)),
        ],
      );
    final edge = (white ? whiteEdge : blackEdge).withAlpha(a(1));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round
      ..color = edge;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = edge;
    for (final s in _shapes(type)) {
      switch (s.$2) {
        case _Kind.body:
          canvas.drawPath(s.$1, fill);
          canvas.drawPath(s.$1, stroke);
        case _Kind.line:
          canvas.drawPath(s.$1, line);
        case _Kind.dot:
          canvas.drawPath(s.$1, Paint()..color = edge);
      }
    }
    canvas.restore();
  }

  /// Minimal SVG path reader for the absolute M / L / C / Z commands above.
  static Path _parse(String d) {
    final path = Path();
    final tokens = RegExp(r'[MLCZ]|-?\d*\.?\d+').allMatches(d).map((m) => m.group(0)!).toList();
    var i = 0;
    String cmd = 'M';
    double n() => double.parse(tokens[i++]);
    while (i < tokens.length) {
      final t = tokens[i];
      if (t == 'M' || t == 'L' || t == 'C' || t == 'Z') {
        cmd = t;
        i++;
        if (cmd == 'Z') {
          path.close();
          continue;
        }
      }
      switch (cmd) {
        case 'M':
          path.moveTo(n(), n());
          cmd = 'L';
        case 'L':
          path.lineTo(n(), n());
        case 'C':
          path.cubicTo(n(), n(), n(), n(), n(), n());
        default:
          i++;
      }
    }
    return path;
  }
}

/// A single piece as a widget (captured-pieces tray, promotion picker).
class ChessPieceIcon extends StatelessWidget {
  final int piece;
  final double size;
  final bool shadow;
  const ChessPieceIcon({super.key, required this.piece, required this.size, this.shadow = false});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _IconPainter(piece, shadow));
}

class _IconPainter extends CustomPainter {
  final int piece;
  final bool shadow;
  _IconPainter(this.piece, this.shadow);

  @override
  void paint(Canvas canvas, Size size) => ChessPieceArt.paint(canvas, Offset.zero & size, piece, shadow: shadow);

  @override
  bool shouldRepaint(covariant _IconPainter old) => old.piece != piece;
}
