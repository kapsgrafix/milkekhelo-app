import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Figma "Language Toggle": 72×32, 4px inset, background/surface fill,
/// border/default stroke, radius 12. Active segment: brand/yellow, radius 8,
/// text/on-light. Inactive: transparent, text/muted. Labels Bold 15.
///
/// Used by the home header and every game header — one definition only.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final isHi = lang == AppLang.hi;
        return Container(
          width: 72,
          height: 32,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              _Segment(label: 'EN', active: !isHi, onTap: () => AppLanguage.instance.set(AppLang.en)),
              _Segment(label: 'हिं', active: isHi, onTap: () => AppLanguage.instance.set(AppLang.hi)),
            ],
          ),
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Segment({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label == 'EN' ? 'English' : 'हिंदी',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: active ? AppColors.brandYellow : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: AppText.toggle(color: active ? AppColors.textOnLight : AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
