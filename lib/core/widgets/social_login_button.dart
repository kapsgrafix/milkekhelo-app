import 'package:flutter/material.dart';

import '../feedback/fx.dart';
import '../localization/app_language.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Figma Styleguide "Social Login Button": 48px tall, radius 16, 16px side
/// padding, 20px logo, 10px gap, Bold 16 label. Brand colours follow the
/// third-party guidelines, so they're hard-coded here.
///   Google:   white fill, 4-colour G, text/on-light label.
///   Facebook: #1877F2 fill, white f, white label.
/// Used on the Settings screen and the in-game Save Progress overlay.
/// Labels follow the app language (EN / HI).
class SocialLoginButton extends StatefulWidget {
  final String labelEn;
  final String labelHi;
  final String logo;
  final Color fill;
  final Color textColor;
  final VoidCallback onTap;

  const SocialLoginButton._({
    required this.labelEn,
    required this.labelHi,
    required this.logo,
    required this.fill,
    required this.textColor,
    required this.onTap,
  });

  /// [compact]: just the brand name ("Google"), for two buttons side by side.
  factory SocialLoginButton.google({required VoidCallback onTap, bool compact = false}) => SocialLoginButton._(
        labelEn: compact ? 'Google' : 'Continue with Google',
        labelHi: compact ? 'Google' : 'Google से जारी रखें',
        logo: 'assets/settings/google_logo.webp',
        fill: Colors.white,
        textColor: AppColors.textOnLight,
        onTap: onTap,
      );

  factory SocialLoginButton.facebook({required VoidCallback onTap, bool compact = false}) => SocialLoginButton._(
        labelEn: compact ? 'Facebook' : 'Continue with Facebook',
        labelHi: compact ? 'Facebook' : 'Facebook से जारी रखें',
        logo: 'assets/settings/facebook_logo.webp',
        fill: const Color(0xFF1877F2),
        textColor: Colors.white,
        onTap: onTap,
      );

  @override
  State<SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<SocialLoginButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final label = AppLanguage.instance.isHindi ? widget.labelHi : widget.labelEn;
    return Semantics(
      button: true,
      label: label,
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
                    label,
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

/// Google / Facebook sign-in isn't wired up yet — the buttons show this
/// short note, floating just above the 50px ad strip.
void showSignInComingSoon(BuildContext context) {
  Fx.tap();
  final hi = AppLanguage.instance.isHindi;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(
      hi ? 'साइन इन जल्द आ रहा है!' : 'Sign in is coming soon!',
      style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF16234A),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: EdgeInsets.fromLTRB(24, 0, 24, 66 + MediaQuery.of(context).padding.bottom),
    duration: const Duration(seconds: 2),
  ));
}
