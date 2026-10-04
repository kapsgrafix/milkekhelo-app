import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import 'bj_data.dart';
import 'bj_engine.dart';

// ─────────────────────────── Block look ───────────────────────────

/// Draws one block. Figma: module colour, 2px radius and a faint 4px inner
/// edge (rgba(0,0,0,.04)) at 39.75px — plus a soft top light and bottom
/// shade so pieces read as chunky, tappable blocks. Phase 2: the face is a
/// gentle top-to-bottom gradient (a touch lighter → a touch deeper) for a
/// subtle sheen.
void paintBlock(Canvas canvas, Rect r, Color color, {double opacity = 1}) {
  if (opacity <= 0) return;
  final w = r.width;
  if (w <= 0) return;
  final radius = Radius.circular(max(2.0, w * 0.06));
  final rr = RRect.fromRectAndRadius(r, radius);
  int a(double v) => (v * 255 * opacity).round().clamp(0, 255);
  final hsl = HSLColor.fromColor(color);
  final lighter = hsl.withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0)).toColor();
  final deeper = hsl.withLightness((hsl.lightness - 0.06).clamp(0.0, 1.0)).toColor();
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lighter.withAlpha(a(1.0)), color.withAlpha(a(1.0)), deeper.withAlpha(a(1.0))],
        stops: const [0, 0.5, 1],
      ).createShader(r),
  );
  final band = w * 0.13;
  canvas.save();
  canvas.clipRRect(rr);
  canvas.drawRect(Rect.fromLTWH(r.left, r.top, w, band), Paint()..color = Color.fromARGB(a(0.26), 255, 255, 255));
  canvas.drawRect(Rect.fromLTWH(r.left, r.bottom - band, w, band), Paint()..color = Color.fromARGB(a(0.16), 0, 0, 0));
  canvas.restore();
  final edge = w * 0.1;
  canvas.drawRRect(
    rr.deflate(edge / 2),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = edge
      ..color = Color.fromARGB(a(0.04), 0, 0, 0),
  );
}

/// A whole piece at a given cell size / gap (tray, drag overlay).
class BjPiecePainter extends CustomPainter {
  final BjPiece piece;
  final double cell;
  final double gap;
  final double opacity;
  final Color? overrideColor;

  /// A tight drop shadow under each block (the piece being dragged).
  final bool shadow;

  const BjPiecePainter({
    required this.piece,
    required this.cell,
    required this.gap,
    this.opacity = 1,
    this.overrideColor,
    this.shadow = false,
  });

  static Size sizeFor(BjPiece p, double cell, double gap) =>
      Size(p.cols * cell + (p.cols - 1) * gap, p.rows * cell + (p.rows - 1) * gap);

  @override
  void paint(Canvas canvas, Size size) {
    if (shadow) {
      // Close to the block: 3px down, 2px soft edge.
      final p = Paint()
        ..color = const Color(0x4D000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      for (final c in piece.cells) {
        final r = Rect.fromLTWH(c.c * (cell + gap), c.r * (cell + gap) + 3, cell, cell);
        canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(max(2.0, cell * 0.06))), p);
      }
    }
    for (final c in piece.cells) {
      final r = Rect.fromLTWH(c.c * (cell + gap), c.r * (cell + gap), cell, cell);
      paintBlock(canvas, r, overrideColor ?? piece.color, opacity: opacity);
    }
  }

  @override
  bool shouldRepaint(covariant BjPiecePainter old) =>
      old.piece != piece || old.cell != cell || old.gap != gap || old.opacity != opacity || old.overrideColor != overrideColor || old.shadow != shadow;
}

// ─────────────────────────── Effects model ───────────────────────────

/// A cleared cell that flashes white, swells and pops.
class BjBurst {
  final int index;
  final Color color;
  final double start;
  const BjBurst(this.index, this.color, this.start);
  static const double duration = 0.42;
}

/// A bright beam sweeping along a cleared row / column.
class BjBeam {
  final bool row;
  final int line;
  final Color color;
  final double start;
  const BjBeam(this.row, this.line, this.color, this.start);
  static const double duration = 0.4;
}

/// A tiny square shard flying out of a cleared cell (board coordinates).
class BjParticle {
  final Offset origin;
  final Offset velocity;
  final Color color;
  final double start;
  final double life;
  final double size;
  final double spin;
  const BjParticle(this.origin, this.velocity, this.color, this.start, this.life, this.size, this.spin);
  static const double gravity = 900;
}

/// "+60" score pop rising from where the piece landed.
class BjFloat {
  final String text;
  final Offset pos;
  final double start;
  const BjFloat(this.text, this.pos, this.start);
  static const double duration = 0.95;
}

// ─────────────────────────── Board painter ───────────────────────────

/// Everything the board painter needs for one frame.
class BjBoardScene {
  final BjBoard board;
  final double Function() now;
  Set<int> preview = {};
  Color? previewColor;
  BjLines glow = BjLines.empty;
  final Map<int, double> pops = {};
  final List<BjBurst> bursts = [];
  final List<BjBeam> beams = [];
  final List<BjParticle> particles = [];
  final List<BjFloat> floats = [];
  double? introStart;
  double? gameOverStart;

  BjBoardScene(this.board, this.now);

  /// Removes finished effects; true while anything still needs frames.
  bool prune() {
    final t = now();
    bursts.removeWhere((b) => t - b.start > BjBurst.duration);
    beams.removeWhere((b) => t - b.start > BjBeam.duration);
    particles.removeWhere((p) => t - p.start > p.life);
    floats.removeWhere((f) => t - f.start > BjFloat.duration);
    pops.removeWhere((_, s) => t - s > 0.3);
    final intro = introStart != null && t - introStart! < 0.9;
    final over = gameOverStart != null && t - gameOverStart! < 1.0;
    return bursts.isNotEmpty || beams.isNotEmpty || particles.isNotEmpty || floats.isNotEmpty || pops.isNotEmpty || !glow.isEmpty || intro || over;
  }
}

class BjBoardPainter extends CustomPainter {
  final BjBoardScene s;
  BjBoardPainter(this.s, Listenable repaint) : super(repaint: repaint);

  static const double gap = 2;

  @override
  void paint(Canvas canvas, Size size) {
    const n = BjData.size;
    final cell = (size.width - gap * (n - 1)) / n;
    final pitch = cell + gap;
    final t = s.now();
    Rect rectOf(int i) => Rect.fromLTWH((i % n) * pitch, (i ~/ n) * pitch, cell, cell);
    Rect scaled(Rect r, double k) => Rect.fromCenter(center: r.center, width: r.width * k, height: r.height * k);

    final glowIdx = s.glow.indices;
    final glowColor = s.previewColor;
    final pulse = 0.5 + 0.5 * sin(t * 10);

    // Empty slots (with a diagonal "wave" when a game starts).
    final slot = Paint()..color = BjData.slotFill;
    for (var i = 0; i < n * n; i++) {
      var k = 1.0;
      if (s.introStart != null) {
        final d = ((i % n) + (i ~/ n)) * 0.035;
        final p = ((t - s.introStart! - d) / 0.3).clamp(0.0, 1.0);
        k = Curves.easeOutBack.transform(p);
      }
      if (k <= 0) continue;
      canvas.drawRRect(RRect.fromRectAndRadius(scaled(rectOf(i), k), Radius.circular(4 * k)), slot);
    }

    // Placed blocks.
    for (var i = 0; i < n * n; i++) {
      final c = s.board.cells[i];
      if (c == null) continue;
      var color = c;
      if (glowColor != null && glowIdx.contains(i)) color = glowColor;
      if (s.gameOverStart != null) {
        final row = i ~/ n;
        if (t >= s.gameOverStart! + (n - 1 - row) * 0.07) color = BjData.deadBlock;
      }
      var k = 1.0;
      final pop = s.pops[i];
      if (pop != null) {
        final p = ((t - pop) / 0.26).clamp(0.0, 1.0);
        k = 1 + 0.14 * sin(pi * p) * (1 - p * 0.4);
      }
      paintBlock(canvas, scaled(rectOf(i), k), color);
    }

    // Ghost of the dragged piece where it would land.
    if (glowColor != null) {
      for (final i in s.preview) {
        final lit = glowIdx.contains(i);
        paintBlock(canvas, rectOf(i), glowColor, opacity: lit ? 0.95 : 0.45);
      }
    }

    // Glow around lines that this drop would clear.
    if (glowColor != null && !s.glow.isEmpty) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.white.withAlpha((110 + 90 * pulse).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      final edgePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withAlpha((150 + 105 * pulse).round());
      final shine = Paint()..color = Colors.white.withAlpha((25 + 35 * pulse).round());
      for (final r in s.glow.rows) {
        final rect = Rect.fromLTWH(-1, r * pitch - 1, size.width + 2, cell + 2);
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));
        canvas.drawRRect(rr, glowPaint);
        canvas.drawRRect(rr, shine);
        canvas.drawRRect(rr, edgePaint);
      }
      for (final c in s.glow.cols) {
        final rect = Rect.fromLTWH(c * pitch - 1, -1, cell + 2, size.height + 2);
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));
        canvas.drawRRect(rr, glowPaint);
        canvas.drawRRect(rr, shine);
        canvas.drawRRect(rr, edgePaint);
      }
    }

    // Beams along cleared lines.
    for (final b in s.beams) {
      final p = ((t - b.start) / BjBeam.duration).clamp(0.0, 1.0);
      final grow = 2 + 10 * Curves.easeOut.transform(p);
      final rect = b.row
          ? Rect.fromLTWH(0, b.line * pitch + cell / 2 - grow / 2, size.width, grow)
          : Rect.fromLTWH(b.line * pitch + cell / 2 - grow / 2, 0, grow, size.height);
      final alpha = ((1 - p) * 230).round();
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(6), const Radius.circular(12)),
        Paint()
          ..color = b.color.withAlpha(alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = Colors.white.withAlpha(alpha));
    }

    // Cleared cells: flash white → swell → pop.
    for (final b in s.bursts) {
      final p = (t - b.start) / BjBurst.duration;
      final r = rectOf(b.index);
      if (p < 0) {
        paintBlock(canvas, r, b.color);
        continue;
      }
      if (p < 0.3) {
        final q = p / 0.3;
        paintBlock(canvas, scaled(r, 1 + 0.18 * q), Color.lerp(b.color, Colors.white, q)!);
      } else {
        final q = Curves.easeIn.transform(((p - 0.3) / 0.7).clamp(0.0, 1.0));
        canvas.save();
        canvas.translate(r.center.dx, r.center.dy);
        canvas.rotate(q * 0.7);
        canvas.translate(-r.center.dx, -r.center.dy);
        paintBlock(canvas, scaled(r, 1.18 * (1 - q)), Color.lerp(Colors.white, b.color, q)!, opacity: 1 - q * 0.6);
        canvas.restore();
      }
    }

    // Shards.
    for (final p in s.particles) {
      final dt = t - p.start;
      if (dt < 0) continue;
      final pos = p.origin + p.velocity * dt + Offset(0, 0.5 * BjParticle.gravity * dt * dt);
      final a = (1 - dt / p.life).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * dt);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size), Radius.circular(p.size * 0.2)),
        Paint()..color = p.color.withAlpha((a * 255).round()),
      );
      canvas.restore();
    }

    // Score pops.
    for (final f in s.floats) {
      final p = ((t - f.start) / BjFloat.duration).clamp(0.0, 1.0);
      final scale = p < 0.18 ? Curves.easeOutBack.transform(p / 0.18) : 1.0;
      final alpha = p > 0.6 ? 1 - (p - 0.6) / 0.4 : 1.0;
      final style = AppFonts.baloo(fontSize: 26, fontWeight: FontWeight.w800, height: 1);
      final stroke = TextPainter(
        text: TextSpan(
          text: f.text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF5A1530).withAlpha((alpha * 255).round()),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final fill = TextPainter(
        text: TextSpan(text: f.text, style: style.copyWith(color: BjData.gold.withAlpha((alpha * 255).round()))),
        textDirection: TextDirection.ltr,
      )..layout();
      final c = f.pos - Offset(0, 46 * Curves.easeOut.transform(p));
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(scale);
      final o = Offset(-fill.width / 2, -fill.height / 2);
      stroke.paint(canvas, o);
      fill.paint(canvas, o);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant BjBoardPainter old) => true;
}

// ─────────────────────────── Confetti ───────────────────────────

/// Full-screen confetti for a new best score.
class BjConfettiPainter extends CustomPainter {
  final List<BjParticle> pieces;
  final double Function() now;
  BjConfettiPainter(this.pieces, this.now, Listenable repaint) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final t = now();
    for (final p in pieces) {
      final dt = t - p.start;
      if (dt < 0 || dt > p.life) continue;
      final pos = p.origin + p.velocity * dt + Offset(sin(dt * 6 + p.spin) * 14, 0.5 * 420 * dt * dt);
      final a = dt > p.life - 0.5 ? (p.life - dt) / 0.5 : 1.0;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * dt);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
        Paint()..color = p.color.withAlpha((a.clamp(0.0, 1.0) * 255).round()),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant BjConfettiPainter old) => true;
}
