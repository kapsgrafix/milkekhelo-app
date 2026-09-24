import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'chunky_button.dart';
import 'game_header.dart';
import 'screen_bottom_bar.dart';

/// Screen structure shared by the card-deck games (First, Thank You) —
/// Figma frames "First Home" (8:201) and "Thank You Home" (8:283), 360×720:
///
///   0    Header                                   56
///   80   Progress Bar (12px side padding)         14
///   138  Prompt (label/card, action/primary)      20
///        · 24 ·
///        Card slot                                240×320, radius 24
///        · 24 ·
///        Hint (caption/default, text/muted)       14
///   574  Action Footer (Back · Next Card · Refresh) 72
///   670  Bottom bar                               50
///
/// Gaps around the prompt/card/hint group are flex (44 : 34, as in Figma),
/// so it is exact on a 720pt screen and balances on taller ones. On short
/// screens the card shrinks (keeping 3:4) before anything overflows.
///
/// This widget is layout only — each game keeps its own deck, state, copy
/// and card artwork and passes the card area in as [cardArea].
class CardDeckLayout extends StatelessWidget {
  final Color background;
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onHelp;

  /// 1-based position shown as "index/total".
  final int progressIndex;
  final int progressTotal;

  final String prompt;
  final String hint;

  /// Builds the swipeable card area for the given card size. It is given the
  /// full screen width so swipes work edge to edge; cards should be centred
  /// at [cardSize].
  final Widget Function(BuildContext context, Size cardSize) cardArea;

  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final VoidCallback onRefresh;
  final String nextLabel;

  const CardDeckLayout({
    super.key,
    required this.background,
    required this.title,
    required this.onBack,
    this.onHelp,
    required this.progressIndex,
    required this.progressTotal,
    required this.prompt,
    required this.hint,
    required this.cardArea,
    required this.onPrevious,
    required this.onNext,
    required this.onRefresh,
    required this.nextLabel,
  });

  static const double cardWidth = 240;
  static const double cardHeight = 320;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color.alphaBlend(AppColors.surface, background),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: background,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: GameHeader(title: title, onBack: onBack, onHelp: onHelp),
            ),
            const SizedBox(height: 24),
            DeckProgressBar(index: progressIndex, total: progressTotal),
            Expanded(child: _buildMiddle()),
            CardDeckFooter(
              onPrevious: onPrevious,
              onNext: onNext,
              onRefresh: onRefresh,
              nextLabel: nextLabel,
            ),
            const SizedBox(height: 24),
            const ScreenBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMiddle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // prompt (16 × 1.25) + hint (11 × 1.3) + two 24px gaps.
        const fixed = 20.0 + 14.3 + 24 + 24;
        final available = constraints.maxHeight - fixed - 16; // keep a little breathing room
        final h = available.clamp(120.0, cardHeight).toDouble();
        final cardSize = Size(h * cardWidth / cardHeight, h);
        return Column(
          children: [
            const Spacer(flex: 44),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                prompt,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.labelCard(color: AppColors.actionPrimary),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(height: cardSize.height, child: cardArea(context, cardSize)),
            const SizedBox(height: 24),
            SizedBox(
              width: cardWidth,
              child: Text(
                hint,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption(),
              ),
            ),
            const Spacer(flex: 34),
          ],
        );
      },
    );
  }
}

/// Figma "Progress Bar": 12px side padding, 12px gap, 10px pill track in
/// background/surface with a brand/yellow fill, "n/total" counter
/// (SemiBold 13 / 14px, text/muted).
class DeckProgressBar extends StatelessWidget {
  final int index;
  final int total;
  const DeckProgressBar({super.key, required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    final double fraction = total == 0 ? 0.0 : (index / total).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  // Figma shows a 14px fill at 1/51 — never let the fill be
                  // smaller than that so the first card still reads as started.
                  final fillWidth = (c.maxWidth * fraction).clamp(14.0, c.maxWidth).toDouble();
                  return Container(
                    height: 10,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      width: fillWidth,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.brandYellow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Text('$index/$total', style: AppText.progress()),
          ],
        ),
      ),
    );
  }
}

/// Figma "Action Footer / Type=Card Deck": 12px padding, 12px gaps —
/// Back (Secondary, 48²) · Next Card (Primary, flex) · Refresh (Secondary, 48²).
class CardDeckFooter extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final VoidCallback onRefresh;
  final String nextLabel;

  const CardDeckFooter({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.onRefresh,
    required this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    // 12 top padding, 48 button + 4 bevel, 8 bottom = 72 (bevel sits inside
    // the bottom padding, as in Figma).
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          ChunkyButton.icon(icon: Icons.arrow_back_rounded, semanticLabel: 'Previous card', onTap: onPrevious),
          const SizedBox(width: 12),
          Expanded(child: ChunkyButton(label: nextLabel, onTap: onNext)),
          const SizedBox(width: 12),
          ChunkyButton.icon(icon: Icons.refresh_rounded, semanticLabel: 'Shuffle', onTap: onRefresh),
        ],
      ),
    );
  }
}
