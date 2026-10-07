import 'dart:math';

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

  /// 'yellow' / 'red' when that goti has just reached 100 — plays the win
  /// burst on (and spilling around) square 100.
  final String? celebrate100;

  const SnlBoard({super.key, required this.yellowPos, required this.redPos, this.celebrate100});

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
              if (celebrate100 != null) _burst(size),
            ],
          );
        },
      ),
    );
  }

  Widget _burst(Size size) {
    final cell = size.width / 10;
    final c = snlCellFraction(100);
    final extent = cell * 4.2;
    final colors = celebrate100 == 'red'
        ? [SnlData.redGotiLight, SnlData.redGotiDark]
        : [SnlData.yellowGotiLight, SnlData.yellowGotiDark];
    return Positioned(
      left: c.dx * size.width - extent / 2,
      top: c.dy * size.height - extent / 2,
      width: extent,
      height: extent,
      child: IgnorePointer(child: _HundredBurst(cell: cell, colors: colors)),
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


/// Win burst on square 100: the square flashes gold, light rays spin out,
/// two shock rings expand, sparkles and confetti fly off in every
/// direction and a trophy pops up — then a soft glow keeps pulsing.
class _HundredBurst extends StatefulWidget {
  final double cell;
  final List<Color> colors;
  const _HundredBurst({required this.cell, required this.colors});

  @override
  State<_HundredBurst> createState() => _HundredBurstState();
}

class _HundredBurstState extends State<_HundredBurst> with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  late final List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    const palette = [Color(0xFFFFD54F), Color(0xFFFFFFFF), Color(0xFFFF7A45), Color(0xFF4ADE80), Color(0xFF60A5FA), Color(0xFFEC4899)];
    _sparks = List.generate(26, (i) {
      final a = i / 26 * pi * 2 + rng.nextDouble() * 0.3;
      return _Spark(a, 0.75 + rng.nextDouble() * 0.6, 0.05 + rng.nextDouble() * 0.06, palette[rng.nextInt(palette.length)], rng.nextBool());
    });
  }

  @override
  void dispose() {
    _pop.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedBuilder(
      animation: Listenable.merge([_pop, _loop]),
      builder: (context, _) {
        final t = reduce ? 1.0 : _pop.value;
        final trophy = Curves.elasticOut.transform((t / 0.55).clamp(0.0, 1.0));
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size.infinite, painter: _BurstPainter(widget.cell, widget.colors, _sparks, t, reduce ? 0 : _loop.value)),
            Transform.translate(
              offset: Offset(0, -widget.cell * 0.15 * trophy),
              child: Transform.scale(
                scale: trophy,
                child: Text('🏆', style: TextStyle(fontSize: widget.cell * 0.72, height: 1)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Spark {
  final double angle, speed, size;
  final Color color;
  final bool star;
  const _Spark(this.angle, this.speed, this.size, this.color, this.star);
}

class _BurstPainter extends CustomPainter {
  final double cell;
  final List<Color> colors;
  final List<_Spark> sparks;
  final double t; // 0 → 1 once
  final double loop; // 0 → 1 repeating
  _BurstPainter(this.cell, this.colors, this.sparks, this.t, this.loop);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final glowPulse = 0.5 + 0.5 * sin(loop * pi * 2);

    // Soft lasting glow behind the square.
    canvas.drawCircle(
      c,
      cell * (1.0 + 0.15 * glowPulse),
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFD54F).withAlpha((150 + 60 * glowPulse).round()),
          const Color(0x00FFD54F),
        ]).createShader(Rect.fromCircle(center: c, radius: cell * 1.2)),
    );

    // Spinning rays.
    final rayLen = cell * (0.8 + 1.1 * Curves.easeOut.transform(min(1, t * 1.6)));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(loop * pi * 2 / 6 + t * 1.2);
    final ray = Paint()
      ..shader = RadialGradient(colors: [const Color(0xCCFFF3C4), const Color(0x00FFD54F)])
          .createShader(Rect.fromCircle(center: Offset.zero, radius: rayLen));
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6;
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(cos(a - 0.11) * rayLen, sin(a - 0.11) * rayLen)
        ..lineTo(cos(a + 0.11) * rayLen, sin(a + 0.11) * rayLen)
        ..close();
      canvas.drawPath(path, ray);
    }
    canvas.restore();

    // Square 100 flashes gold (winner colour at the edge).
    final sq = Rect.fromCenter(center: c, width: cell, height: cell);
    final flash = t < 0.2 ? t / 0.2 : (0.55 + 0.25 * glowPulse);
    canvas.drawRRect(
      RRect.fromRectAndRadius(sq.inflate(2 * glowPulse), Radius.circular(cell * 0.18)),
      Paint()..color = const Color(0xFFFFE082).withAlpha((200 * flash).round()),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sq.inflate(2 * glowPulse), Radius.circular(cell * 0.18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = colors.last,
    );

    // Shock rings.
    for (final delay in const [0.0, 0.18]) {
      final r = ((t - delay) / 0.6).clamp(0.0, 1.0);
      if (r <= 0 || r >= 1) continue;
      canvas.drawCircle(
        c,
        cell * (0.5 + 1.6 * Curves.easeOut.transform(r)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.12 * (1 - r)
          ..color = (delay == 0 ? colors.first : Colors.white).withAlpha((230 * (1 - r)).round()),
      );
    }

    // Sparkles + confetti flying out.
    if (t < 1) {
      for (final s in sparks) {
        final d = cell * 2.0 * s.speed * Curves.easeOut.transform(t);
        final p = c + Offset(cos(s.angle) * d, sin(s.angle) * d + cell * 0.6 * t * t);
        final alpha = ((1 - t) * 255).round();
        final r = s.size * cell * (1 - 0.3 * t);
        final paint = Paint()..color = s.color.withAlpha(alpha);
        if (s.star) {
          _star(canvas, p, r * 1.3, t * 4 + s.angle, paint);
        } else {
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(s.angle + t * 6);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 1.6, height: r), paint);
          canvas.restore();
        }
      }
    }
  }

  void _star(Canvas canvas, Offset c, double r, double rot, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rad = i.isEven ? r : r * 0.4;
      final a = rot + i * pi / 4;
      final p = c + Offset(cos(a) * rad, sin(a) * rad);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => true;
}
