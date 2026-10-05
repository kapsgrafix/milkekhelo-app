import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/feedback/fx.dart';
import '../core/localization/app_language.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/game_header.dart';
import '../core/widgets/screen_bottom_bar.dart';
import 'policy_content.dart';

/// Privacy Policy & Terms page, opened from the home menu. Uses the shared
/// game header (back + language toggle) on the home navy background.
/// The policy text itself is English-only (legal copy); the chrome follows
/// the app language.
class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final isHi = lang == AppLang.hi;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: AppColors.surfaceOnScreen,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: AppColors.screenBackground,
            body: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: GameHeader(
                    title: isHi ? 'नीति' : 'Policy',
                    onBack: () => Navigator.of(context).pop(),
                    soundToggle: false,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      Text('Privacy Policy & Terms', style: AppFonts.baloo(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2)),
                      const SizedBox(height: 4),
                      Text('Last updated: $policyLastUpdated', style: AppText.caption()),
                      const SizedBox(height: 8),
                      for (final s in policySections) _Section(section: s),
                      const _ContactSection(),
                    ],
                  ),
                ),
                const ScreenBottomBar(),
              ],
            ),
          ),
        );
      },
    );
  }
}

TextStyle get _body => AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5, color: const Color(0xE6FFFFFF));
TextStyle get _heading => AppFonts.baloo(fontSize: 17, fontWeight: FontWeight.w800, height: 1.25, color: AppColors.actionPrimary);
TextStyle get _label => AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w700, height: 1.4);

class _Section extends StatelessWidget {
  final PolicySection section;
  const _Section({required this.section});

  @override
  Widget build(BuildContext context) {
    final s = section;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.heading, style: _heading),
          for (final p in s.paragraphs) ...[const SizedBox(height: 8), Text(p, style: _body)],
          if (s.bullets.isNotEmpty) ...[
            if (s.bulletsLabel != null) ...[const SizedBox(height: 10), Text(s.bulletsLabel!, style: _label)],
            const SizedBox(height: 6),
            for (final b in s.bullets) _Bullet(text: b),
          ],
          for (final group in s.moreBullets) ...[
            const SizedBox(height: 10),
            Text(group.$1, style: _label),
            const SizedBox(height: 6),
            for (final b in group.$2) _Bullet(text: b),
          ],
          for (final p in s.after)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Text(p, style: _label.copyWith(fontStyle: FontStyle.italic)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    // "Display name: …" style bullets get a bold lead-in.
    final colon = text.indexOf(':');
    final hasLead = colon > 0 && colon < 20;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 10, left: 2),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: AppColors.brandYellow, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: hasLead
                ? Text.rich(
                    TextSpan(children: [
                      TextSpan(text: text.substring(0, colon + 1), style: _label),
                      TextSpan(text: text.substring(colon + 1), style: _body),
                    ]),
                  )
                : Text(text, style: _body),
          ),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  Future<void> _open(BuildContext context, Uri uri, String copyText) async {
    Fx.tap();
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: copyText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copied $copyText', style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w600))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact Us', style: _heading),
          const SizedBox(height: 8),
          Text('MilkeKhelo', style: _label),
          const SizedBox(height: 8),
          _LinkRow(
            icon: Icons.mail_rounded,
            label: 'Email',
            value: policyEmail,
            onTap: () => _open(context, Uri(scheme: 'mailto', path: policyEmail), policyEmail),
          ),
          _LinkRow(
            icon: Icons.language_rounded,
            label: 'Website',
            value: policyWebsite,
            onTap: () => _open(context, Uri.parse('https://$policyWebsite'), policyWebsite),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _LinkRow({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: '$label $value',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.brandYellow),
              const SizedBox(width: 10),
              Text('$label: ', style: _label),
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: _body.copyWith(color: AppColors.brandYellow, decoration: TextDecoration.underline, decorationColor: AppColors.brandYellow),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
