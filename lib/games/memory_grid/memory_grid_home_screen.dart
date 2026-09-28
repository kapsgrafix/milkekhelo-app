import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/game_header.dart';
import '../../core/widgets/pressable_card.dart';
import '../../core/widgets/screen_bottom_bar.dart';
import 'memory_grid_game_screen.dart';
import 'mg_data.dart';
import 'mg_translations.dart';

/// Memory Grid landing page — Figma "Memory Grid L1" (14:1392, 360×720):
///   0    Header (Game Empty)                                     56
///   76   Hero: 120px icon · "Memory Grid" (h1) · tagline        182
///   282  Section Divider "Solo — Beat Your Best"                 20
///   314  3 × Difficulty Card (104 wide, 12 gap)                 150 + 5 ledge
///   498  Section Divider "Play Together"                         20
///   530  Choice Card "2 Players Offline"                          89 + 5 ledge
///   670  Bottom bar                                              50
class MemoryGridHomeScreen extends StatelessWidget {
  const MemoryGridHomeScreen({super.key});

  static const _heroIcon = 'assets/home/memory_grid.webp';

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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
                    child: Column(
                      children: [
                        _Hero(t: t, icon: _heroIcon),
                        const SizedBox(height: 24),
                        _SectionDivider(label: t.soloHeading),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _DifficultyCard(
                                image: 'assets/memory_grid/solo_easy.webp',
                                name: t.easy,
                                blocks: t.easyDesc(MgData.levels['easy']!.dots),
                                play: t.play,
                                palette: MgData.easyCard,
                                onTap: () => _start(context, level: 'easy'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DifficultyCard(
                                image: 'assets/memory_grid/solo_medium.webp',
                                name: t.medium,
                                blocks: t.easyDesc(MgData.levels['medium']!.dots),
                                play: t.play,
                                palette: MgData.mediumCard,
                                onTap: () => _start(context, level: 'medium'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DifficultyCard(
                                image: 'assets/memory_grid/solo_hard.webp',
                                name: t.hard,
                                blocks: t.easyDesc(MgData.levels['hard']!.dots),
                                play: t.play,
                                palette: MgData.hardCard,
                                onTap: () => _start(context, level: 'hard'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 29), // 34 − 5px ledge
                        _SectionDivider(label: t.duelHeading),
                        const SizedBox(height: 12),
                        _ChoiceCard(t: t, onTap: () => _start(context, level: null)),
                      ],
                    ),
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

/// 120px game icon, "Memory Grid" (heading/h1: ExtraBold 28 / 115%, second
/// word in #6EE0AC) and the tagline (body/small: Medium 13 / 135%, muted).
class _Hero extends StatelessWidget {
  final MgText t;
  final String icon;
  const _Hero({required this.t, required this.icon});

  @override
  Widget build(BuildContext context) {
    final h1 = AppFonts.baloo(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15);
    return Column(
      children: [
        Image.asset(icon, width: 120, height: 120, fit: BoxFit.contain, filterQuality: FilterQuality.high),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: t.titleA, style: h1),
            TextSpan(text: t.titleB, style: h1.copyWith(color: MgData.titleAccent)),
          ]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          t.tagline,
          textAlign: TextAlign.center,
          style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w500, height: 1.35, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Figma "Section Divider": 6px dot · dashed line · label (Bold 13) ·
/// dashed line · 6px dot, 10px gaps.
class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    Widget dot() => Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: MgData.titleAccent, shape: BoxShape.circle),
        );
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          dot(),
          const SizedBox(width: 10),
          const Expanded(child: CustomPaint(size: Size(double.infinity, 1.5), painter: _DashPainter())),
          const SizedBox(width: 10),
          Text(label, style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          const Expanded(child: CustomPaint(size: Size(double.infinity, 1.5), painter: _DashPainter())),
          const SizedBox(width: 10),
          dot(),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = MgData.titleAccent.withAlpha(140)
      ..strokeWidth = 1.5;
    const dash = 4.0, gap = 4.0;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width).toDouble(), y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Figma "Difficulty Card": gradient face, radius 16, 5px ledge.
/// Body (12 top / 8 sides / 10 bottom, 10 gap): 74×51 art (radius 6),
/// name ExtraBold 15 / 110% white, blocks Medium 11 on-light.
/// 1px 18%-black divider, then a 32px footer in the bottom colour with
/// "Play →" Bold 13 on-light.
class _DifficultyCard extends StatelessWidget {
  final String image;
  final String name;
  final String blocks;
  final String play;
  final MgCardPalette palette;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.image,
    required this.name,
    required this.blocks,
    required this.play,
    required this.palette,
    required this.onTap,
  });

  static const double faceHeight = 150.23;
  static const double ledge = 5;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$name, $blocks',
      child: SizedBox(
        height: faceHeight + ledge,
        child: PressableCard(
          topColor: palette.top,
          bottomColor: palette.bottom,
          shadowColor: palette.shadow,
          borderRadius: 16,
          shadowOffset: ledge,
          pressedOffset: 3,
          pressedOverlayColor: const Color(0x2E000000),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(image, width: 74, height: 51.23, fit: BoxFit.cover, filterQuality: FilterQuality.high),
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(name, maxLines: 1, style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w800, height: 1.1)),
                        ),
                        Text(
                          blocks,
                          maxLines: 1,
                          style: AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.textOnLight),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 1, color: const Color(0x2E000000)),
                Container(
                  height: 32,
                  width: double.infinity,
                  color: palette.bottom,
                  alignment: Alignment.center,
                  child: Text(play, style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textOnLight)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma "Choice Card": purple gradient, radius 24, 5px ledge, 16 padding,
/// 12 gap — 56px art · title (ExtraBold 16) + subtitle (Medium 12 / 128%)
/// · 40px round arrow badge (25% white).
class _ChoiceCard extends StatelessWidget {
  final MgText t;
  final VoidCallback onTap;
  const _ChoiceCard({required this.t, required this.onTap});

  static const double faceHeight = 89;
  static const double ledge = 5;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: t.duelName,
      child: SizedBox(
        height: faceHeight + ledge,
        child: PressableCard(
          topColor: MgData.duelCard.top,
          bottomColor: MgData.duelCard.bottom,
          shadowColor: MgData.duelCard.shadow,
          borderRadius: 24,
          shadowOffset: ledge,
          pressedOffset: 3,
          pressedOverlayColor: const Color(0x2E000000),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Image.asset('assets/memory_grid/two_players.webp',
                    width: 56, height: 56, fit: BoxFit.contain, filterQuality: FilterQuality.high),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.duelName, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(t.duelSub, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w500, height: 1.28)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: Color(0x40FFFFFF), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ),
              ],
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
