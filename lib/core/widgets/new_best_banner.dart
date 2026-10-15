import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// "New Best Streak!" / "New Best Score!" — a glossy 3D gold title that
/// pops in over the board when the player beats their record mid-game,
/// with the new number underneath. The game fires confetti + the win sound
/// alongside it, and removes the banner after [NewBestBanner.duration].
///
/// Give it a fresh key each time so the pop animation replays.
class NewBestBanner extends StatelessWidget {
  static const Duration duration = Duration(milliseconds: 1700);

  final String title;
  final int value;

  const NewBestBanner({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: duration,
          builder: (context, t, child) {
            // Pop in (elastic), hold, then lift and fade out at the end.
            final popIn = Curves.elasticOut.transform(min(1.0, t / 0.35));
            final out = t < 0.82 ? 0.0 : (t - 0.82) / 0.18;
            final scale = 0.4 + 0.6 * popIn + 0.06 * out;
            final wobble = sin(t * pi * 3) * 0.03 * (1 - t);
            return Opacity(
              opacity: (1 - out).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -18 * out),
                child: Transform.rotate(angle: -0.04 + wobble, child: Transform.scale(scale: scale, child: child)),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: Glossy3dText(title, fontSize: 40)),
                const SizedBox(height: 2),
                Glossy3dText('$value', fontSize: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chunky 3D gold lettering: a stacked dark-orange extrusion, a dark
/// outline, a yellow→orange gradient face and a glossy highlight across
/// the top half — like a game title.
class Glossy3dText extends StatelessWidget {
  final String text;
  final double fontSize;

  const Glossy3dText(this.text, {super.key, this.fontSize = 40});

  static const _faceTop = Color(0xFFFFF4B8);
  static const _faceMid = Color(0xFFFFC53D); // brand/yellow
  static const _faceBottom = Color(0xFFFF8A00);
  static const _extrude = Color(0xFFB45309);
  static const _outline = Color(0xFF4A2205);

  @override
  Widget build(BuildContext context) {
    final base = AppFonts.baloo(fontSize: fontSize, fontWeight: FontWeight.w800, height: 1.1);
    final depth = (fontSize * 0.12).clamp(3.0, 8.0);
    final stroke = fontSize * 0.14;

    Text plain(Color c) => Text(text, style: base.copyWith(color: c));
    Text outlined(Color c, double w) => Text(
          text,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = w
              ..strokeJoin = StrokeJoin.round
              ..color = c,
          ),
        );

    return Stack(
      children: [
        // Soft drop shadow under everything.
        Transform.translate(
          offset: Offset(0, depth + 4),
          child: Text(text, style: base.copyWith(color: Colors.transparent, shadows: const [
            Shadow(color: Color(0x88000000), blurRadius: 14),
          ])),
        ),
        // Extrusion: the outline repeated downwards in the dark colour.
        for (var i = depth.round(); i >= 1; i--)
          Transform.translate(offset: Offset(0, i.toDouble()), child: outlined(_outline, stroke)),
        for (var i = depth.round(); i >= 1; i--)
          Transform.translate(offset: Offset(0, i.toDouble()), child: plain(_extrude)),
        // Outline of the face.
        outlined(_outline, stroke),
        // Gradient face.
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_faceTop, _faceMid, _faceBottom],
            stops: [0, 0.45, 1],
          ).createShader(r),
          child: plain(Colors.white),
        ),
        // Gloss: a bright band over the top half of the letters.
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xB3FFFFFF), Color(0x33FFFFFF), Color(0x00FFFFFF), Color(0x00FFFFFF)],
            stops: [0, 0.42, 0.46, 1],
          ).createShader(r),
          child: plain(Colors.white),
        ),
      ],
    );
  }
}
