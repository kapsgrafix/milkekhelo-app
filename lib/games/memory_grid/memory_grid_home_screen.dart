import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/game_header.dart';
import '../../core/widgets/game_landing_body.dart';
import '../../core/widgets/heartbeat.dart';
import '../../core/widgets/pressable_card.dart';
import '../../core/widgets/screen_bottom_bar.dart';
import 'memory_grid_game_screen.dart';
import 'mg_data.dart';
import 'mg_translations.dart';

/// Memory Grid landing page — Figma "Memory Grid L1 V2" (290:1909, 360×720).
/// Layout: hero art · 48 · mode cards form one unit, centred vertically
/// via [GameLandingBody]. Figma reference positions:
///   0    Header (Game Empty)                                     56
///   96   Hero art (name baked in, EN/HI)                        180
///   327  Solo - Easy  (green,  312×80, radius 16, 5px ledge)
///        · 24 ·
///        Solo - Hard  (red,    312×80, radius 16, 5px ledge)
///        · 24 ·
///        2 Players    (yellow, 312×80, radius 16, 5px ledge)
///   670  Bottom bar                                              50
/// Title heading/h1 (ExtraBold 28 / 115%), subtitle body/base
/// (Medium 15 / 140%), both white. Cards pulse gently (shared [Heartbeat]).
///
/// Phase 2: Medium is no longer offered here (still defined in [MgData]).
class MemoryGridHomeScreen extends StatelessWidget {
  const MemoryGridHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final t = MgText(lang);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Color.alphaBlend(AppColors.surface, MgData.screenBg),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: MgData.screenBg,
            body: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: GameHeader(
                    title: '',
                    onBack: () => Navigator.of(context).pop(),
                    onHelp: () => _openHow(context, t, isDuel: false),
                  ),
                ),
                Expanded(
                  child: GameLandingBody(
                    // Hero art (game name is part of the picture): 180×180.
                    hero: Image.asset(
                          // EN: dedicated 360px hero art (sharp at 2×);
                          // HI: the Hindi home-card art until a 360px version exists.
                          lang == AppLang.hi ? 'assets/home/card_memory_grid_hi.webp' : 'assets/memory_grid/hero_en.webp',
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          semanticLabel: t.titleA + t.titleB,
                        ),
                        variants: [
                        Heartbeat(
                          child: _ModeCard(
                            title: t.soloEasy,
                            subtitle: t.beatYourBest,
                            palette: MgData.easyCard,
                            onTap: () => _start(context, level: 'easy'),
                          ),
                        ),
                        const SizedBox(height: 24 - _ModeCard.ledge),
                        Heartbeat(
                          delay: const Duration(milliseconds: 260),
                          child: _ModeCard(
                            title: t.soloHard,
                            subtitle: t.beatYourBest,
                            palette: MgData.hardCard,
                            onTap: () => _start(context, level: 'hard'),
                          ),
                        ),
                        const SizedBox(height: 24 - _ModeCard.ledge),
                        Heartbeat(
                          delay: const Duration(milliseconds: 520),
                          child: _ModeCard(
                            title: t.twoPlayers,
                            subtitle: t.twoPlayersSub,
                            palette: MgData.twoPlayerCard,
                            onTap: () => _start(context, level: null),
                          ),
                        ),
                      ],
                  ),
                ),
                const ScreenBottomBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _start(BuildContext context, {String? level}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MemoryGridGameScreen(level: level)),
    );
  }

  void _openHow(BuildContext context, MgText t, {required bool isDuel}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MgHowToPlaySheet(t: t, isDuel: isDuel),
    );
  }
}

/// Figma L1 V2 mode card: 312×80 gradient face (top → bottom colour),
/// radius 16, 5px solid ledge; centred white title (h1, thin outline in the
/// ledge colour) over subtitle (body/base). Pressed = 18% black overlay plus the shared press-down.
class _ModeCard extends StatelessWidget {
  static const double faceHeight = 80;
  static const double ledge = 5;

  final String title;
  final String subtitle;
  final MgCardPalette palette;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h1 = AppFonts.baloo(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15);
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 312),
        child: SizedBox(
          height: faceHeight + ledge,
          child: PressableCard(
            topColor: palette.top,
            bottomColor: palette.bottom,
            shadowColor: palette.shadow,
            borderRadius: 16,
            shadowOffset: ledge,
            pressedOverlayColor: const Color(0x2E000000),
            onTap: onTap,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // White title over a thin outline in the ledge colour
                    // (same treatment as the Snakes & Ladders mode cards).
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            style: h1.copyWith(
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 3
                                ..strokeJoin = StrokeJoin.round
                                ..color = palette.shadow,
                            ),
                          ),
                          Text(title, maxLines: 1, style: h1),
                        ],
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared how-to-play sheet used by both the home screen (defaults to solo
/// steps) and the in-game help button (uses whichever mode is active).
class MgHowToPlaySheet extends StatelessWidget {
  final MgText t;
  final bool isDuel;
  const MgHowToPlaySheet({super.key, required this.t, required this.isDuel});

  @override
  Widget build(BuildContext context) {
    final steps = isDuel ? t.howStepsDuel : t.howStepsSolo;
    return Container(
      // Clear the phone's gesture / navigation bar.
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + MediaQuery.viewPaddingOf(context).bottom),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12442B), Color(0xFF0A2418)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(t.howTitle, style: AppFonts.baloo(fontSize: 22, fontWeight: FontWeight.w800, color: MgData.gold)),
            const SizedBox(height: 20),
            for (int i = 0; i < steps.length; i++) ...[
              _MgStep(number: i + 1, title: steps[i][0], desc: steps[i][1]),
              if (i != steps.length - 1) const SizedBox(height: 16),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MgData.accent2.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MgData.accent2.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.goalTitle, style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(t.goalText, style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MgStep extends StatelessWidget {
  final int number;
  final String title;
  final String desc;
  const _MgStep({required this.number, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [MgData.accent2, MgData.accent]),
          ),
          child: Text('$number', style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(desc, style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60)),
            ],
          ),
        ),
      ],
    );
  }
}
