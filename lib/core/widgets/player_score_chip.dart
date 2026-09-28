import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Player colours used by every 2-player game (Figma yellow/500, coral/500).
class PlayerColors {
  PlayerColors._();
  static const Color yellowBorder = Color(0xFFFFC53D);
  static const Color yellowSwatch = Color(0xFFFBBF24);
  static const Color redBorder = Color(0xFFFF7A45);
  static const Color redSwatch = Color(0xFFEF4444);
}

/// Figma "Score Section / 2 Player" chip — shared by Snakes & Ladders and
/// Memory Grid duel: background/surface fill, 2px border in the player's
/// colour, radius 16, 16/10 padding, 32px avatar, 12px gap.
/// Name Bold 12/13 · score Bold 18/20 + unit Medium 11/12 (text/muted).
/// The player whose turn it isn't is shown at 70% opacity.
class PlayerScoreChip extends StatelessWidget {
  final String name;
  final int score;
  final String unit;
  final Color swatch;
  final Color border;
  final bool active;

  const PlayerScoreChip({
    super.key,
    required this.name,
    required this.score,
    required this.unit,
    required this.swatch,
    required this.border,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0.7,
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: swatch,
                border: Border.all(color: const Color(0xD9FFFFFF), width: 3),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w700, height: 13 / 12)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$score', style: AppFonts.baloo(fontSize: 18, fontWeight: FontWeight.w700, height: 20 / 18)),
                      const SizedBox(width: 4),
                      Text(unit,
                          style: AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w500, height: 12 / 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
