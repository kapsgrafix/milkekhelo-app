import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The 50px full-width strip at the bottom of every screen. It's the slot
/// for the 320×50 banner ad (centred), and is a few shades darker than the
/// page. It extends under the Android gesture / navigation area, and each
/// screen sets the system navigation bar to the same colour
/// ([AppColors.adStripOn] of its background) so the two read as one band.
///
/// By default it's a translucent dark shade over whatever sits behind it;
/// pass [color] for a solid colour (used over gradient backgrounds).
class ScreenBottomBar extends StatelessWidget {
  final Color? color;
  const ScreenBottomBar({super.key, this.color});

  /// Size of the banner ad that goes inside the strip.
  static const Size adSize = Size(320, 50);

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;
    return Container(
      width: double.infinity,
      height: 50 + inset,
      color: color ?? AppColors.adStripShade,
      alignment: Alignment.topCenter,
      // Banner ad slot — empty until ads are wired up.
      child: SizedBox.fromSize(size: adSize),
    );
  }
}
