import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/card_deck_layout.dart';
import 'thank_you_data.dart';

/// "Thank You" — the gratitude card game. Mechanically identical to First
/// (shuffled no-repeat 51-card deck; swipe, tap or footer buttons;
/// reshuffle), with its own palette and content.
///
/// Screen structure follows Figma "Thank You Home" via the shared
/// [CardDeckLayout]; the deck, copy and card artwork live only in this
/// folder (games/thank_you/).
class ThankYouScreen extends StatefulWidget {
  const ThankYouScreen({super.key});

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  static const _pageAnim = Duration(milliseconds: 250);

  final _rng = Random();
  final _controller = PageController();
  late List<ThankYouCard> _deck;
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

  List<ThankYouCard> _shuffled() => List<ThankYouCard>.of(ThankYouData.cards)..shuffle(_rng);

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
          background: AppColors.screenCoral,
          title: isHi ? 'थैंक यू' : 'Thank You',
          onBack: () => Navigator.of(context).pop(),
          onHelp: () => _openHow(isHi),
          progressIndex: _done ? total : _page + 1,
          progressTotal: total,
          prompt: _done
              ? (isHi ? 'शाबाश!' : 'All Done!')
              : (isHi ? 'आप किसके लिए आभारी हैं...' : "Share what you're grateful for..."),
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
                  : _ThankYouCardFace(card: _deck[index], isHi: isHi, scale: cardSize.height / CardDeckLayout.cardHeight);
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
            ['खिलाड़ी जुटाएं', 'कम से कम 2 खिलाड़ी। जितने ज़्यादा, उतना मज़ा!', null],
            ['कार्ड खोलें', 'एक श्रेणी दिखेगी — जैसे "एक टीचर" या "एक खाने की चीज़"।', 'उदाहरण: एक टीचर बताएं जिनके लिए आप आभारी हैं।'],
            ['सब बताएं', 'हर खिलाड़ी उस श्रेणी से कुछ बताए जिसके लिए वो शुक्रगुज़ार है।', null],
            ['किस्सा सुनाएं', 'क्यों आभारी हैं — कोई याद, वजह या एहसास।', null],
            ['अगला कार्ड', 'Next दबाएं और आभार जारी रखें!', null],
          ]
        : const [
            ['Gather Players', 'Minimum 2 players. The more the merrier!', null],
            ['Open a Card', 'A category appears — like "One Teacher" or "One Food Item".', 'Example: Name one teacher you are thankful for.'],
            ['Everyone Shares', 'Each player names something from that category they are grateful for.', null],
            ['Tell the Story', 'Share why you are thankful — a memory, a reason, a feeling.', null],
            ['Next Card', 'Tap Next Card and keep the gratitude going!', null],
          ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _HowSheet(
        title: isHi ? 'कैसे खेलें' : 'How to Play',
        goalTitle: isHi ? '😇 खेल का मकसद' : '😇 Goal of the Game',
        goalText: isHi
            ? 'रुकें, सोचें और बताएं कि आप किन चीज़ों के लिए सच में आभारी हैं। साथ जुड़ने और जीवन की कद्र करने का खूबसूरत तरीका।'
            : 'Pause, reflect, and share what you are truly grateful for. A beautiful way to connect and appreciate life together.',
        badgeColors: const [Color(0xFF4ADE80), Color(0xFF16A34A)],
        badgeTextColor: Colors.white,
        steps: steps,
      ),
    );
  }
}

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

/// One Thank You card, drawn to fit the Figma card slot (240×320, radius
/// 24). [scale] = actual card height / 320.
class _ThankYouCardFace extends StatelessWidget {
  final ThankYouCard card;
  final bool isHi;
  final double scale;
  const _ThankYouCardFace({required this.card, required this.isHi, required this.scale});

  @override
  Widget build(BuildContext context) {
    final color = ThankYouData.palette[(card.paletteIndex - 1) % ThankYouData.palette.length];
    final s = scale;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24 * s),
        boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 26, offset: Offset(0, 10))],
      ),
      child: Padding(
        padding: EdgeInsets.all(8 * s),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withAlpha(56), width: 2),
            borderRadius: BorderRadius.circular(16 * s),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 18 * s),
            child: Column(
              children: [
                Text(
                  isHi ? card.titleHi : card.titleEn,
                  textAlign: TextAlign.center,
                  style: AppFonts.baloo(fontSize: 20 * s, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: 0.4),
                ),
                SizedBox(height: 6 * s),
                Text(
                  isHi ? card.subHi : card.subEn,
                  textAlign: TextAlign.center,
                  style: AppFonts.baloo(fontSize: 12 * s, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: 1.0, color: Colors.white.withAlpha(184)),
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(card.icon, style: TextStyle(fontSize: 72 * s)),
                    ),
                  ),
                ),
                // Category label has no Hindi translation in the original
                // data — always shown in English.
                Text(
                  card.cat,
                  textAlign: TextAlign.center,
                  style: AppFonts.baloo(fontSize: 12 * s, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: 1.2, color: Colors.white.withAlpha(199)),
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
          Text('😇', style: TextStyle(fontSize: 64 * scale)),
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
