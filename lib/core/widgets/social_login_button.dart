import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
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
  final SignInProvider provider;

  const SocialLoginButton._({
    required this.provider,
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
        provider: SignInProvider.google,
        logo: 'assets/settings/google_logo.webp',
        fill: Colors.white,
        textColor: AppColors.textOnLight,
        onTap: onTap,
      );

  factory SocialLoginButton.facebook({required VoidCallback onTap, bool compact = false}) => SocialLoginButton._(
        labelEn: compact ? 'Facebook' : 'Continue with Facebook',
        labelHi: compact ? 'Facebook' : 'Facebook से जारी रखें',
        provider: SignInProvider.facebook,
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
                // While a sign-in is running, the logo becomes a small spinner.
                ValueListenableBuilder<bool>(
                  valueListenable: AuthService.instance.busy,
                  builder: (context, busy, _) => busy && widget.provider == SignInProvider.google
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: widget.textColor),
                        )
                      : Image.asset(widget.logo, width: 20, height: 20, filterQuality: FilterQuality.medium),
                ),
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

/// A short floating note just above the 50px ad strip.
void showAppToast(BuildContext context, String text, {Duration duration = const Duration(seconds: 2)}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(text, style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w600)),
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF16234A),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: EdgeInsets.fromLTRB(24, 0, 24, 66 + MediaQuery.of(context).padding.bottom),
    duration: duration,
  ));
}

/// For sign-in methods that aren't wired up yet (Facebook, for now).
void showSignInComingSoon(BuildContext context) {
  Fx.tap();
  final hi = AppLanguage.instance.isHindi;
  showAppToast(context, hi ? 'Facebook साइन इन जल्द आ रहा है!' : 'Facebook sign in is coming soon!');
}

/// Runs a sign-in from any button (Settings, Save Progress overlay) and
/// shows the result as a toast. Returns true when the player is signed in.
/// Pass a [toastContext] that stays on screen (e.g. the game screen) when
/// the button lives in a dialog that may close.
Future<bool> signInFromButton(BuildContext context, SignInProvider provider, {BuildContext? toastContext}) async {
  if (provider == SignInProvider.facebook) {
    showSignInComingSoon(context);
    return false;
  }
  Fx.tap();
  final hi = AppLanguage.instance.isHindi;
  final target = toastContext ?? context;
  try {
    final u = await AuthService.instance.signInWithGoogle();
    final first = u.name.trim().split(' ').first;
    if (target.mounted) {
      Fx.toggle();
      showAppToast(target, hi ? 'साइन इन हो गया${first.isEmpty ? '' : ', $first'}! 🎉' : 'Signed in${first.isEmpty ? '' : ' as $first'}! 🎉');
    }
    return true;
  } on AuthException catch (e) {
    if (e.cancelled || e.code == 'busy') return false;
    debugPrint('Sign-in failed: $e');
    if (target.mounted) {
      final why = e.code == 'network'
          ? (hi ? 'इंटरनेट कनेक्शन देखें।' : 'Check your internet connection.')
          : (hi ? 'फिर से कोशिश करें। (${e.code})' : 'Please try again. (${e.code})');
      showAppToast(target, (hi ? 'साइन इन नहीं हो सका। ' : "Couldn't sign in. ") + why, duration: const Duration(seconds: 4));
    }
    return false;
  } catch (e) {
    debugPrint('Sign-in failed: $e');
    if (target.mounted) {
      showAppToast(target, hi ? 'साइन इन नहीं हो सका। फिर से कोशिश करें।' : "Couldn't sign in. Please try again.",
          duration: const Duration(seconds: 4));
    }
    return false;
  }
}
