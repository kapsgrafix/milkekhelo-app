import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/card_deck_layout.dart';
import 'first_data.dart';

/// "First" — the icebreaker card game. A shuffled, no-repeat deck of 51
/// prompts; swipe, tap the card or use the footer buttons to move through
/// them, then reshuffle for another round.
///
/// Screen structure follows Figma "First Home" via the shared
/// [CardDeckLayout]; the deck, copy and card artwork live only in this
/// folder (games/first/).
class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  static const _pageAnim = Duration(milliseconds: 250);

  final _rng = Random();
  final _controller = PageController();
  late List<FirstCard> _deck;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _deck = _shuffled();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<FirstCard> _shuffled() => List<FirstCard>.of(FirstData.cards)..shuffle(_rng);

  /// True once the player has moved past the last card (the "All done" page).
  bool get _done => _page >= _deck.length;

  void _next() {
    if (_done) {
      _reshuffle();
    } else {
      _controller.nextPage(duration: _pageAnim, curve: Curves.easeOut);
    }
  }

  void _previous() => _controller.previousPage(duration: _pageAnim, curve: Curves.easeOut);

  void _reshuffle() {
    setState(() {
      _deck = _shuffled();
      _page = 0;
    });
    if (_controller.hasClients) _controller.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final isHi = lang == AppLang.hi;
        final total = _deck.length;
        return CardDeckLayout(
          background: AppColors.screenPurple,
          title: isHi ? 'फर्स्ट' : 'First',
          onBack: () => Navigator.of(context).pop(),
          onHelp: () => _openHow(isHi),
          progressIndex: _done ? total : _page + 1,
          progressTotal: total,
          prompt: _done
              ? (isHi ? 'शाबाश!' : 'All Done!')
              : (isHi ? 'अपनी कहानी बताएं...' : 'Share the story of your...'),
          hint: _done
              ? (isHi ? 'सभी $total कार्ड देख लिए!' : "You've gone through all $total cards!")
              : (isHi ? 'कार्ड दबाएं या स्वाइप करें' : 'Tap card or swipe to flip'),
          onPrevious: _page > 0 ? _previous : null,
          onNext: _next,
          onRefresh: _reshuffle,
          nextLabel: _done ? (isHi ? 'फिर खेलें' : 'Play Again') : (isHi ? 'अगला कार्ड →' : 'Next Card →'),
          cardArea: (context, cardSize) => PageView.builder(
            controller: _controller,
            itemCount: total + 1, // + the "All done" page
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (context, index) {
              final Widget face = index >= total
                  ? _EndCard(isHi: isHi, scale: cardSize.height / CardDeckLayout.cardHeight)
                  : _FirstCardFace(card: _deck[index], isHi: isHi, scale: cardSize.height / CardDeckLayout.cardHeight);
              return Center(
                child: GestureDetector(
                  onTap: _next,
                  child: SizedBox.fromSize(size: cardSize, child: face),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openHow(bool isHi) {
    final steps = isHi
        ? const [
            ['खिलाड़ी जुटाएं', 'कम से कम 2 खिलाड़ी होने चाहिए।', null],
            ['कार्ड खोलें', 'स्क्रीन पर एक "First" सवाल दिखेगा।', 'उदाहरण: आपकी पहली थिएटर फिल्म?'],
            ['सब जवाब दें', 'सभी खिलाड़ी बारी-बारी जवाब बताएं।', null],
            ['किस्सा सुनाएं', 'चाहें तो अपनी यादें भी साझा करें।', null],
            ['अगला कार्ड', 'Next Card दबाएं और जारी रखें!', null],
          ]
        : const [
            ['Gather Players', 'Minimum 2 players are required.', null],
            ['Open a Card', 'A "First" question appears on screen.', 'Example: What was your first movie in a theatre?'],
            ['Everyone Answers', 'Players take turns sharing their answer.', null],
            ['Share the Story', 'Add a memory or story behind your answer.', null],
            ['Next Card', 'Tap Next Card and keep playing!', null],
          ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _HowSheet(
        title: isHi ? 'कैसे खेलें' : 'How to Play',
        goalTitle: isHi ? '🎯 खेल का मकसद' : '🎯 Goal of the Game',
        goalText: isHi
            ? 'एक-दूसरे को जानने का, यादें साझा करने का और मौज करने का मज़ेदार तरीका।'
            : 'A fun way to break the ice, share memories, and get to know each other better.',
        badgeColors: const [Color(0xFFFFD700), Color(0xFFFF8C00)],
        badgeTextColor: const Color(0xFF1A1A2E),
        steps: steps,
      ),
    );
  }
}

/// Shared how-to-play sheet shape, parameterised by colors/text so First and
/// Thank You each keep their own copy (no cross-game shared widget needed
/// for just this).
class _HowSheet extends StatelessWidget {
  final String title;
  final String goalTitle;
  final String goalText;
  final List<Color> badgeColors;
  final Color badgeTextColor;
  final List<List<String?>> steps;

  const _HowSheet({
    required this.title,
    required this.goalTitle,
    required this.goalText,
    required this.badgeColors,
    required this.badgeTextColor,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1040), Color(0xFF0D2040)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
            Text(title, style: AppFonts.baloo(fontSize: 22, fontWeight: FontWeight.w800, color: badgeColors.first)),
            const SizedBox(height: 20),
            for (int i = 0; i < steps.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: badgeColors)),
                    child: Text('${i + 1}', style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w800, color: badgeTextColor)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i][0]!, style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(steps[i][1]!, style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60)),
                        if (steps[i].length > 2 && steps[i][2] != null) ...[
                          const SizedBox(height: 4),
                          Text(steps[i][2]!, style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white38).copyWith(fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (i != steps.length - 1) const SizedBox(height: 16),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goalTitle, style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(goalText, style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One First card, drawn to fit the Figma card slot (240×320, radius 24).
/// [scale] = actual card height / 320, so the artwork shrinks proportionally
/// on very short screens.
class _FirstCardFace extends StatelessWidget {
  final FirstCard card;
  final bool isHi;
  final double scale;
  const _FirstCardFace({required this.card, required this.isHi, required this.scale});

  @override
  Widget build(BuildContext context) {
    final cat = FirstData.categories[card.catKey]!;
    final textColor = cat.darkText ? const Color(0xFF1A1A2E) : Colors.white;
    final s = scale;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cat.color,
        borderRadius: BorderRadius.circular(24 * s),
        boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 26, offset: Offset(0, 10))],
      ),
      child: Padding(
        padding: EdgeInsets.all(8 * s),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: (cat.darkText ? Colors.black : Colors.white).withAlpha(56), width: 2),
            borderRadius: BorderRadius.circular(16 * s),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 18 * s),
            child: Column(
              children: [
                Text(
                  isHi ? card.titleHi : card.titleEn,
                  textAlign: TextAlign.center,
                  style: AppFonts.baloo(fontSize: 20 * s, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: 0.4, color: textColor),
                ),
                SizedBox(height: 6 * s),
                Text(
                  isHi ? card.subHi : card.subEn,
                  textAlign: TextAlign.center,
                  style: AppFonts.baloo(fontSize: 12 * s, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: 1.0, color: textColor.withAlpha(184)),
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(card.icon, style: TextStyle(fontSize: 72 * s)),
                    ),
                  ),
                ),
                Text(
                  isHi ? cat.nameHi : cat.nameEn,
                  textAlign: TextAlign.center,
                  style: AppFonts.baloo(fontSize: 12 * s, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: 1.2, color: textColor.withAlpha(199)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The last page of the deck, shown in the card slot after card 51.
class _EndCard extends StatelessWidget {
  final bool isHi;
  final double scale;
  const _EndCard({required this.isHi, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎉', style: TextStyle(fontSize: 64 * scale)),
          SizedBox(height: 12 * scale),
          Text(
            isHi ? 'एक और राउंड खेलें?' : 'Ready for another round?',
            textAlign: TextAlign.center,
            style: AppText.labelCard(),
          ),
        ],
      ),
    );
  }
}
