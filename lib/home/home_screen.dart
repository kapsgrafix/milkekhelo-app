import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/localization/app_language.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/chunky_button.dart';
import '../core/widgets/game_header.dart';
import '../core/widgets/heartbeat.dart';
import '../core/widgets/language_toggle.dart';
import '../core/widgets/pressable_card.dart';
import '../games/blocks_jodo/blocks_jodo_screen.dart';
import '../games/chess/chess_home_screen.dart';
import '../games/first/first_screen.dart';
import '../games/memory_grid/memory_grid_home_screen.dart';
import '../games/snakes_and_ladders/snl_home_screen.dart';
import '../games/thank_you/thank_you_screen.dart';
import '../games/whos_that/whos_that_screen.dart';
import 'settings_sheet.dart';

/// The launcher / home screen — Figma "Home - L0 Final - Phase 3"
/// (MilkeKhelo-Design, node 348:2469, 360×720).
///
/// Figma layout (y from frame top). Kapil's tweaks on top of the frame:
/// 16px side margins, Party Games cards fill the row (10px gaps, square),
/// no bottom bar.
///   0    Header (Type=Logo): menu · centred 136px wordmark · language   56
///   68   Featured banner 320×264, radius 24: block-art background,
///        160px Block Jodo art at (80, 24), 240×48 "Play Now" at (40, 192)
///   356  "MilkeKhelo Party Games" — My First · Who's That? · Thank You
///        (square cards filling the row, gap 10, radius 16, 6px ledge)
///   513  "Classic Games" — Snakes & Ladders · Chess · Memory Grid
///        (square cards filling the row, gap 10, radius 16, 6px ledge)
///        32px bottom padding
/// The content is taller than most screens, so it scrolls.
///
/// This screen holds no game logic — each card just pushes that game's route.
const Color _homeBgEdge = Color(0xFF000E3A);

void _push(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _homeBgEdge,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _homeBgEdge,
        body: DecoratedBox(
          // Figma: radial blue glow centred at (180, 451.5) of the 360×720
          // frame, radius ≈ 273, fading to deep navy.
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, 451.5 / 360 - 1),
              radius: 273 / 360, // fraction of the screen width
              colors: [Color(0xFF0026A0), Color(0xFF001A6D), Color(0xFF001453), _homeBgEdge],
              stops: [0, 0.5, 0.75, 1],
            ),
          ),
          child: ValueListenableBuilder<AppLang>(
            valueListenable: AppLanguage.instance,
            builder: (context, lang, _) {
              final isHi = lang == AppLang.hi;
              return Column(
                children: [
                  const SafeArea(bottom: false, child: _HomeHeader()),
                  Expanded(child: _HomeBody(isHi: isHi)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Body ─────────────────────────────

class _HomeBody extends StatelessWidget {
  final bool isHi;
  const _HomeBody({required this.isHi});

  static bool _precached = false;

  /// Decode both language sets once, so switching EN ⇄ हिं swaps the card
  /// art instantly with no blank frame.
  static void _precacheAll(BuildContext context) {
    if (_precached) return;
    _precached = true;
    precacheImage(const AssetImage('assets/home/banner_bg.webp'), context);
    for (final g in const ['blocks_jodo', 'my_first', 'whos_that', 'thank_you', 'snl', 'chess', 'memory_grid']) {
      for (final l in const ['en', 'hi']) {
        precacheImage(AssetImage('assets/home/card_${g}_$l.webp'), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Card art is language-specific (the game name is part of the picture).
    // Lossless WebP — pixel-identical to the supplied PNGs.
    final lang = isHi ? 'hi' : 'en';
    _precacheAll(context);

    // Party cards share the full row width (10px gaps) and stay square:
    // radius 16, art 84% of the card, inset 8% (Figma 84 / 8 at 100px).
    Widget small(double side, int index, GameCardPalette palette, String game, String label, Widget Function() screen) {
      return SizedBox(
        width: side,
        child: _GameModuleCard(
          index: index,
          palette: palette,
          image: 'assets/home/card_${game}_$lang.webp',
          faceHeight: side,
          radius: 16,
          artSize: side * 0.84,
          artTop: side * 0.08,
          label: label,
          onTap: () => _push(context, screen()),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 32 - _GameModuleCard.ledge + MediaQuery.paddingOf(context).bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FeaturedBanner(isHi: isHi),
              const SizedBox(height: 24),
              _SectionTitle(isHi ? 'मिलकेखेलो पार्टी गेम्स' : 'MilkeKhelo Party Games'),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, c) {
                  final side = (c.maxWidth - 2 * 10) / 3;
                  return Row(
                    children: [
                      small(side, 0, AppColors.first, 'my_first', isHi ? 'मेरा पहला' : 'My First', () => const FirstScreen()),
                      const SizedBox(width: 10),
                      small(side, 1, AppColors.snakesAndLadders /* module/pink */, 'whos_that',
                          isHi ? 'पहचान कौन' : "Who's That?", () => const WhosThatScreen()),
                      const SizedBox(width: 10),
                      small(side, 2, AppColors.thankYou, 'thank_you', isHi ? 'धन्यवाद' : 'Thank You', () => const ThankYouScreen()),
                    ],
                  );
                },
              ),
              // Figma: 24px from the card faces to the next section; the
              // 6px ledge already sits inside the row.
              const SizedBox(height: 24 - _GameModuleCard.ledge),
              _SectionTitle(isHi ? 'क्लासिक खेल' : 'Classic Games'),
              const SizedBox(height: 8),
              // Three classic games — same full-width square cards as the
              // Party row; Chess uses the My First purple.
              LayoutBuilder(
                builder: (context, c) {
                  final side = (c.maxWidth - 2 * 10) / 3;
                  return Row(
                    children: [
                      small(side, 3, AppColors.snakesAndLadders, 'snl', isHi ? 'साँप-सीढ़ी' : 'Snakes & Ladders',
                          () => const SnlHomeScreen()),
                      const SizedBox(width: 10),
                      small(side, 4, AppColors.first, 'chess', isHi ? 'शतरंज' : 'Chess', () => const ChessHomeScreen()),
                      const SizedBox(width: 10),
                      small(side, 5, AppColors.memoryGrid, 'memory_grid', isHi ? 'मेमोरी जाल' : 'Memory Grid',
                          () => const MemoryGridHomeScreen()),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma "Logo" frame (349:3597): 320×264 banner, radius 24, the block
/// background art (cover), Block Jodo art 160×160 centred 24px from the
/// top, and a 240px Primary "Play Now" button 192px from the top.
class _FeaturedBanner extends StatelessWidget {
  final bool isHi;
  const _FeaturedBanner({required this.isHi});

  static const double height = 264;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/home/banner_bg.webp',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
            ),
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Heartbeat(
                  child: Image.asset(
                    'assets/home/card_blocks_jodo_${isHi ? 'hi' : 'en'}.webp',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    semanticLabel: isHi ? 'ब्लॉक जोड़ो' : 'Block Jodo',
                  ),
                ),
              ),
            ),
            Positioned(
              top: 192,
              left: 0,
              right: 0,
              child: Center(
                child: ChunkyButton(
                  label: isHi ? 'अभी खेलें' : 'Play Now',
                  width: 240,
                  onTap: () => _push(context, const BlocksJodoScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────── Header ────────────────────────────

/// Figma "Header / Type=Logo": 12px padding, 72px left slot with the menu
/// button, the 136×18.9 wordmark centred, 72px language toggle on the right.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _MenuButton(onTap: () => showSettingsSheet(context)),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 32,
              child: Center(
                child: Image.asset(
                  'assets/home/wordmark.webp',
                  width: 136,
                  height: 136 / 7.2, // 18.89 — Figma wordmark slot
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  semanticLabel: 'milkekhelo.com',
                ),
              ),
            ),
          ),
          const LanguageToggle(),
        ],
      ),
    );
  }
}

/// Figma "Icon/Menu": the shared 32×32 header button with a 16px
/// three-bar hamburger glyph in text/primary.
class _MenuButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget bar() => Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
    return HeaderIconButton(
      semanticLabel: 'Menu',
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [bar(), const SizedBox(height: 3), bar(), const SizedBox(height: 3), bar()],
      ),
    );
  }
}


// ───────────────────────────── Cards ────────────────────────────


/// Figma "Section Divider": SemiBold 16, text/primary, left-aligned.
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w600, height: 25 / 16),
    );
  }
}

/// Figma Phase 2 game card: gradient face, 6px solid ledge, game artwork
/// (with its name baked in) centred horizontally at a fixed top inset.
/// Pressed = 18% black overlay plus the shared 3px press-down.
/// Every card pulses ([Heartbeat], staggered) and a diagonal light sweep
/// ([_CardShimmer]) passes over it at random intervals.
class _GameModuleCard extends StatelessWidget {
  static const double ledge = 6;

  final int index;
  final GameCardPalette palette;
  final String image;
  final double faceHeight;
  final double radius;

  /// Art width as a fraction of the card width (big cards scale with the
  /// screen) — or a fixed [artSize] (small cards).
  final double? artFraction;
  final double? artSize;
  final double artTop;
  final String label;
  final VoidCallback onTap;

  const _GameModuleCard({
    required this.index,
    required this.palette,
    required this.image,
    required this.faceHeight,
    required this.radius,
    this.artFraction,
    this.artSize,
    required this.artTop,
    required this.label,
    required this.onTap,
  }) : assert(artFraction != null || artSize != null);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Heartbeat(
        delay: Duration(milliseconds: 220 * index),
        child: SizedBox(
          height: faceHeight + ledge,
          child: PressableCard(
            topColor: palette.top,
            bottomColor: palette.bottom,
            shadowColor: palette.shadow,
            borderRadius: radius,
            shadowOffset: ledge,
            pressedOverlayColor: const Color(0x2E000000), // 18% black
            onTap: onTap,
            child: LayoutBuilder(
              builder: (context, c) {
                final size = min(artSize ?? c.maxWidth * artFraction!, faceHeight - artTop);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: artTop,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Image.asset(
                          image,
                          width: size,
                          height: size,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    _CardShimmer(radius: radius),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft white band that glides diagonally across the card (2.4 s, sine
/// easing), then waits a random 4–9 s before the next pass (first pass
/// staggered 1.2–4.7 s), so the
/// four cards glint at different, unpredictable moments — the "alive"
/// idle polish seen in high-end casual games. Skipped entirely when the
/// phone's "remove animations" accessibility setting is on.
class _CardShimmer extends StatefulWidget {
  final double radius;
  const _CardShimmer({required this.radius});

  @override
  State<_CardShimmer> createState() => _CardShimmerState();
}

class _CardShimmerState extends State<_CardShimmer> with SingleTickerProviderStateMixin {
  static final _rng = Random();
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  Timer? _next;

  @override
  void initState() {
    super.initState();
    _schedule(first: true);
  }

  void _schedule({bool first = false}) {
    final ms = first ? 1200 + _rng.nextInt(3500) : 4000 + _rng.nextInt(5000);
    _next = Timer(Duration(milliseconds: ms), () async {
      if (!mounted) return;
      if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
        await _c.forward(from: 0).orCancel.catchError((_) {});
      }
      if (mounted) _schedule();
    });
  }

  @override
  void dispose() {
    _next?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            if (_c.value == 0 || _c.value == 1) return const SizedBox.expand();
            final t = Curves.easeInOutSine.transform(_c.value);
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-1, -1),
                  end: const Alignment(1, 1),
                  // Wide, feathered band so the glint glides rather than flashes.
                  colors: const [
                    Color(0x00FFFFFF),
                    Color(0x00FFFFFF),
                    Color(0x14FFFFFF),
                    Color(0x3DFFFFFF),
                    Color(0x14FFFFFF),
                    Color(0x00FFFFFF),
                    Color(0x00FFFFFF),
                  ],
                  stops: const [0.0, 0.3, 0.41, 0.5, 0.59, 0.7, 1.0],
                  transform: _SlideGradient(-1.2 + 2.4 * t),
                ),
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

/// Moves a gradient along its own diagonal by [fraction] of the box size.
class _SlideGradient extends GradientTransform {
  final double fraction;
  const _SlideGradient(this.fraction);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * fraction, bounds.height * fraction, 0);
}
