import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/localization/app_language.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/game_header.dart';
import '../core/widgets/heartbeat.dart';
import '../core/widgets/language_toggle.dart';
import '../core/widgets/pressable_card.dart';
import '../games/blocks_jodo/blocks_jodo_screen.dart';
import '../games/first/first_screen.dart';
import '../games/memory_grid/memory_grid_home_screen.dart';
import '../games/snakes_and_ladders/snl_home_screen.dart';
import '../games/thank_you/thank_you_screen.dart';
import 'settings_sheet.dart';

/// The launcher / home screen — Figma "Home - L0 Final - Phase 2"
/// (MilkeKhelo-Design, node 318:2044, 360×720).
///
/// Figma layout (y from frame top):
///   0    Header (12px padding, 32px controls)                    56
///   0    Top glow panel (radial, centred on its bottom edge)    280
///   120  Logo lockup (wordmark / heart divider / tagline)        74
///   310  "Most Popular Games" — Memory Grid · Snakes & Ladders
///        (155×148 cards, gap 10, radius 24, 6px ledge)
///   515  "More Games" — My First · Thank You · Block Jodo
///        (100×100 cards, gap 10, radius 16, 6px ledge)
///   648  …72px clear space to the bottom (no bottom bar in this frame)
///
/// As in Figma the logo is pinned to the top and the card sections to the
/// bottom; the gap between them flexes with the screen height. If a screen
/// is too short, the content scrolls.
///
/// This screen holds no game logic — each card just pushes that game's route.
const Color _homeBgEdge = Color(0xFF000E3A);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
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
          child: Stack(
            children: [
              // Figma "Rectangle 34624640": 360×280 panel behind the logo.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 280 + topInset,
                child: const CustomPaint(painter: _TopGlowPainter()),
              ),
              ValueListenableBuilder<AppLang>(
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
            ],
          ),
        ),
      ),
    );
  }
}

/// The top panel's radial gradient: centred on the panel's bottom edge,
/// 180 × 162.4 radii (Figma gradientTransform), same blue → navy stops.
class _TopGlowPainter extends CustomPainter {
  const _TopGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height);
    final rx = size.width / 2;
    const ry = 162.4;
    // Squash the circle vertically about its centre (column-major 4×4).
    final k = ry / rx;
    final m = Float64List.fromList([
      1, 0, 0, 0, //
      0, k, 0, 0, //
      0, 0, 1, 0, //
      0, center.dy * (1 - k), 0, 1,
    ]);
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        rx,
        const [Color(0xFF0026A0), Color(0xFF001A6D), Color(0xFF001453), _homeBgEdge],
        const [0, 0.5, 0.75, 1],
        ui.TileMode.clamp,
        m,
      );
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────────────────── Body ─────────────────────────────

class _HomeBody extends StatelessWidget {
  final bool isHi;
  const _HomeBody({required this.isHi});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 64),
                  _LogoLockup(isHi: isHi),
                  const SizedBox(height: 24),
                  const Spacer(),
                  _GameSections(isHi: isHi),
                  const SizedBox(height: 72),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────── Header ────────────────────────────

/// Figma "Header / Type=Home": 12px padding, 72px left slot with the menu
/// button, flexible centre, 72px language toggle on the right.
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
          const Expanded(child: SizedBox(height: 32)),
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

// ───────────────────────────── Logo ─────────────────────────────

/// Figma "Logo with Tagline" (Background=Dark): 240 wide, 6px gaps.
class _LogoLockup extends StatelessWidget {
  final bool isHi;
  const _LogoLockup({required this.isHi});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/home/wordmark.webp',
            width: 240,
            height: 240 / 7.2, // 33.33 — Figma wordmark slot
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            semanticLabel: 'milkekhelo.com',
          ),
          const SizedBox(height: 6),
          const CustomPaint(size: Size(146, 10), painter: _HeartDividerPainter()),
          const SizedBox(height: 6),
          Text(
            isHi ? 'कम स्क्रॉल, ज़्यादा कहानियाँ' : 'Less Scrolling. More Stories.',
            textAlign: TextAlign.center,
            style: AppText.tagline(),
          ),
        ],
      ),
    );
  }
}

/// Exact port of the lockup's divider SVG (viewBox 0 0 146 10): two 1px
/// white lines at 40% opacity either side of a small white heart.
class _HeartDividerPainter extends CustomPainter {
  const _HeartDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 146, size.height / 10);
    final line = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(0, 5), const Offset(63, 5), line);
    canvas.drawLine(const Offset(83, 5), const Offset(146, 5), line);

    final heart = Path()
      ..moveTo(73, 8)
      ..cubicTo(70.5, 6, 68.5, 4.6, 68.5, 2.9)
      ..cubicTo(68.5, 1.7, 69.5, 1, 70.6, 1)
      ..cubicTo(71.5, 1, 72.3, 1.5, 73, 2.4)
      ..cubicTo(73.7, 1.5, 74.5, 1, 75.4, 1)
      ..cubicTo(76.5, 1, 77.5, 1.7, 77.5, 2.9)
      ..cubicTo(77.5, 4.6, 75.5, 6, 73, 8)
      ..close();
    canvas.drawPath(heart, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────────────────── Cards ────────────────────────────

class _GameSections extends StatelessWidget {
  final bool isHi;
  const _GameSections({required this.isHi});

  static const double _gap = 10;

  static bool _precached = false;

  /// Decode both language sets once, so switching EN ⇄ हिं swaps the card
  /// art instantly with no blank frame.
  static void _precacheBothLanguages(BuildContext context) {
    if (_precached) return;
    _precached = true;
    for (final g in const ['snl', 'memory_grid', 'my_first', 'thank_you', 'blocks_jodo']) {
      for (final l in const ['en', 'hi']) {
        precacheImage(AssetImage('assets/home/card_${g}_$l.webp'), context);
      }
    }
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    // Card art is language-specific (the game name is part of the picture).
    // Lossless WebP — pixel-identical to the supplied PNGs.
    final lang = isHi ? 'hi' : 'en';
    _precacheBothLanguages(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(isHi ? 'सबसे लोकप्रिय खेल' : 'Most Popular Games'),
            const SizedBox(height: 8),
            Row(
              children: [
                // Figma: art 122.4px on a 155px card (78.9%), 14px from top.
                Expanded(
                  child: _GameModuleCard(
                    index: 0,
                    palette: AppColors.memoryGrid,
                    image: 'assets/home/card_memory_grid_$lang.webp',
                    faceHeight: 148,
                    radius: 24,
                    artFraction: 122.37 / 155,
                    artTop: 14,
                    label: isHi ? 'मेमोरी जाल' : 'Memory Grid',
                    onTap: () => _push(context, const MemoryGridHomeScreen()),
                  ),
                ),
                const SizedBox(width: _gap),
                // Figma: art 130px on a 155px card (83.9%), 9px from top.
                Expanded(
                  child: _GameModuleCard(
                    index: 1,
                    palette: AppColors.snakesAndLadders,
                    image: 'assets/home/card_snl_$lang.webp',
                    faceHeight: 148,
                    radius: 24,
                    artFraction: 130 / 155,
                    artTop: 9,
                    label: isHi ? 'साँप-सीढ़ी' : 'Snakes & Ladders',
                    onTap: () => _push(context, const SnlHomeScreen()),
                  ),
                ),
              ],
            ),
            // 24px between sections; the 6px ledge already sits in the row.
            const SizedBox(height: 24 - _GameModuleCard.ledge),
            _SectionTitle(isHi ? 'और खेल' : 'More Games'),
            const SizedBox(height: 8),
            Row(
              children: [
                // Figma: 100×100 cards, 88px art inset 6px.
                Expanded(
                  child: _GameModuleCard(
                    index: 2,
                    palette: AppColors.first,
                    image: 'assets/home/card_my_first_$lang.webp',
                    faceHeight: 100,
                    radius: 16,
                    artSize: 88,
                    artTop: 6,
                    label: isHi ? 'मेरा पहला' : 'My First',
                    onTap: () => _push(context, const FirstScreen()),
                  ),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: _GameModuleCard(
                    index: 3,
                    palette: AppColors.thankYou,
                    image: 'assets/home/card_thank_you_$lang.webp',
                    faceHeight: 100,
                    radius: 16,
                    artSize: 88,
                    artTop: 6,
                    label: isHi ? 'धन्यवाद' : 'Thank You',
                    onTap: () => _push(context, const ThankYouScreen()),
                  ),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: _GameModuleCard(
                    index: 4,
                    palette: AppColors.blocksJodo,
                    image: 'assets/home/card_blocks_jodo_$lang.webp',
                    faceHeight: 100,
                    radius: 16,
                    artSize: 88,
                    artTop: 7,
                    label: isHi ? 'ब्लॉक जोड़ो' : 'Block Jodo',
                    onTap: () => _push(context, const BlocksJodoScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
