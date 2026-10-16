import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/auth/account_ui.dart';
import '../core/auth/auth_service.dart';
import '../core/feedback/feedback_settings.dart';
import '../core/feedback/fx.dart';
import '../core/localization/app_language.dart';
import '../core/saves/game_saves.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/game_header.dart';
import '../core/widgets/screen_bottom_bar.dart';
import '../core/widgets/social_login_button.dart';
import '../policy/policy_screen.dart';

/// App settings — Figma "Settings" (MilkeKhelo-Design, node 398:624,
/// 360×720). Opened from the gear on the Home header; replaces the old
/// menu bottom sheet.
///
/// Figma layout (Settings section 461:2045, Oct 15 2026), y from top:
///   0    Header (Type=Game Title): back · "Settings" · language        56
///   76   ACCOUNT label, then — signed out: helper text + Google /
///        Facebook buttons (48px, radius 16, 12px apart); signed in: the
///        profile card (avatar + provider badge · name · "⋮" menu)
///   +28  PREFERENCES label, then the toggle card (surface, 1px border,
///        radius 16): Music · Sound Effects · Vibration, 62px rows
///   606  Privacy Policy link + version — pinned 20px above the ad strip
///   670  50px ad strip (#010821)
/// Content padding: 24px sides, 20px top, 28px between sections.
///
/// Account: signed out → helper text + Google / Facebook buttons;
/// signed in → profile card (photo, name, email, provider) + Sign out.
/// (Facebook shows "coming soon" until its app is set up.)
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
                              // Figma (Oct 15): Account first, then Preferences.
                              _SectionLabel(t.account),
                              const SizedBox(height: 10),
                              ValueListenableBuilder<AppUser?>(
                                valueListenable: AuthService.instance.user,
                                builder: (context, user, _) => user != null
                                    ? _ProfileCard(user: user, t: t)
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            t.accountHelper,
                                            style: AppFonts.baloo(
                                                fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                                          ),
                                          const SizedBox(height: 10),
                                          SocialLoginButton.google(
                                              onTap: () => signInFromButton(context, SignInProvider.google)),
                                          // Facebook sign-in returns once the app is on the Play Store.
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 28),
                              _SectionLabel(t.preferences),
                              const SizedBox(height: 10),
                              _PreferencesCard(t: t),
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
  String get signedInWith => hi ? 'से साइन इन' : 'Signed in with';
  String get accountHelper => hi
      ? 'साइन इन करें ताकि आपकी प्रगति सेव रहे और किसी भी डिवाइस पर खेल सकें'
      : 'Sign in to save your progress and play across devices';
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

/// Figma "Profile Card" (455:762): surface, 1px border, radius 16,
/// padding 16, gap 14 — 56px avatar with the provider badge · name
/// (ExtraBold 18/24) over "Signed in with Google" (Medium 12/16, muted),
/// 4px apart · 32px "⋮" button that opens the account menu
/// (Log out / Delete profile), each with its confirmation dialog.
class _ProfileCard extends StatelessWidget {
  final AppUser user;
  final _SettingsText t;
  const _ProfileCard({required this.user, required this.t});

  @override
  Widget build(BuildContext context) {
    final providerName = user.provider == SignInProvider.google ? 'Google' : 'Facebook';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          UserAvatar(user: user, size: 56, badge: AvatarBadge.provider),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isEmpty ? user.email : user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.baloo(fontSize: 18, fontWeight: FontWeight.w800, height: 24 / 18),
                ),
                const SizedBox(height: 4),
                Text(
                  t.hi ? '$providerName ${t.signedInWith}' : '${t.signedInWith} $providerName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w500, height: 16 / 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const _MoreButton(),
        ],
      ),
    );
  }
}

/// 32px "⋮" button; while the menu is open it shows the surface chip
/// (Figma "Settings - Account Menu").
class _MoreButton extends StatefulWidget {
  const _MoreButton();

  @override
  State<_MoreButton> createState() => _MoreButtonState();
}

class _MoreButtonState extends State<_MoreButton> {
  bool _open = false;

  Future<void> _openMenu() async {
    Fx.tap();
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    setState(() => _open = true);
    final action = await showAccountMenu(context, anchor: anchor);
    if (!mounted) return;
    setState(() => _open = false);
    switch (action) {
      case AccountMenuAction.logOut:
        if (await showLogoutConfirm(context)) {
          await AuthService.instance.signOut();
          if (mounted) showAppToast(context, AppLanguage.instance.isHindi ? 'लॉग आउट हो गया' : 'Logged out');
        }
      case AccountMenuAction.delete:
        if (await showDeleteConfirm(context)) {
          final hi = AppLanguage.instance.isHindi;
          try {
            final uid = AuthService.instance.user.value?.uid;
            await AuthService.instance.deleteAccount();
            GameSaves.instance.forgetLocal(uid);
            if (mounted) showAppToast(context, hi ? 'प्रोफ़ाइल डिलीट हो गई' : 'Profile deleted');
          } on AuthException catch (e) {
            if (mounted && !e.cancelled) {
              showAppToast(
                context,
                (hi ? 'प्रोफ़ाइल डिलीट नहीं हो सकी। ' : "Couldn't delete the profile. ") +
                    (e.code == 'network' ? (hi ? 'इंटरनेट देखें।' : 'Check your internet.') : '(${e.code})'),
                duration: const Duration(seconds: 4),
              );
            }
          }
        }
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLanguage.instance.isHindi ? 'अकाउंट विकल्प' : 'Account options',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openMenu,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _open ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _open ? AppColors.borderDefault : Colors.transparent),
          ),
          child: const Icon(Icons.more_vert_rounded, size: 22, color: AppColors.textPrimary),
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
