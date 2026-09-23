import 'package:flutter/material.dart';

/// The "3D pressed button" card look used everywhere in the web app's
/// design system (home screen game tiles, Memory Grid level cards, the
/// duel card, and every primary CTA button): a flat gradient face sitting
/// on top of a solid-color shadow "ledge", which shrinks and the face
/// slides down when pressed — CSS: `box-shadow:0 6px 0 0 var(--cs)` ->
/// `:active{transform:translateY(3px);box-shadow:0 3px 0 0 var(--cs)}`.
///
/// IMPORTANT: this widget needs a BOUNDED height that already includes
/// room for the shadow ledge, i.e. wrap it in a `SizedBox`/`AspectRatio`
/// sized to `contentHeight + shadowOffset` — not just `contentHeight`.
class PressableCard extends StatefulWidget {
  final Widget child;
  final Color topColor;
  final Color? bottomColor;
  final Color shadowColor;
  final double borderRadius;
  final double shadowOffset;
  final double pressedOffset;
  final VoidCallback? onTap;

  const PressableCard({
    super.key,
    required this.child,
    required this.topColor,
    this.bottomColor,
    required this.shadowColor,
    this.borderRadius = 24,
    this.shadowOffset = 6,
    this.pressedOffset = 3,
    this.onTap,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onTap == null) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final total = constraints.maxHeight;
          final faceHeight = (total - widget.shadowOffset).clamp(0, total).toDouble();
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: faceHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: widget.shadowColor, borderRadius: radius),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                top: _pressed ? widget.pressedOffset : 0,
                left: 0,
                right: 0,
                height: faceHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.bottomColor == null ? widget.topColor : null,
                    gradient: widget.bottomColor != null
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [widget.topColor, widget.bottomColor!],
                          )
                        : null,
                    borderRadius: radius,
                  ),
                  child: widget.child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
