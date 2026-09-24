import 'package:flutter/material.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/game_header.dart';
import '../../core/widgets/pressable_card.dart';
import '../../core/widgets/stroked_text.dart';
import 'mg_data.dart';
import 'mg_translations.dart';
import 'memory_grid_game_screen.dart';

/// Memory Grid's landing screen: pick a solo difficulty, or start a 2-player
/// duel. Pushes into [MemoryGridGameScreen] configured for whichever mode
/// was chosen.
class MemoryGridHomeScreen extends StatelessWidget {
  const MemoryGridHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final t = MgText(lang);
        return Scaffold(
          backgroundColor: MgData.screenBg,
          body: SafeArea(
            child: Column(
              children: [
                GameHeader(
                  title: '',
                  onBack: () => Navigator.of(context).pop(),
                  onHelp: () => _openHow(context, t, isDuel: false),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const Text('🧠', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: 'Memory', style: AppFonts.baloo(fontSize: 30, fontWeight: FontWeight.w800)),
                              TextSpan(
                                text: ' Grid',
                                style: AppFonts.baloo(fontSize: 30, fontWeight: FontWeight.w800, color: MgData.accent2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.tagline,
                          style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white38),
                        ),
                        const SizedBox(height: 26),
                        _SectionDivider(label: t.soloHeading),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _LevelCard(
                                gridSize: 3,
                                name: t.easy,
                                desc: t.easyDesc(MgData.levels['easy']!.dots),
                                palette: MgData.easyPalette,
                                onTap: () => _start(context, level: 'easy'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _LevelCard(
                                gridSize: 4,
                                name: t.medium,
                                desc: t.easyDesc(MgData.levels['medium']!.dots),
                                palette: MgData.mediumPalette,
                                onTap: () => _start(context, level: 'medium'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _LevelCard(
                                gridSize: 5,
                                name: t.hard,
                                desc: t.easyDesc(MgData.levels['hard']!.dots),
                                palette: MgData.hardPalette,
                                onTap: () => _start(context, level: 'hard'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        _SectionDivider(label: t.duelHeading),
                        const SizedBox(height: 12),
                        _DuelCard(t: t, onTap: () => _start(context, level: null)),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
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
      MaterialPageRoute(
        builder: (_) => MemoryGridGameScreen(level: level),
      ),
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

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _line()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70),
          ),
        ),
        Expanded(child: _line()),
      ],
    );
  }

  Widget _line() => Container(
        height: 1.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [MgData.accent2.withOpacity(0), MgData.accent2.withOpacity(0.55)]),
        ),
      );
}

class _LevelCard extends StatelessWidget {
  final int gridSize;
  final String name;
  final String desc;
  final MgLevelPalette palette;
  final VoidCallback onTap;

  const _LevelCard({
    required this.gridSize,
    required this.name,
    required this.desc,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.92,
      child: PressableCard(
        topColor: palette.top,
        bottomColor: palette.bottom,
        shadowColor: palette.shadow,
        borderRadius: 24,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniGrid(size: gridSize),
              const SizedBox(height: 8),
              StrokedText(
                name,
                strokeColor: palette.textStroke,
                style: AppFonts.baloo(fontSize: 18, fontWeight: FontWeight.w800, color: palette.text),
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 8),
              Text(desc, style: AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black.withOpacity(0.65))),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniGrid extends StatelessWidget {
  final int size;
  const _MiniGrid({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: GridView.count(
        crossAxisCount: size,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        children: List.generate(size * size, (_) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

class _DuelCard extends StatelessWidget {
  final MgText t;
  final VoidCallback onTap;
  const _DuelCard({required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: PressableCard(
        topColor: MgData.duelColor,
        shadowColor: MgData.duelShadow,
        borderRadius: 24,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Text('👥', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StrokedText(
                      t.duelName,
                      textAlign: TextAlign.left,
                      style: AppFonts.baloo(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.duelSub,
                      style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ),
            ],
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
