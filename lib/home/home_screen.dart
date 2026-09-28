import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/localization/app_language.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/game_header.dart';
import '../core/widgets/language_toggle.dart';
import '../core/widgets/pressable_card.dart';
import '../core/widgets/screen_bottom_bar.dart';
import '../games/first/first_screen.dart';
import '../games/memory_grid/memory_grid_home_screen.dart';
import '../games/snakes_and_ladders/snl_screen.dart';
import '../games/thank_you/thank_you_screen.dart';
import 'settings_sheet.dart';

/// The launcher / home screen — built to the Figma frame "Home - L0"
/// "Home - L0 Final EN" (MilkeKhelo-Design, node 236:968, 360×720).
///
/// Figma layout (y from frame top):
///   0   Header (12px padding, 32px controls)          → 56 tall
///   156 Logo lockup (wordmark / heart divider / tagline) → 74 tall
///   308 2×2 game cards (152×148 / 152×152, gap 16×22, 6px ledge)
///   670 Bottom bar (50px, background/surface)
///
/// The vertical gaps (100 / 78 / 34) are flex spacers so the layout is
/// pixel-exact on a 720pt-tall screen and scales proportionally on taller
/// or shorter phones. If a screen is too short, the content scrolls.
///
/// This screen holds no game logic — each card just pushes that game's route.
const Color _homeBgEdge = Color(0xFF000E3A);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF232B52), // surface over the gradient's edge
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _homeBgEdge,
        body: DecoratedBox(
          // Figma "Home - L0 Final": radial blue glow centred at (180, 451.5)
          // of the 360×720 frame, radius ≈ 273, fading to deep navy.
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
                  const ScreenBottomBar(),
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
                  const Spacer(flex: 100),
                  _LogoLockup(isHi: isHi),
                  const Spacer(flex: 78),
                  _GameGrid(isHi: isHi),
                  const Spacer(flex: 34),
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

class _GameGrid extends StatelessWidget {
  final bool isHi;
  const _GameGrid({required this.isHi});

  static const double _colGap = 16;
  // Figma row gap is 22 measured card-to-card; each cell already includes
  // the 6px shadow ledge, so the visible gap between cells is 22 - 6.
  static const double _rowGap = 22 - _GameModuleCard.ledge;

  static bool _precached = false;

  /// Decode both language sets once, so switching EN ⇄ हिं swaps the card
  /// art instantly with no blank frame.
  static void _precacheBothLanguages(BuildContext context) {
    if (_precached) return;
    _precached = true;
    for (final g in const ['snl', 'memory_grid', 'my_first', 'thank_you']) {
      for (final l in const ['en', 'hi']) {
        precacheImage(AssetImage('assets/home/card_${g}_$l.webp'), context);
      }
    }
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    // Figma "Home - L0 Final EN": row 1 cards are 152×148, row 2 are
    // 152×152; art is 120px (Thank You 124px), centred on the card face.
    // The game names are part of the artwork (English / Hindi versions).
    // Card art is language-specific (the game name is part of the picture).
    // Lossless WebP — pixel-identical to the supplied PNGs.
    final lang = isHi ? 'hi' : 'en';
    _precacheBothLanguages(context);
    final cards = [
      _GameModuleCard(
        palette: AppColors.snakesAndLadders,
        image: 'assets/home/card_snl_$lang.webp',
        imageSize: 120,
        faceHeight: 148,
        label: isHi ? 'साँप-सीढ़ी' : 'Snakes & Ladders',
        onTap: () => _push(context, const SnlScreen()),
      ),
      _GameModuleCard(
        palette: AppColors.memoryGrid,
        image: 'assets/home/card_memory_grid_$lang.webp',
        imageSize: 120,
        faceHeight: 148,
        label: isHi ? 'मेमोरी जाल' : 'Memory Grid',
        onTap: () => _push(context, const MemoryGridHomeScreen()),
      ),
      _GameModuleCard(
        palette: AppColors.first,
        image: 'assets/home/card_my_first_$lang.webp',
        imageSize: 120,
        faceHeight: 152,
        label: isHi ? 'मेरा पहला' : 'My First',
        onTap: () => _push(context, const FirstScreen()),
      ),
      _GameModuleCard(
        palette: AppColors.thankYou,
        image: 'assets/home/card_thank_you_$lang.webp',
        imageSize: 124,
        faceHeight: 152,
        label: isHi ? 'धन्यवाद' : 'Thank You',
        onTap: () => _push(context, const ThankYouScreen()),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          children: [
            Row(children: [Expanded(child: cards[0]), const SizedBox(width: _colGap), Expanded(child: cards[1])]),
            const SizedBox(height: _rowGap),
            Row(children: [Expanded(child: cards[2]), const SizedBox(width: _colGap), Expanded(child: cards[3])]),
          ],
        ),
      ),
    );
  }
}

/// Figma "Home - L0 Final" game card: gradient face, radius 24, 6px solid
/// ledge, game artwork (with its name baked in) centred on the face.
/// Pressed = 18% black overlay plus the shared 3px press-down.
/// A diagonal light sweep ([_CardShimmer]) passes over each card at
/// random intervals so the screen feels alive.
class _GameModuleCard extends StatelessWidget {
  static const double ledge = 6;

  final GameCardPalette palette;
  final String image;
  final double imageSize;
  final double faceHeight;
  final String label;
  final VoidCallback onTap;

  const _GameModuleCard({
    required this.palette,
    required this.image,
    required this.imageSize,
    required this.faceHeight,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: faceHeight + ledge,
        child: PressableCard(
          topColor: palette.top,
          bottomColor: palette.bottom,
          shadowColor: palette.shadow,
          borderRadius: 24,
          shadowOffset: ledge,
          pressedOverlayColor: const Color(0x2E000000), // 18% black
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Image.asset(
                  image,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const _CardShimmer(radius: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// A soft white band that sweeps diagonally across the card, then waits a
/// random 3–8 s before the next pass (first pass staggered 0.8–4 s), so the
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
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  Timer? _next;

  @override
  void initState() {
    super.initState();
    _schedule(first: true);
  }

  void _schedule({bool first = false}) {
    final ms = first ? 800 + _rng.nextInt(3200) : 3000 + _rng.nextInt(5000);
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
            final t = Curves.easeInOutCubic.transform(_c.value);
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-1, -1),
                  end: const Alignment(1, 1),
                  colors: const [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x55FFFFFF), Color(0x00FFFFFF), Color(0x00FFFFFF)],
                  stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
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
