import 'package:flutter/material.dart';

/// Body of every game's L1 "choose a mode" screen (Snakes & Ladders,
/// Memory Grid, Who's That, and future games with the same structure).
///
/// The hero art and the mode cards form ONE unit — hero · 48px · cards —
/// and that unit is centred vertically in the space between the header and
/// the bottom bar, so it sits right on any phone height. On a screen too
/// short to fit it, the unit scrolls instead (24px breathing room top and
/// bottom, 24px side margins).
class GameLandingBody extends StatelessWidget {
  final Widget hero;
  final List<Widget> variants;

  /// Space between the hero art and the first mode card.
  static const double heroGap = 48;

  const GameLandingBody({super.key, required this.hero, required this.variants});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  hero,
                  const SizedBox(height: heroGap),
                  ...variants,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
