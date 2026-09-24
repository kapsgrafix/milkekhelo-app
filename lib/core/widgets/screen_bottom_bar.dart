import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Figma: the 50px full-width background/surface strip at the bottom of
/// every frame. Extends under the Android gesture / navigation area.
class ScreenBottomBar extends StatelessWidget {
  const ScreenBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;
    return Container(width: double.infinity, height: 50 + inset, color: AppColors.surface);
  }
}
