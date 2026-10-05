import 'package:flutter/material.dart';

import '../feedback/feedback_settings.dart';
import '../feedback/fx.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'language_toggle.dart';

/// Figma "Header / Type=Game Title" — shared by every game screen:
///   12px padding · left slot (Go Back · Sound · How To, 8px gaps) ·
///   centred title (label/card, usually empty) · Language Toggle on the right.
///
/// The Sound button (shown when [soundToggle] is true — every game screen)
/// switches music, sound effects and vibration off together, or back on.
/// It shares state with the Menu sheet's three toggles.
///
/// This is the ONLY place the header chrome is defined.
class GameHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onHelp;
  final bool soundToggle;

  const GameHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.onHelp,
    this.soundToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Left slot is at least as wide as the language toggle (72) so a
          // title stays optically centred.
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeaderIconButton(
                  semanticLabel: 'Back',
                  onTap: onBack,
                  child: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textPrimary),
                ),
                if (soundToggle) ...[
                  const SizedBox(width: 8),
                  const _SoundButton(),
                ],
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

/// 32×32 header button: speaker on / speaker muted. "On" = any of music,
/// sound effects or vibration enabled; a tap turns all three off, or all
/// three back on.
class _SoundButton extends StatelessWidget {
  const _SoundButton();

  @override
  Widget build(BuildContext context) {
    final fs = FeedbackSettings.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([fs.music, fs.sfx, fs.haptics]),
      builder: (context, _) {
        final on = fs.music.value || fs.sfx.value || fs.haptics.value;
        return HeaderIconButton(
          semanticLabel: on ? 'Sound on — tap to mute' : 'Sound off — tap to unmute',
          onTap: () {
            fs.setMusic(!on);
            fs.setSfx(!on);
            fs.setHaptics(!on);
            if (!on) Fx.toggle(); // confirm it's back on
          },
          child: Icon(
            on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            size: 16,
            color: on ? AppColors.textPrimary : AppColors.textMuted,
          ),
        );
      },
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
        onTap: onTap == null
            ? null
            : () {
                Fx.tap();
                onTap!();
              },
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
