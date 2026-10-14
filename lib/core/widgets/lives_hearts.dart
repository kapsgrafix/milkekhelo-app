import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Lives as a row of hearts under the score boxes (the classic platformer
/// HUD layout), drawn in the MilkeKhelo style: chunky glossy hearts with a
/// solid ledge underneath, like the app's cards and buttons. A lost heart
/// becomes an empty surface heart with the border/default outline.
/// When a life is lost, that heart hops, wobbles and drains.
///
/// Used by Memory Grid (solo) and Blocks Jodo.
class LivesHearts extends StatefulWidget {
  final int lives;
  final int max;

  /// Width of one heart; its height is about 0.9 × that plus the ledge.
  final double size;
  final double gap;

  const LivesHearts({super.key, required this.lives, this.max = 3, this.size = 26, this.gap = 10});

  @override
  State<LivesHearts> createState() => _LivesHeartsState();
}

class _LivesHeartsState extends State<LivesHearts> with SingleTickerProviderStateMixin {
  late final AnimationController _lose =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  int _losing = -1; // index of the heart currently draining

  @override
  void didUpdateWidget(LivesHearts old) {
    super.didUpdateWidget(old);
    if (widget.lives < old.lives) {
      _losing = widget.lives.clamp(0, widget.max - 1);
      _lose.forward(from: 0);
    } else if (widget.lives > old.lives) {
      _losing = -1;
      _lose.value = 0;
    }
  }

  @override
  void dispose() {
    _lose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.lives} of ${widget.max} lives',
      child: AnimatedBuilder(
        animation: _lose,
        builder: (context, _) {
          final v = _lose.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.max; i++) ...[
                if (i > 0) SizedBox(width: widget.gap),
                _heart(i, v),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _heart(int i, double v) {
    final full = i < widget.lives;
    final losing = i == _losing && _lose.isAnimating;
    Widget h = CustomPaint(
      size: Size(widget.size, widget.size * 0.9 + 3),
      // While draining, the heart stays full for the first half of the hop.
      painter: _HeartPainter(full: full || (losing && v < 0.5)),
    );
    if (losing) {
      final hop = sin(pi * min(1.0, v * 1.6));
      final wobble = sin(v * pi * 8) * (1 - v) * 0.25;
      h = Transform.translate(
        offset: Offset(0, -hop * widget.size * 0.35),
        child: Transform.rotate(angle: wobble, child: Transform.scale(scale: 1 + 0.2 * hop, child: h)),
      );
    }
    return h;
  }
}

/// A rounded heart: pink→red gradient face, 3px dark-red ledge underneath
/// (the same chunky "ledge" as the app's cards), and a soft white glint.
/// Empty: background/surface fill with a border/default outline.
class _HeartPainter extends CustomPainter {
  final bool full;
  const _HeartPainter({required this.full});

  static const _top = Color(0xFFFF8FA8);
  static const _bottom = Color(0xFFE0244A);
  static const _ledge = Color(0xFF7A1030);

  static Path _shape(double w, double h) {
    // Heart in a w × h box: two round lobes meeting in a soft point.
    return Path()
      ..moveTo(w * 0.5, h * 0.98)
      ..cubicTo(w * 0.36, h * 0.86, 0, h * 0.62, 0, h * 0.32)
      ..cubicTo(0, h * 0.12, w * 0.15, 0, w * 0.29, 0)
      ..cubicTo(w * 0.40, 0, w * 0.47, h * 0.07, w * 0.5, h * 0.17)
      ..cubicTo(w * 0.53, h * 0.07, w * 0.60, 0, w * 0.71, 0)
      ..cubicTo(w * 0.85, 0, w, h * 0.12, w, h * 0.32)
      ..cubicTo(w, h * 0.62, w * 0.64, h * 0.86, w * 0.5, h * 0.98)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    const ledge = 3.0;
    final w = size.width;
    final h = size.height - ledge;
    final face = _shape(w, h);

    if (!full) {
      canvas.drawPath(face.shift(const Offset(0, ledge)), Paint()..color = const Color(0x33000000));
      canvas.drawPath(face, Paint()..color = AppColors.surface);
      canvas.drawPath(
        face,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.borderDefault,
      );
      return;
    }

    canvas.drawPath(face.shift(const Offset(0, ledge)), Paint()..color = _ledge);
    canvas.drawPath(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_top, _bottom],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    // Glint on the left lobe.
    canvas.save();
    canvas.translate(w * 0.27, h * 0.27);
    canvas.rotate(-0.6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.22, height: w * 0.12),
      Paint()..color = const Color(0xCCFFFFFF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeartPainter old) => old.full != full;
}
