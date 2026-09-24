import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'language_toggle.dart';

/// Figma "Header / Type=Game Title" — shared by every game screen:
///   12px padding · Left slot 72px (Go Back + How To, 8px gap) ·
///   centred title (label/card) · 72px Language Toggle on the right.
///
/// The left slot is always 72px wide (same as the toggle) so the title stays
/// optically centred even when a screen has no help button.
///
/// This is the ONLY place the header chrome is defined.
class GameHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onHelp;

  const GameHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Row(
              children: [
                HeaderIconButton(
                  semanticLabel: 'Back',
                  onTap: onBack,
                  child: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textPrimary),
                ),
                if (onHelp != null) ...[
                  const SizedBox(width: 8),
                  HeaderIconButton(
                    semanticLabel: 'How to play',
                    onTap: onHelp,
                    child: Text('?', style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w800, height: 1.0)),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.labelCard(),
            ),
          ),
          const LanguageToggle(),
        ],
      ),
    );
  }
}

/// Figma "Icon/Go Back", "Icon/How To", "Icon/Menu": 32×32 square,
/// background/surface fill, border/default stroke, radius 12, 16px glyph.
class HeaderIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const HeaderIconButton({super.key, required this.child, this.onTap, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: child,
        ),
      ),
    );
  }
}
