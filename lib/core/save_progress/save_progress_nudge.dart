import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feedback/fx.dart';
import '../localization/app_language.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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
    return progressed && count != null && count < maxShows;
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
///   Body: 24 top / 20 sides / 18 bottom, 16px gaps:
///     illustration (280×118) · title + subtitle (6px) ·
///     Google + Facebook (10px) · trust line
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
    void signIn() {
      showSignInComingSoon(context);
      close(); // stay in the game for now (sign-in isn't wired up yet)
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
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _Illustration(saved: hi ? 'सेव!' : 'SAVED!'),
                          ),
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
                          // Google and Facebook side by side.
                          Row(
                            children: [
                              Expanded(child: SocialLoginButton.google(onTap: signIn, compact: true)),
                              const SizedBox(width: 10),
                              Expanded(child: SocialLoginButton.facebook(onTap: signIn, compact: true)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            button: true,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Fx.tap();
                                exitGame();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // touch target
                                child: Text(
                                  hi ? 'गेम से बाहर निकलें' : 'Exit the game',
                                  style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w600).copyWith(
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hi ? 'हम आपसे पूछे बिना कभी कुछ पोस्ट नहीं करेंगे।' : "We'll never post anything without asking.",
                            textAlign: TextAlign.center,
                            style: AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted),
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

/// The 280×118 emoji cluster: cloud, controller, dice, star, sparkle, a
/// tilted yellow "SAVED!" badge and confetti — positions from Figma
/// (each rotated piece is centred in its rotated bounding box).
class _Illustration extends StatelessWidget {
  final String saved;
  const _Illustration({required this.saved});

  static double _deg(double d) => d * pi / 180;

  Widget _emoji(String e, double size) => Text(e, style: TextStyle(fontSize: size, height: 1.2));

  Widget _rotated({required double left, required double top, required double w, required double h, required double deg, required Widget child}) {
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Transform.rotate(angle: _deg(deg), child: child),
      ),
    );
  }

  /// [left]/[top]/[bw]/[bh] are the rotated bounding box from Figma;
  /// [w]×[h] is the confetti piece before rotation.
  Widget _confetti(double left, double top, double bw, double bh, double w, double h, double deg, Color c, double r) {
    return _rotated(
      left: left,
      top: top,
      w: bw,
      h: bh,
      deg: deg,
      child: Container(width: w, height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 118,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 94, top: 2, child: _emoji('☁️', 92)),
          _rotated(left: 154.93, top: 80, w: 40.33, h: 40.33, deg: 12, child: _emoji('🎮', 34)),
          _rotated(left: 76, top: 79.23, w: 33.94, h: 33.94, deg: -14, child: _emoji('🎲', 28)),
          _rotated(left: 46.18, top: 14, w: 25.49, h: 25.49, deg: 10, child: _emoji('⭐', 22)),
          Positioned(left: 212, top: 40, child: _emoji('✨', 20)),
          _rotated(
            left: 114.8,
            top: 58,
            w: 66.58,
            h: 31.68,
            deg: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandYellow,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [BoxShadow(color: Color(0xFF7A4A00), offset: Offset(0, 2))],
              ),
              child: Text(
                saved,
                style: AppFonts.baloo(
                    fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF3B2503), letterSpacing: 0.72),
              ),
            ),
          ),
          _confetti(14, 17.77, 11.6, 9.66, 10, 6, -25, const Color(0xFFFFC53D), 3),
          _confetti(44, 94.34, 11.31, 11.31, 8, 8, -45, const Color(0xFFFF5D8F), 4),
          _confetti(228.29, 18, 10.17, 7.78, 9, 5, 20, const Color(0xFF33C481), 2.5),
          _confetti(256, 104.19, 8.57, 8.57, 7, 7, -15, const Color(0xFFFF7A45), 3.5),
          _confetti(202, 119.34, 9.33, 11.16, 10, 5, -60, const Color(0xFF9B7FEA), 2.5),
          _confetti(2, 70, 6, 6, 6, 6, 0, Colors.white, 3),
          _confetti(272, 60, 6, 6, 6, 6, 0, const Color(0xFFFFE08A), 3),
        ],
      ),
    );
  }
}
