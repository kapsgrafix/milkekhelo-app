import 'package:flutter/material.dart';

import '../auth/account_ui.dart';
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

/// A short note that drops in at the top of the screen and fades away by
/// itself, e.g. "Game saved" after signing in from a game. Lives on the
/// root overlay, so it stays visible while the game screen closes.
void showTopToast(OverlayState overlay, String text, {Duration duration = const Duration(milliseconds: 2600)}) {
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _TopToast(text: text, duration: duration, onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _TopToast extends StatefulWidget {
  final String text;
  final Duration duration;
  final VoidCallback onDone;
  const _TopToast({required this.text, required this.duration, required this.onDone});

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _c.forward();
    await Future.delayed(widget.duration);
    if (!mounted) return;
    await _c.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 24,
      right: 24,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _c,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -0.6), end: Offset.zero).animate(curve),
            child: Center(
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16234A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderDefault),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 8))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF22C55E)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(widget.text, style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// For sign-in methods that aren't wired up yet (Facebook, for now).
void showSignInComingSoon(BuildContext context) {
  Fx.tap();
  final hi = AppLanguage.instance.isHindi;
  showAppToast(context, hi ? 'Facebook साइन इन जल्द आ रहा है!' : 'Facebook sign in is coming soon!');
}

/// Runs a sign-in from any button (Settings, Save Progress overlay).
/// Success → the Welcome dialog (Figma 460:828); failure → a short toast.
/// [beforeWelcome] runs first on success (e.g. to close the overlay the
/// button lives in). [welcome]: false skips the Welcome dialog (the
/// in-game overlay closes the game instead). Returns true when signed in.
Future<bool> signInFromButton(
  BuildContext context,
  SignInProvider provider, {
  BuildContext? toastContext,
  VoidCallback? beforeWelcome,
  bool welcome = true,
}) async {
  if (provider == SignInProvider.facebook) {
    showSignInComingSoon(context);
    return false;
  }
  Fx.tap();
  final hi = AppLanguage.instance.isHindi;
  final target = toastContext ?? context;
  final nav = Navigator.of(context, rootNavigator: true);
  try {
    final u = await AuthService.instance.signInWithGoogle();
    beforeWelcome?.call();
    if (welcome && nav.mounted) {
      Fx.roundWin();
      showWelcomeDialog(nav.context, u);
    }
    return true;
  } on AuthException catch (e) {
    if (e.code == 'busy') return false;
    if (e.cancelled) {
      // A real "back" from the account picker has no reason; anything else
      // (e.g. "[16] Account reauth failed") is a setup problem worth showing.
      final reason = e.detail ?? '';
      if (reason.isNotEmpty && target.mounted) {
        showAppToast(target, (hi ? 'साइन इन नहीं हो सका: ' : "Couldn't sign in: ") + reason,
            duration: const Duration(seconds: 6));
      }
      return false;
    }
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
