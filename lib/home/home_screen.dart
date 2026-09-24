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

/// The launcher / home screen — built to the Figma frame "Home - L0"
/// (MilkeKhelo-Design, node 6:159, 360×720).
///
/// Figma layout (y from frame top):
///   0   Header (12px padding, 32px controls)          → 56 tall
///   156 Logo lockup (wordmark / heart divider / tagline) → 74 tall
///   308 2×2 Game Module Cards (152×148, gap 16×22, 6px ledge)
///   670 Bottom bar (50px, background/surface)
///
/// The vertical gaps (100 / 78 / 38) are flex spacers so the layout is
/// pixel-exact on a 720pt-tall screen and scales proportionally on taller
/// or shorter phones. If a screen is too short, the content scrolls.
///
/// This screen holds no game logic — each card just pushes that game's route.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.surfaceOnScreen,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.screenBackground,
        body: ValueListenableBuilder<AppLang>(
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
                  const _LogoLockup(),
                  const Spacer(flex: 78),
                  _GameGrid(isHi: isHi),
                  const Spacer(flex: 38),
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
              child: _MenuButton(onTap: () {
                // TODO: menu (Policy etc.) — not part of the Home - L0 frame.
              }),
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
  const _LogoLockup();

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
            'Play Offline. Connect for Real.',
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

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final cards = [
      _GameModuleCard(
        palette: AppColors.snakesAndLadders,
        image: 'assets/home/snakes_and_ladders.webp',
        label: isHi ? 'स्नेक्स एंड लैडर्स' : 'Snakes & Ladders',
        onTap: () => _push(context, const SnlScreen()),
      ),
      _GameModuleCard(
        palette: AppColors.memoryGrid,
        image: 'assets/home/memory_grid.webp',
        label: isHi ? 'मेमोरी ग्रिड' : 'Memory Grid',
        onTap: () => _push(context, const MemoryGridHomeScreen()),
      ),
      _GameModuleCard(
        palette: AppColors.first,
        image: 'assets/home/first.webp',
        label: isHi ? 'माई फर्स्ट' : 'My First',
        onTap: () => _push(context, const FirstScreen()),
      ),
      _GameModuleCard(
        palette: AppColors.thankYou,
        image: 'assets/home/thank_you.webp',
        label: isHi ? 'थैंक यू' : 'Thank You',
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

/// Figma "Game Module Card" (Size=Large): gradient face, radius 24,
/// 6px solid drop-shadow ledge, 16 top / 12 bottom padding, 92×92 art,
/// 8px gap, label Baloo 2 ExtraBold 16 / 1.25 in text/primary.
/// Pressed = 18% black overlay (plus the shared 3px press-down).
class _GameModuleCard extends StatelessWidget {
  static const double faceHeight = 16 + 92 + 8 + 20 + 12; // 148
  static const double ledge = 6;

  final GameCardPalette palette;
  final String image;
  final String label;
  final VoidCallback onTap;

  const _GameModuleCard({
    required this.palette,
    required this.image,
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  image,
                  width: 92,
                  height: 92,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
                const SizedBox(height: 8),
                // Scales down (never wraps) if a longer Hindi label
                // wouldn't fit the card width.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: AppText.labelCard(),
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
