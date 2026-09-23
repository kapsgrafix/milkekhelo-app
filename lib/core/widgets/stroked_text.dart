import 'package:flutter/material.dart';

/// Replicates the web app's `-webkit-text-stroke` + `paint-order:stroke fill`
/// cartoon-outline text treatment (used on home-screen game tile names and
/// Memory Grid level-card names): an outline layer painted behind a solid
/// fill layer, both using the exact same layout so they sit perfectly on
/// top of each other.
class StrokedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color strokeColor;
  final double strokeWidth;
  final TextAlign textAlign;

  const StrokedText(
    this.text, {
    super.key,
    required this.style,
    this.strokeColor = const Color(0x33000000),
    this.strokeWidth = 4,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: textAlign,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        Text(text, textAlign: textAlign, style: style),
      ],
    );
  }
}
