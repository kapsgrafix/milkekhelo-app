import 'package:flutter/material.dart';

import 'snl_data.dart';

/// The Snakes & Ladders board: the illustrated board image
/// (assets/snakes_and_ladders/board.webp — same artwork as the web app's
/// board.png) with the two gotis positioned on top.
///
/// The snakes and ladders are part of the artwork; [SnlData.snakes] /
/// [SnlData.ladders] were mapped from this exact image, so if the artwork
/// ever changes, that mapping must be updated to match.
class SnlBoard extends StatelessWidget {
  final int yellowPos;
  final int redPos;

  const SnlBoard({super.key, required this.yellowPos, required this.redPos});

  static const String asset = 'assets/snakes_and_ladders/board.webp';

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  semanticLabel: 'Snakes and Ladders board',
                ),
              ),
              ..._buildGoti(size),
            ],
          );
        },
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
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 3))],
          gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: colors),
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

/// Dice face with black pips (value 1–6), drawn so it looks the same on
/// every device — unlike the ⚀–⚅ text glyphs, which some fonts render in
/// the text colour (white).
class SnlDiceFace extends StatelessWidget {
  final int value;
  final double size;
  const SnlDiceFace({super.key, required this.value, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _PipPainter(value));
  }
}

class _PipPainter extends CustomPainter {
  final int value;
  const _PipPainter(this.value);

  // Pip positions on a 3×3 grid (0 = left/top, 1 = centre, 2 = right/bottom).
  static const Map<int, List<List<int>>> _layout = {
    1: [[1, 1]],
    2: [[0, 0], [2, 2]],
    3: [[0, 0], [1, 1], [2, 2]],
    4: [[0, 0], [2, 0], [0, 2], [2, 2]],
    5: [[0, 0], [2, 0], [1, 1], [0, 2], [2, 2]],
    6: [[0, 0], [2, 0], [0, 1], [2, 1], [0, 2], [2, 2]],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF111111);
    final step = size.width / 3;
    final r = size.width * 0.105;
    for (final p in _layout[value.clamp(1, 6)]!) {
      canvas.drawCircle(Offset(step * p[0] + step / 2, step * p[1] + step / 2), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PipPainter old) => old.value != value;
}
