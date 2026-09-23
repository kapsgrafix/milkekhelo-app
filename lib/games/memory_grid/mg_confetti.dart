import 'dart:math';
import 'package:flutter/material.dart';

import 'mg_data.dart';

/// A short confetti burst, fired on a solo round win or a duel finishing.
/// Only Memory Grid uses this, so it lives in this game's own folder.
class MgConfetti extends StatefulWidget {
  final Duration duration;
  const MgConfetti({super.key, required this.duration});

  @override
  State<MgConfetti> createState() => MgConfettiState();
}

class MgConfettiState extends State<MgConfetti> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rng = Random();
  List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
  }

  void fire() {
    _particles = List.generate(90, (_) => _Particle.random(_rng));
    _ctrl
      ..reset()
      ..forward();
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(particles: _particles, progress: _ctrl.value, totalMs: widget.duration.inMilliseconds),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double startX;
  final double startY;
  final double w;
  final double h;
  final Color color;
  final double vx;
  final double vy;
  final double rot0;
  final double vr;

  _Particle({
    required this.startX,
    required this.startY,
    required this.w,
    required this.h,
    required this.color,
    required this.vx,
    required this.vy,
    required this.rot0,
    required this.vr,
  });

  factory _Particle.random(Random rng) {
    return _Particle(
      startX: rng.nextDouble(),
      startY: -rng.nextDouble() * 0.5,
      w: 6 + rng.nextDouble() * 6,
      h: 9 + rng.nextDouble() * 8,
      color: MgData.confettiColors[rng.nextInt(MgData.confettiColors.length)],
      vx: -1.2 + rng.nextDouble() * 2.4,
      vy: 2.6 + rng.nextDouble() * 3.2,
      rot0: rng.nextDouble() * 360,
      vr: -7 + rng.nextDouble() * 14,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress; // 0..1
  final int totalMs;

  _ConfettiPainter({required this.particles, required this.progress, required this.totalMs});

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty || progress <= 0) return;
    final elapsedMs = progress * totalMs;
    final remaining = totalMs - elapsedMs;
    final fadeAlpha = remaining < 400 ? (remaining / 400).clamp(0.0, 1.0) : 1.0;
    // Frame count proxy: use elapsed time directly as "ticks" scaled roughly to ~60fps feel.
    final t = elapsedMs / 16.0;

    for (final p in particles) {
      final x = p.startX * size.width + p.vx * t;
      final y = p.startY * size.height + p.vy * t;
      if (y > size.height + 20) continue;
      final rot = (p.rot0 + p.vr * t) * pi / 180;
      final paint = Paint()..color = p.color.withOpacity(fadeAlpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
