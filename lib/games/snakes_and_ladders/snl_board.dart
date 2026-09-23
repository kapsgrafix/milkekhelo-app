import 'package:flutter/material.dart';

import 'snl_data.dart';

/// The Snakes & Ladders board.
///
/// The original web app uses a hand-illustrated `board.png` with the
/// snakes/ladders baked into the artwork. That image isn't available for
/// this port, so the board is instead drawn procedurally from the exact
/// same [SnlData.snakes] / [SnlData.ladders] mapping — same board, same
/// gameplay, just vector-drawn instead of a static image. Swap in real
/// artwork later by replacing the body of [_BoardPainter] with an `Image`.
class SnlBoard extends StatelessWidget {
  final int yellowPos;
  final int redPos;

  const SnlBoard({super.key, required this.yellowPos, required this.redPos});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 30, offset: Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              return Stack(
                children: [
                  CustomPaint(size: size, painter: _BoardPainter()),
                  ..._buildGoti(size),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGoti(Size size) {
    final yellowFrac = _fractionFor('yellow', yellowPos, redPos);
    final redFrac = _fractionFor('red', redPos, yellowPos);
    final gotiSize = size.width * 0.07;
    return [
      _goti(size, yellowFrac, gotiSize, [SnlData.yellowGotiLight, SnlData.yellowGotiDark]),
      _goti(size, redFrac, gotiSize, [SnlData.redGotiLight, SnlData.redGotiDark]),
    ];
  }

  Widget _goti(Size size, Offset frac, double gotiSize, List<Color> colors) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      left: frac.dx * size.width - gotiSize / 2,
      top: frac.dy * size.height - gotiSize / 2,
      width: gotiSize,
      height: gotiSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3))],
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: colors,
          ),
        ),
      ),
    );
  }

  /// Mirrors the web app's `snlCellPct` + overlap-nudge logic: off-board
  /// gotis sit near the bottom-left, and two gotis sharing a square are
  /// nudged apart horizontally so neither is hidden.
  Offset _fractionFor(String color, int pos, int otherPos) {
    if (pos == 0) {
      return Offset(color == 'yellow' ? 0.03 : 0.09, 0.96);
    }
    var frac = snlCellFraction(pos);
    if (pos == otherPos) {
      final nudge = (color == 'yellow' ? -2.4 : 2.4) / 100;
      frac = Offset(frac.dx + nudge, frac.dy);
    }
    return frac;
  }
}

class _BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 10;

    // Base board fill.
    final basePaint = Paint()..color = const Color(0xFF4A1526);
    canvas.drawRect(Offset.zero & size, basePaint);

    // Checkerboard squares + numbers.
    for (int n = 1; n <= 100; n++) {
      final frac = snlCellFraction(n);
      final cx = frac.dx * size.width;
      final cy = frac.dy * size.height;
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: cell, height: cell);
      final idx = n - 1;
      final row = idx ~/ 10;
      final col = idx % 10;
      final isLight = (row + col) % 2 == 0;
      final squarePaint = Paint()
        ..color = isLight ? const Color(0x14FFFFFF) : const Color(0x0AFFFFFF);
      canvas.drawRect(rect.deflate(1), squarePaint);

      final numStyle = TextStyle(
        color: Colors.white.withOpacity(0.32),
        fontSize: cell * 0.24,
        fontWeight: FontWeight.w700,
      );
      final tp = TextPainter(
        text: TextSpan(text: '$n', style: numStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - cell / 2 + 3, cy - cell / 2 + 2));
    }

    // Grid lines.
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    for (int i = 0; i <= 10; i++) {
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, size.height), gridPaint);
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), gridPaint);
    }

    // Ladders.
    for (final entry in SnlData.ladders.entries) {
      _drawLadder(canvas, size, entry.key, entry.value);
    }

    // Snakes.
    for (final entry in SnlData.snakes.entries) {
      _drawSnake(canvas, size, entry.key, entry.value);
    }
  }

  void _drawLadder(Canvas canvas, Size size, int bottom, int top) {
    final p1 = _px(snlCellFraction(bottom), size);
    final p2 = _px(snlCellFraction(top), size);
    final dir = (p2 - p1);
    final len = dir.distance;
    if (len == 0) return;
    final unit = Offset(dir.dx / len, dir.dy / len);
    final perp = Offset(-unit.dy, unit.dx);
    final railOffset = size.width * 0.014;

    final railPaint = Paint()
      ..color = const Color(0xFFC97F00)
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;

    final rail1a = p1 + perp * railOffset;
    final rail1b = p2 + perp * railOffset;
    final rail2a = p1 - perp * railOffset;
    final rail2b = p2 - perp * railOffset;
    canvas.drawLine(rail1a, rail1b, railPaint);
    canvas.drawLine(rail2a, rail2b, railPaint);

    final rungPaint = Paint()
      ..color = const Color(0xFFFFE08A)
      ..strokeWidth = size.width * 0.009
      ..strokeCap = StrokeCap.round;
    const rungCount = 6;
    for (int i = 1; i < rungCount; i++) {
      final t = i / rungCount;
      final a = Offset.lerp(rail1a, rail1b, t)!;
      final b = Offset.lerp(rail2a, rail2b, t)!;
      canvas.drawLine(a, b, rungPaint);
    }
  }

  void _drawSnake(Canvas canvas, Size size, int head, int tail) {
    final p1 = _px(snlCellFraction(head), size); // head (high number)
    final p2 = _px(snlCellFraction(tail), size); // tail (low number)
    final mid = Offset.lerp(p1, p2, 0.5)!;
    final dir = (p2 - p1);
    final len = dir.distance;
    if (len == 0) return;
    final perp = Offset(-dir.dy / len, dir.dx / len);
    final wobble = perp * (size.width * 0.06);
    final ctrl1 = Offset.lerp(p1, mid, 1)! + wobble;
    final ctrl2 = Offset.lerp(mid, p2, 0)! - wobble;

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p2.dx, p2.dy);

    final bodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.022
      ..strokeCap = StrokeCap.round
      ..shader = _snakeGradient(p1, p2);
    canvas.drawPath(path, bodyPaint);

    // Head marker with simple eyes.
    final headPaint = Paint()..color = const Color(0xFF15803D);
    canvas.drawCircle(p1, size.width * 0.02, headPaint);
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(p1 + const Offset(-2, -2), size.width * 0.004, eyePaint);
    canvas.drawCircle(p1 + const Offset(2, -2), size.width * 0.004, eyePaint);
  }

  Shader _snakeGradient(Offset a, Offset b) {
    return const LinearGradient(
      colors: [Color(0xFF4ADE80), Color(0xFF15803D)],
    ).createShader(Rect.fromPoints(a, b));
  }

  Offset _px(Offset frac, Size size) => Offset(frac.dx * size.width, frac.dy * size.height);

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => false;
}
