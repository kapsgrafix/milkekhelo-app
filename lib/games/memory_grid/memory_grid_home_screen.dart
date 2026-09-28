import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/game_header.dart';
import '../../core/widgets/heartbeat.dart';
import '../../core/widgets/pressable_card.dart';
import '../../core/widgets/screen_bottom_bar.dart';
import 'memory_grid_game_screen.dart';
import 'mg_data.dart';
import 'mg_translations.dart';

/// Memory Grid landing page — Figma "Memory Grid L1" (14:1392, 360×720):
///   0    Header (Game Empty)                                     56
///   0    Glow panel (280 tall, 40px bottom radius) behind the top
///   76   Hero art (name baked in, EN/HI)                         180
///   308  Section title "Solo - Beat Your Best" (SemiBold 16, left) · 12 ·
///        3 × Difficulty Card (104 wide, 12 gap)                 150 + 5 ledge
///        · 24 · Section title "Play Together" · 12 ·
///        Choice Card "2 Players Offline"                          88 + 5 ledge
///   All cards pulse gently (shared [Heartbeat]), staggered left → right.
///   670  Bottom bar                                              50
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
            body: Stack(
              children: [
                // Figma: 280px top panel with a soft green glow toward the
                // bottom-right and 40px rounded bottom corners, sitting
                // behind the header and hero art.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).padding.top + 280,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                      gradient: LinearGradient(
                        // CSS linear-gradient(155.15deg, transparent 46.5%, rgba(40,251,42,.2) 100%)
                        begin: Alignment(-0.473, -1.313),
                        end: Alignment(0.473, 1.313),
                        colors: [Color(0x0028FB2A), Color(0x0028FB2A), Color(0x3328FB2A)],
                        stops: [0, 0.465, 1],
                      ),
                    ),
                  ),
                ),
                Column(
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
                        // Hero art (game name is part of the picture): 180×180.
                        Image.asset(
                          // EN: dedicated 360px hero art (sharp at 2×);
                          // HI: the Hindi home-card art until a 360px version exists.
                          lang == AppLang.hi ? 'assets/home/card_memory_grid_hi.webp' : 'assets/memory_grid/hero_en.webp',
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          semanticLabel: t.titleA + t.titleB,
                        ),
                        const SizedBox(height: 52),
                        _SectionTitle(label: t.soloHeading),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Heartbeat(
                                delay: const Duration(milliseconds: 0),
                                child: _DifficultyCard(
                                image: 'assets/memory_grid/diff_easy.webp',
                                name: t.easy,
                                blocks: t.easyDesc(MgData.levels['easy']!.dots),
                                play: t.play,
                                palette: MgData.easyCard,
                                onTap: () => _start(context, level: 'easy'),
                              ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Heartbeat(
                                delay: const Duration(milliseconds: 220),
                                child: _DifficultyCard(
                                image: 'assets/memory_grid/diff_medium.webp',
                                name: t.medium,
                                blocks: t.easyDesc(MgData.levels['medium']!.dots),
                                play: t.play,
                                palette: MgData.mediumCard,
                                onTap: () => _start(context, level: 'medium'),
                              ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Heartbeat(
                                delay: const Duration(milliseconds: 440),
                                child: _DifficultyCard(
                                image: 'assets/memory_grid/diff_hard.webp',
                                name: t.hard,
                                blocks: t.easyDesc(MgData.levels['hard']!.dots),
                                play: t.play,
                                palette: MgData.hardCard,
                                onTap: () => _start(context, level: 'hard'),
                              ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 19), // Figma 24 gap − 5px ledge
                        _SectionTitle(label: t.duelHeading),
                        const SizedBox(height: 12),
                        Heartbeat(
                          delay: const Duration(milliseconds: 660),
                          child: _ChoiceCard(t: t, onTap: () => _start(context, level: null)),
                        ),
                      ],
                    ),
                  ),
                ),
                const ScreenBottomBar(),
              ],
            ),
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

/// Figma "Section Divider" (latest L1): a left-aligned section title,
/// SemiBold 16, text/primary — no dots or lines.
class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}

/// Figma "Difficulty Card": gradient face, radius 16, 5px ledge.
/// Body (8px padding): 84×84 art (difficulty name is part of the art),
/// "n blocks" Medium 11 on-light. 1px 18%-black divider, then a 32px footer
/// in the bottom colour with "Play →" Bold 13 white.
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

  static const double faceHeight = 8 + 84 + 17 + 8 + 1 + 32; // 150
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
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(image, width: 84, height: 84, fit: BoxFit.contain, filterQuality: FilterQuality.high),
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
                  child: Text(play, style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
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

  static const double faceHeight = 12 + 64 + 12; // 88
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Image.asset('assets/memory_grid/two_players.webp',
                    width: 64, height: 64, fit: BoxFit.contain, filterQuality: FilterQuality.high),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Figma: white title with a thin dark-purple outline
                      // (outline layer underneath, white fill on top).
                      Stack(
                        children: [
                          Text(t.duelName, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w800).copyWith(
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 2.5
                                  ..strokeJoin = StrokeJoin.round
                                  ..color = MgData.duelCard.shadow,
                              )),
                          Text(t.duelName, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w800)),
                        ],
                      ),
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
