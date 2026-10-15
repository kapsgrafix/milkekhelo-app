import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_service.dart';
import '../feedback/fx.dart';
import '../localization/app_language.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/chunky_button.dart';
import '../widgets/social_login_button.dart';

/// "Don't lose your game!" — the sign-in nudge (Figma "Save Progress
/// Overlay - In Game", 401:675).
///
/// Only for games with real progress to save: Snakes & Ladders, Chess,
/// Memory Grid (solo) and Blocks Jodo. Never for My First, Thank You or
/// Who's That.
///
/// WHEN: as the player tries to LEAVE a game (header back arrow, Android
/// back, or a "Home" / exit button) after that game's progress threshold
/// is met — never from the result screen. "Exit the game" leaves; ✕, tap
/// outside or back closes it and the player stays in the game. Google /
/// Facebook (side by side) show "coming soon" and keep them in the game.
/// HOW OFTEN: the first [maxShows] times for a new player, then never.
///
/// Usage: wrap the game screen in a [SaveProgressGate], and route every
/// exit through `Navigator.maybePop(context)` so the gate can step in.
class SaveProgressNudge {
  SaveProgressNudge._();

  static const int maxShows = 10;
  static const String _countKey = 'save_progress_overlay_count';

  static int? _shownCount; // null until loaded

  static Future<void> _load() async {
    if (_shownCount != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _shownCount ??= prefs.getInt(_countKey) ?? 0;
    } catch (_) {
      _shownCount ??= maxShows; // can't remember — stay quiet
    }
  }

  /// Warm up the stored count (called when a gated game opens).
  static void preload() => _load();

  /// True when the overlay may be shown now.
  static bool ready({required bool progressed}) {
    final count = _shownCount;
    // Signed-in players already have their progress saved — never nudge them.
    return progressed && count != null && count < maxShows && !AuthService.instance.signedIn;
  }

  /// Shows the overlay. Completes with true if the player chose "Exit the
  /// game", false if they closed it (✕, tap outside, back) to keep playing.
  static Future<bool> show(BuildContext context, {required Color background}) async {
    _shownCount = (_shownCount ?? 0) + 1;
    SharedPreferences.getInstance()
        .then((p) => p.setInt(_countKey, _shownCount!))
        .catchError((_) => false);
    final exit = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: const Color(0x99000000), // Figma scrim: black 60%
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, _, __) => SaveProgressOverlay(background: background),
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(scale: Tween(begin: 0.88, end: 1.0).animate(curved), child: child),
        );
      },
    );
    return exit == true;
  }
}

/// Wraps a game screen and catches every attempt to leave it (Android back
/// and anything that calls `Navigator.maybePop`). If [progressed] says the
/// threshold is met and the overlay still has shows left, the overlay
/// appears first: "Exit the game" leaves; ✕ (or tap outside / back) closes
/// it and the player stays in the game.
class SaveProgressGate extends StatefulWidget {
  /// Has the player made enough progress for the nudge? Asked at exit time.
  final bool Function() progressed;

  /// The game's screen colour (the overlay card's fill).
  final Color background;

  /// Called just before the overlay appears (e.g. to pause a match clock).
  final VoidCallback? onShow;

  /// Called when the player closes the overlay and stays in the game.
  final VoidCallback? onResume;

  final Widget child;

  const SaveProgressGate({
    super.key,
    required this.progressed,
    required this.background,
    required this.child,
    this.onShow,
    this.onResume,
  });

  @override
  State<SaveProgressGate> createState() => _SaveProgressGateState();
}

class _SaveProgressGateState extends State<SaveProgressGate> {
  bool _leaving = false;

  /// The player already closed it once in this game: the next exit attempt
  /// just leaves (no asking twice).
  bool _dismissedHere = false;

  @override
  void initState() {
    super.initState();
    SaveProgressNudge.preload();
  }

  Future<void> _onExit() async {
    if (_leaving) return;
    _leaving = true;
    final nav = Navigator.of(context);
    if (!_dismissedHere && SaveProgressNudge.ready(progressed: widget.progressed())) {
      widget.onShow?.call();
      final exit = await SaveProgressNudge.show(context, background: widget.background);
      if (!exit) {
        // ✕ / tap outside / back: stay in the game.
        _leaving = false;
        _dismissedHere = true;
        if (mounted) widget.onResume?.call();
        return;
      }
    }
    if (mounted) nav.pop(); // "Exit the game" (or no overlay): leave
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onExit();
      },
      child: widget.child,
    );
  }
}

/// Figma "Save Progress Overlay" (401:648): 320px card, radius 28, 1px
/// border/default, shadow 0 16 40 black 45%. The fill is the current
/// game's screen colour so it sits naturally on every game.
///   Body: 24 top / 20 sides / 18 bottom, 16px gaps (Figma 461:2111):
///     save badge (280×100) · title + subtitle (6px) ·
///     [Google | Facebook] + trust line (8px) · dull OR divider ·
///     Primary "Leave game" button
///   Close: 36×36 module/red chip, radius 12, 3px ledge, 11px from the
///   top and 13px from the right.
class SaveProgressOverlay extends StatelessWidget {
  final Color background;
  const SaveProgressOverlay({super.key, required this.background});

  static const Color _red = Color(0xFFE03D3D); // module/red
  static const Color _redShadow = Color(0xFF5D1010); // module/red-shadow

  @override
  Widget build(BuildContext context) {
    void close() => Navigator.of(context).pop(false); // stay in the game
    void exitGame() => Navigator.of(context).pop(true); // carry on leaving
    Future<void> signIn(SignInProvider provider) async {
      if (provider == SignInProvider.facebook) {
        showSignInComingSoon(context); // not wired up yet
        close();
        return;
      }
      // Signed in → close the overlay (stay in the game), then Welcome.
      await signInFromButton(context, provider, beforeWelcome: close);
    }

    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final hi = lang == AppLang.hi;
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.borderDefault),
                  boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 40, offset: Offset(0, 16))],
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Figma (461:2111): save badge illustration, 280×100.
                          const FittedBox(fit: BoxFit.scaleDown, child: _SaveBadge()),
                          const SizedBox(height: 16),
                          Text(
                            hi ? 'अपना गेम मत खोइए!' : "Don't lose your game!",
                            textAlign: TextAlign.center,
                            style: AppFonts.baloo(fontSize: 24, fontWeight: FontWeight.w800, height: 1.15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hi
                                ? 'साइन इन करें और हम आपकी प्रगति सेव कर लेंगे — किसी भी फ़ोन पर वहीं से खेलें जहाँ छोड़ा था।'
                                : "Sign in and we'll save your progress — jump back in right where you left off, on any phone.",
                            textAlign: TextAlign.center,
                            style: AppFonts.baloo(
                                fontSize: 14, fontWeight: FontWeight.w500, height: 1.4, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          // Sign In Group: Google + Facebook side by side, trust line.
                          Row(
                            children: [
                              Expanded(child: SocialLoginButton.google(onTap: () => signIn(SignInProvider.google), compact: true)),
                              const SizedBox(width: 10),
                              Expanded(child: SocialLoginButton.facebook(onTap: () => signIn(SignInProvider.facebook), compact: true)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hi ? 'हम आपसे पूछे बिना कभी कुछ पोस्ट नहीं करेंगे।' : "We'll never post anything without asking.",
                            textAlign: TextAlign.center,
                            style: AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          // Dull "OR" divider (60% opacity).
                          Opacity(
                            opacity: 0.6,
                            child: Row(
                              children: [
                                Expanded(child: Container(height: 1, color: AppColors.borderDefault)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    hi ? 'या' : 'OR',
                                    style: AppFonts.baloo(
                                        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.96, color: AppColors.textMuted),
                                  ),
                                ),
                                Expanded(child: Container(height: 1, color: AppColors.borderDefault)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ChunkyButton(
                            label: hi ? 'गेम छोड़ें' : 'Leave game',
                            width: double.infinity,
                            onTap: exitGame,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 11,
                      right: 13,
                      child: Semantics(
                        button: true,
                        label: hi ? 'बंद करें' : 'Close',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Fx.tap();
                            close();
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _red,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: _redShadow, offset: Offset(0, 3))],
                            ),
                            child: const Icon(Icons.close_rounded, size: 22, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
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

/// Figma "Illustration" (save badge, 280×100): a soft blue glow, a white
/// cloud with a green check badge, two yellow sparkles and two white
/// twinkles. Drawn in code so it stays crisp and sits on any game colour.
class _SaveBadge extends StatelessWidget {
  const _SaveBadge();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 280, height: 100, child: CustomPaint(painter: _SaveBadgePainter()));
  }
}

class _SaveBadgePainter extends CustomPainter {
  const _SaveBadgePainter();

  static void _sparkle(Canvas canvas, Offset c, double r, Color color) {
    // Four-point star with concave sides.
    final p = Path()..moveTo(c.dx, c.dy - r);
    p.quadraticBezierTo(c.dx + r * 0.18, c.dy - r * 0.18, c.dx + r, c.dy);
    p.quadraticBezierTo(c.dx + r * 0.18, c.dy + r * 0.18, c.dx, c.dy + r);
    p.quadraticBezierTo(c.dx - r * 0.18, c.dy + r * 0.18, c.dx - r, c.dy);
    p.quadraticBezierTo(c.dx - r * 0.18, c.dy - r * 0.18, c.dx, c.dy - r);
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const glowC = Offset(128, 50);
    // Glow (may spill a little outside the box, like the Figma export).
    canvas.drawCircle(
      glowC,
      78,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0x665B7BFF), Color(0x005B7BFF)])
            .createShader(Rect.fromCircle(center: glowC, radius: 78)),
    );

    // Cloud: a pill base plus three round bumps.
    final cloud = Path()
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(86, 56, 170, 84), const Radius.circular(14)))
      ..addOval(Rect.fromCircle(center: const Offset(108, 58), radius: 19))
      ..addOval(Rect.fromCircle(center: const Offset(130, 44), radius: 26))
      ..addOval(Rect.fromCircle(center: const Offset(153, 58), radius: 17));
    canvas.drawPath(
      cloud.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x40000820)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      cloud,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFE6EBFF), Color(0xFFB9C6FF)],
          stops: [0, 0.55, 1],
        ).createShader(const Rect.fromLTRB(86, 18, 170, 84)),
    );

    // Green check badge with a white ring.
    const badgeC = Offset(165, 76);
    canvas.drawCircle(badgeC, 18, Paint()..color = Colors.white);
    canvas.drawCircle(badgeC, 15, Paint()..color = const Color(0xFF33C481));
    final tick = Path()
      ..moveTo(badgeC.dx - 7, badgeC.dy + 0.5)
      ..lineTo(badgeC.dx - 2, badgeC.dy + 5.5)
      ..lineTo(badgeC.dx + 7.5, badgeC.dy - 5);
    canvas.drawPath(
      tick,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Sparkles.
    _sparkle(canvas, const Offset(74, 19), 8, const Color(0xFFFFC53D));
    _sparkle(canvas, const Offset(214, 28), 6, const Color(0xFFFFC53D));
    _sparkle(canvas, const Offset(58, 46), 3.5, const Color(0xCCFFFFFF));
    _sparkle(canvas, const Offset(218, 60), 3.5, const Color(0xCCFFFFFF));
  }

  @override
  bool shouldRepaint(_SaveBadgePainter old) => false;
}
