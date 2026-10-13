import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/feedback/feedback_settings.dart';
import '../core/feedback/fx.dart';
import '../core/localization/app_language.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/game_header.dart';
import '../core/widgets/screen_bottom_bar.dart';
import '../policy/policy_screen.dart';

/// App settings — Figma "Settings" (MilkeKhelo-Design, node 398:624,
/// 360×720). Opened from the gear on the Home header; replaces the old
/// menu bottom sheet.
///
/// Figma layout (y from frame top):
///   0    Header (Type=Game Title): back · "Settings" · language        56
///   76   PREFERENCES label, then the toggle card (surface, 1px border,
///        radius 16): Music · Sound Effects · Vibration, 62px rows,
///        1px dividers. Same three settings as the old menu sheet.
///   322  ACCOUNT label, helper text, Google + Facebook buttons
///        (48px, radius 16, 12px apart)
///   606  Privacy Policy link + version — pinned 20px above the ad strip
///   670  50px ad strip (#010821)
/// Content padding: 24px sides, 20px top, 28px between sections.
///
/// Google / Facebook sign-in is UI only for now — the buttons show a
/// "coming soon" note until the login code is added.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String appVersion = '1.0';

  static const Color _bgEdge = Color(0xFF000E3A);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.adStripHome,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _bgEdge,
        body: DecoratedBox(
          // Same radial blue glow as Home (Figma: centred at (180, 451.5),
          // radius ≈ 273, fading to deep navy).
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, 451.5 / 360 - 1),
              radius: 273 / 360,
              colors: [Color(0xFF0026A0), Color(0xFF001A6D), Color(0xFF001453), _bgEdge],
              stops: [0, 0.5, 0.75, 1],
            ),
          ),
          child: ValueListenableBuilder<AppLang>(
            valueListenable: AppLanguage.instance,
            builder: (context, lang, _) {
              final t = _SettingsText(lang == AppLang.hi);
              return Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: GameHeader(
                      title: t.title,
                      onBack: () => Navigator.of(context).pop(),
                      soundToggle: false,
                    ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                          sliver: SliverList.list(
                            children: [
                              _SectionLabel(t.preferences),
                              const SizedBox(height: 10),
                              _PreferencesCard(t: t),
                              const SizedBox(height: 28),
                              _SectionLabel(t.account),
                              const SizedBox(height: 10),
                              Text(
                                t.accountHelper,
                                style: AppFonts.baloo(
                                    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 10),
                              _SocialLoginButton.google(label: t.google, onTap: () => _comingSoon(context, t)),
                              const SizedBox(height: 12),
                              _SocialLoginButton.facebook(label: t.facebook, onTap: () => _comingSoon(context, t)),
                            ],
                          ),
                        ),
                        // Footer sits 20px above the ad strip on tall
                        // screens, and scrolls after the content on short ones.
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const SizedBox(height: 32),
                              _FooterLinks(t: t),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const ScreenBottomBar(color: AppColors.adStripHome),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, _SettingsText t) {
    Fx.tap();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(t.comingSoon, style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF16234A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.fromLTRB(24, 0, 24, 66 + MediaQuery.of(context).padding.bottom),
      duration: const Duration(seconds: 2),
    ));
  }
}

// ───────────────────────────── Text ─────────────────────────────

class _SettingsText {
  final bool hi;
  const _SettingsText(this.hi);

  String get title => hi ? 'सेटिंग्स' : 'Settings';
  String get preferences => hi ? 'पसंद' : 'PREFERENCES';
  String get music => hi ? 'संगीत' : 'Music';
  String get musicSub => hi ? 'खेलते समय बैकग्राउंड संगीत' : 'Background music while you play';
  String get sfx => hi ? 'आवाज़ें' : 'Sound Effects';
  String get sfxSub => hi ? 'टैप, पासा, जीत और खेल की आवाज़ें' : 'Taps, dice, wins and game sounds';
  String get vibration => hi ? 'वाइब्रेशन' : 'Vibration';
  String get vibrationSub => hi ? 'टैप और जीत पर हल्का कंपन' : 'Haptic feedback on taps and wins';
  String get account => hi ? 'अकाउंट' : 'ACCOUNT';
  String get accountHelper => hi
      ? 'साइन इन करें ताकि आपकी प्रगति सेव रहे और किसी भी डिवाइस पर खेल सकें'
      : 'Sign in to save your progress and play across devices';
  String get google => hi ? 'Google से जारी रखें' : 'Continue with Google';
  String get facebook => hi ? 'Facebook से जारी रखें' : 'Continue with Facebook';
  String get comingSoon => hi ? 'साइन इन जल्द आ रहा है!' : 'Sign in is coming soon!';
  String get privacy => hi ? 'प्राइवेसी पॉलिसी' : 'Privacy Policy';
  String get version => hi ? 'संस्करण ${SettingsScreen.appVersion}' : 'Version ${SettingsScreen.appVersion}';
}

// ─────────────────────────── Sections ───────────────────────────

/// ExtraBold 11, text/muted, 8% tracking (0.88px).
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.88),
    );
  }
}

/// Toggle card: background/surface, 1px border/default, radius 16, three
/// 62px rows split by 1px border/default dividers.
class _PreferencesCard extends StatelessWidget {
  final _SettingsText t;
  const _PreferencesCard({required this.t});

  @override
  Widget build(BuildContext context) {
    final s = FeedbackSettings.instance;
    Widget divider() => Container(height: 1, color: AppColors.borderDefault);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            _SettingRow(title: t.music, subtitle: t.musicSub, notifier: s.music, onChanged: s.setMusic),
            divider(),
            _SettingRow(title: t.sfx, subtitle: t.sfxSub, notifier: s.sfx, onChanged: s.setSfx),
            divider(),
            _SettingRow(title: t.vibration, subtitle: t.vibrationSub, notifier: s.haptics, onChanged: s.setHaptics),
          ],
        ),
      ),
    );
  }
}

/// One preference row: 12/16 padding, title (Bold 16 / 22) over subtitle
/// (Medium 12 / 16, muted), 12px gap, [SettingsToggle]. The whole row is
/// the tap target.
class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final ValueNotifier<bool> notifier;
  final ValueChanged<bool> onChanged;

  const _SettingRow({required this.title, required this.subtitle, required this.notifier, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, on, _) {
        void flip() {
          onChanged(!on);
          Fx.toggle(); // plays only if sound / vibration is (still) on
        }

        return Semantics(
          toggled: on,
          label: '$title. $subtitle',
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: flip,
              splashColor: const Color(0x14FFFFFF),
              highlightColor: const Color(0x0AFFFFFF),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w700, height: 22 / 16)),
                          Text(subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.baloo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 16 / 12,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ExcludeSemantics(child: SettingsToggle(on: on)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Figma Styleguide "Toggle": 44×26 pill, 3px inset, 20px knob.
///   On:  brand/yellow track, white knob (soft shadow) on the right.
///   Off: background/surface track + 1px border/default, text/muted knob
///        on the left.
class SettingsToggle extends StatelessWidget {
  final bool on;
  const SettingsToggle({super.key, required this.on});

  static const _duration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _duration,
      curve: Curves.easeOut,
      width: 44,
      height: 26,
      decoration: BoxDecoration(
        color: on ? AppColors.brandYellow : AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: on ? AppColors.brandYellow : AppColors.borderDefault),
      ),
      child: AnimatedAlign(
        duration: _duration,
        curve: Curves.easeOut,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2), // 3px inset incl. the 1px border
          child: AnimatedContainer(
            duration: _duration,
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: on ? Colors.white : AppColors.textMuted,
              shape: BoxShape.circle,
              boxShadow: on
                  ? const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))]
                  : const [],
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma Styleguide "Social Login Button": 48px tall, radius 16, 16px side
/// padding, 20px logo, 10px gap, Bold 16 label. Brand colours are
/// third-party guidelines, so they're hard-coded here.
///   Google:   white fill, 4-colour G, text/on-light label.
///   Facebook: #1877F2 fill, white f, white label.
class _SocialLoginButton extends StatefulWidget {
  final String label;
  final String logo;
  final Color fill;
  final Color textColor;
  final VoidCallback onTap;

  const _SocialLoginButton._({
    required this.label,
    required this.logo,
    required this.fill,
    required this.textColor,
    required this.onTap,
  });

  factory _SocialLoginButton.google({required String label, required VoidCallback onTap}) => _SocialLoginButton._(
        label: label,
        logo: 'assets/settings/google_logo.webp',
        fill: Colors.white,
        textColor: AppColors.textOnLight,
        onTap: onTap,
      );

  factory _SocialLoginButton.facebook({required String label, required VoidCallback onTap}) => _SocialLoginButton._(
        label: label,
        logo: 'assets/settings/facebook_logo.webp',
        fill: const Color(0xFF1877F2),
        textColor: Colors.white,
        onTap: onTap,
      );

  @override
  State<_SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<_SocialLoginButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.fill,
              borderRadius: BorderRadius.circular(16),
            ),
            foregroundDecoration: BoxDecoration(
              color: _down ? const Color(0x1F000000) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(widget.logo, width: 20, height: 20, filterQuality: FilterQuality.medium),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w700, color: widget.textColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Privacy Policy (SemiBold 14, underlined) over the version (Medium 11,
/// muted), 4px apart, centred.
class _FooterLinks extends StatelessWidget {
  final _SettingsText t;
  const _FooterLinks({required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          link: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Fx.tap();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PolicyScreen()));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // bigger touch target
              child: Text(
                t.privacy,
                style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w600).copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        Text(t.version, style: AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
      ],
    );
  }
}
