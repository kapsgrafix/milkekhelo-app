import 'package:flutter/material.dart';

import '../core/feedback/feedback_settings.dart';
import '../core/feedback/fx.dart';
import '../core/localization/app_language.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../policy/policy_screen.dart';

/// The home-screen menu: Music / Sound effects / Vibration toggles (saved
/// between launches) and a link to the Policy page.
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final s = FeedbackSettings.instance;
    final isHi = AppLanguage.instance.isHindi;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF16234A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.borderDefault, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(isHi ? 'मेन्यू' : 'Menu', style: AppFonts.baloo(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _ToggleRow(icon: Icons.music_note_rounded, label: isHi ? 'संगीत' : 'Music', notifier: s.music, onChanged: s.setMusic),
          _ToggleRow(icon: Icons.volume_up_rounded, label: isHi ? 'आवाज़ें' : 'Sound effects', notifier: s.sfx, onChanged: s.setSfx),
          _ToggleRow(icon: Icons.vibration_rounded, label: isHi ? 'वाइब्रेशन' : 'Vibration', notifier: s.haptics, onChanged: s.setHaptics),
          const SizedBox(height: 16),
          _NavRow(
            icon: Icons.description_rounded,
            label: isHi ? 'नीति' : 'Policy',
            onTap: () {
              Fx.tap();
              final nav = Navigator.of(context);
              nav.pop(); // close the menu first
              nav.push(MaterialPageRoute(builder: (_) => const PolicyScreen()));
            },
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final ValueNotifier<bool> notifier;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.icon, required this.label, required this.notifier, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, on, _) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: on ? AppColors.brandYellow : AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w700))),
            Switch(
              value: on,
              activeColor: AppColors.textOnLight,
              activeTrackColor: AppColors.brandYellow,
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.surface,
              onChanged: (v) {
                onChanged(v);
                Fx.toggle(); // plays only if sound is (still) on
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.brandYellow),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w700))),
              const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
