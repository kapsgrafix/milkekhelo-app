import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The header every game screen (and the home screen) shares: a back
/// button, an optional help ("?") button, a centered title, and the EN/हिं
/// language toggle on the right. Matches the web app's `.g-header` /
/// `.snl-topbar` grid: three zones, left/center/right.
///
/// This widget is the ONLY place the back/help/lang-toggle visuals are
/// defined — every game imports it instead of re-building its own header,
/// so a chrome-wide tweak (e.g. button size) only ever needs one edit.
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderIconButton(icon: Icons.arrow_back, onTap: onBack),
                if (onHelp != null) ...[
                  const SizedBox(width: 10),
                  _HeaderIconButton(label: '?', onTap: onHelp),
                ],
              ],
            ),
          ),
          Text(
            title,
            style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: const _LanguageToggle(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;

  const _HeaderIconButton({this.icon, this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.headerIconBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.headerIconBorder),
        ),
        child: icon != null
            ? Icon(icon, size: 17, color: Colors.white)
            : Text(
                label ?? '',
                style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        return Container(
          height: 32,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.langToggleBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.langToggleBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LangBtn(label: 'EN', active: lang == AppLang.en, onTap: () => AppLanguage.instance.set(AppLang.en)),
              _LangBtn(label: 'हिं', active: lang == AppLang.hi, onTap: () => AppLanguage.instance.set(AppLang.hi)),
            ],
          ),
        );
      },
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LangBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.langActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppFonts.baloo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.langActiveText : AppColors.langInactiveText,
          ),
        ),
      ),
    );
  }
}
