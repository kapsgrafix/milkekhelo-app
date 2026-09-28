import 'dart:async';

import 'package:flutter/material.dart';

/// Shared idle "pulse" for game cards (home screen, Memory Grid landing).
///
/// Subtle "lub-dub" heartbeat: the card swells to 103% and back, then a
/// smaller 102% beat, then rests — one cycle every 2.6 s. Cards start
/// [delay] apart so the beat ripples across the grid. Off when the phone's
/// "remove animations" accessibility setting is on.
class Heartbeat extends StatefulWidget {
  final Duration delay;
  final Widget child;
  const Heartbeat({super.key, this.delay = Duration.zero, required this.child});

  @override
  State<Heartbeat> createState() => _HeartbeatState();
}

class _HeartbeatState extends State<Heartbeat> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  Timer? _start;

  static final Animatable<double> _beat = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.03).chain(CurveTween(curve: Curves.easeOut)), weight: 7),
    TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 8),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.02).chain(CurveTween(curve: Curves.easeOut)), weight: 6),
    TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 12),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 67),
  ]);

  @override
  void initState() {
    super.initState();
    _start = Timer(widget.delay + const Duration(milliseconds: 600), () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _start?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.scale(scale: _beat.evaluate(_c), child: child),
    );
  }
}
