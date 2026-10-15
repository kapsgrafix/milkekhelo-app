import 'package:flutter/material.dart';

import '../feedback/fx.dart';
import '../localization/app_language.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/chunky_button.dart';
import 'auth_service.dart';

/// Shared account UI from the Figma "Settings" section (461:2045):
/// avatar, Welcome dialog, Log out / Delete profile confirmations and the
/// profile "⋮" menu.

const Color _dialogBg = Color(0xFF0F1A3D); // background/screen
const Color _moduleRed = Color(0xFFE03D3D); // module/red
const Color _moduleGreen = Color(0xFF33C481); // module/green

// ───────────────────────────── Avatar ─────────────────────────────

enum AvatarBadge { none, provider, check }

/// Round photo (or the first letter on brand/yellow) with an optional
/// corner badge: the sign-in provider (white disc with the G / f logo,
/// Figma "Provider Badge") or a green check (Welcome dialog).
class UserAvatar extends StatelessWidget {
  final AppUser user;
  final double size;
  final AvatarBadge badge;

  const UserAvatar({super.key, required this.user, this.size = 56, this.badge = AvatarBadge.none});

  @override
  Widget build(BuildContext context) {
    final initial = (user.name.trim().isNotEmpty
            ? user.name.trim()[0]
            : (user.email.isNotEmpty ? user.email[0] : '?'))
        .toUpperCase();
    Widget letter() => Container(
          color: AppColors.brandYellow,
          alignment: Alignment.center,
          child: Text(
            initial,
            style: AppFonts.baloo(fontSize: size * 0.43, fontWeight: FontWeight.w800, color: AppColors.textOnLight),
          ),
        );
    // Figma: provider badge 22 on a 56 avatar (at 36,36); check badge 26
    // on a 72 avatar (at 48,48) — both 2–3px rings in the card colour.
    final badgeSize = badge == AvatarBadge.check ? size * 26 / 72 : size * 22 / 56;
    final ring = badge == AvatarBadge.check ? 3.0 : 2.0;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: SizedBox.square(
              dimension: size,
              child: user.photoUrl.isEmpty
                  ? letter()
                  : Image.network(user.photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => letter()),
            ),
          ),
          if (badge != AvatarBadge.none)
            Positioned(
              left: size - badgeSize + (badge == AvatarBadge.check ? 2 : 2),
              top: size - badgeSize + 2,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge == AvatarBadge.check ? _moduleGreen : Colors.white,
                  border: Border.all(color: _dialogBg, width: ring),
                ),
                child: badge == AvatarBadge.check
                    ? Icon(Icons.check_rounded, size: badgeSize * 0.6, color: Colors.white)
                    : Image.asset(
                        user.provider == SignInProvider.google
                            ? 'assets/settings/google_logo.webp'
                            : 'assets/settings/facebook_logo_blue.webp',
                        width: badgeSize * 13 / 22,
                        height: badgeSize * 13 / 22,
                        errorBuilder: (_, __, ___) => Icon(
                          user.provider == SignInProvider.google ? Icons.g_mobiledata_rounded : Icons.facebook,
                          size: badgeSize * 0.7,
                          color: const Color(0xFF1877F2),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Dialog shell ─────────────────────────────

/// Figma dialog card: 312 wide, background/screen fill, 1px border/default,
/// radius 28, shadow 0 16 40 black 45%, padding 28 top / 20 sides+bottom,
/// 20px gaps, centred on a black 60% scrim.
Future<T?> _showCardDialog<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'Close',
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, _, __) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 312),
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            decoration: BoxDecoration(
              color: _dialogBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.borderDefault),
              boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 40, offset: Offset(0, 16))],
            ),
            child: SingleChildScrollView(child: builder(context)),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

/// 56px round icon badge: a soft tint of [color] with the icon in [color].
Widget _iconBadge(IconData icon, Color color) => Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.16)),
      child: Icon(icon, size: 26, color: color),
    );

Widget _title(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: AppFonts.baloo(fontSize: 24, fontWeight: FontWeight.w800),
    );

Widget _body(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4, color: AppColors.textMuted),
    );

/// Two-button confirmation (Figma "Log Out Dialog" / "Delete Profile
/// Dialog"): icon badge · title · body · Primary + Secondary buttons.
Future<bool> _confirm(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String body,
  required String confirm,
  required String cancel,
}) async {
  final result = await _showCardDialog<bool>(
    context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconBadge(icon, iconColor),
        const SizedBox(height: 20),
        _title(title),
        const SizedBox(height: 8),
        _body(body),
        const SizedBox(height: 20),
        ChunkyButton(label: confirm, width: double.infinity, onTap: () => Navigator.of(context).pop(true)),
        const SizedBox(height: 12),
        ChunkyButton(
          label: cancel,
          width: double.infinity,
          style: ChunkyButtonStyle.secondary,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
  );
  return result == true;
}

Future<bool> showLogoutConfirm(BuildContext context) {
  final hi = AppLanguage.instance.isHindi;
  return _confirm(
    context,
    icon: Icons.logout_rounded,
    iconColor: AppColors.brandYellow,
    title: hi ? 'लॉग आउट करें?' : 'Log out?',
    body: hi
        ? 'आपकी प्रगति सेव होना बंद हो जाएगी, और आपके टॉप स्कोर शायद न रहें।'
        : 'Your progress will stop saving, and your top scores might not be kept.',
    confirm: hi ? 'लॉग आउट' : 'Log out',
    cancel: hi ? 'लॉग इन रहें' : 'Stay logged in',
  );
}

Future<bool> showDeleteConfirm(BuildContext context) {
  final hi = AppLanguage.instance.isHindi;
  return _confirm(
    context,
    icon: Icons.delete_outline_rounded,
    iconColor: _moduleRed,
    title: hi ? 'प्रोफ़ाइल डिलीट करें?' : 'Delete profile?',
    body: hi
        ? 'आपकी सारी प्रगति और स्कोर हमेशा के लिए मिट जाएंगे। इसे वापस नहीं लाया जा सकता।'
        : "All your progress and scores will be gone for good. This can't be undone.",
    confirm: hi ? 'प्रोफ़ाइल डिलीट करें' : 'Delete profile',
    cancel: hi ? 'प्रोफ़ाइल रखें' : 'Keep my profile',
  );
}

// ───────────────────────────── Welcome ─────────────────────────────

/// Figma "Welcome Dialog" (460:828): 72px avatar with a green check,
/// "Welcome, {first name}!", three perks and "Get started".
Future<void> showWelcomeDialog(BuildContext context, AppUser user) {
  final hi = AppLanguage.instance.isHindi;
  final first = user.name.trim().split(' ').first;
  Widget perk(IconData icon, String title, String sub) => Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandYellow.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.brandYellow),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w700, height: 20 / 15)),
                Text(sub,
                    style: AppFonts.baloo(
                        fontSize: 12, fontWeight: FontWeight.w500, height: 16 / 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      );
  return _showCardDialog<void>(
    context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(user: user, size: 72, badge: AvatarBadge.check),
        const SizedBox(height: 20),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: _title(first.isEmpty ? (hi ? 'स्वागत है!' : 'Welcome!') : (hi ? 'स्वागत है, $first!' : 'Welcome, $first!')),
        ),
        const SizedBox(height: 6),
        _body(hi ? 'सब तैयार है। आपको यह मिलेगा:' : "You're all set. Here's what you get:"),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              perk(Icons.cloud_done_outlined, hi ? 'प्रगति अपने-आप सेव' : 'Progress saved automatically',
                  hi ? 'हर गेम, हर चाल' : 'Every game, every move'),
              const SizedBox(height: 14),
              perk(Icons.emoji_events_outlined, hi ? 'टॉप स्कोर सुरक्षित' : 'Top scores kept safe',
                  hi ? 'आपके बेस्ट स्कोर आपकी प्रोफ़ाइल पर रहेंगे' : 'Your best runs stay on your profile'),
              const SizedBox(height: 14),
              perk(Icons.smartphone_rounded, hi ? 'किसी भी फ़ोन पर खेलें' : 'Play on any phone',
                  hi ? 'वहीं से शुरू करें जहाँ छोड़ा था' : 'Pick up right where you left off'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ChunkyButton(
          label: hi ? 'शुरू करें' : 'Get started',
          width: double.infinity,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

// ───────────────────────────── Account menu ─────────────────────────────

enum AccountMenuAction { logOut, delete }

/// Figma "Account Dropdown" (457:794): 196 wide, #16234A, 1px border,
/// radius 14, 6px vertical padding, shadow 0 12 28 black 50%; two 48px
/// rows (18px icon · 12 · Bold 15) split by a divider. Opens 10px under
/// the "⋮" button, right-aligned to it.
Future<AccountMenuAction?> showAccountMenu(BuildContext context, {required Rect anchor}) {
  final hi = AppLanguage.instance.isHindi;
  return showGeneralDialog<AccountMenuAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, _, __) {
      final screen = MediaQuery.sizeOf(context);
      const width = 196.0;
      final left = (anchor.right + 3 - width).clamp(8.0, screen.width - width - 8);
      Widget item(IconData icon, String label, Color color, AccountMenuAction action) => InkWell(
            onTap: () {
              Fx.tap();
              Navigator.of(context).pop(action);
            },
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 12),
                    Text(label, style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
                  ],
                ),
              ),
            ),
          );
      return Stack(
        children: [
          Positioned(
            left: left,
            top: anchor.bottom + 10,
            width: width,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFF16234A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderDefault),
                  boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 28, offset: Offset(0, 12))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    item(Icons.logout_rounded, hi ? 'लॉग आउट' : 'Log out', AppColors.textPrimary, AccountMenuAction.logOut),
                    Container(height: 1, color: AppColors.borderDefault),
                    item(Icons.delete_outline_rounded, hi ? 'प्रोफ़ाइल डिलीट करें' : 'Delete profile', _moduleRed,
                        AccountMenuAction.delete),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        alignment: Alignment.topRight,
        scale: Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
    ),
  );
}
