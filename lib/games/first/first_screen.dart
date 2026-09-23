import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/game_header.dart';
import 'first_data.dart';

/// "First" — the icebreaker card game. A shuffled, no-repeat deck of 51
/// prompts; swipe or use the buttons to move through them, then reshuffle
/// for another round. Entirely self-contained: nothing outside
/// games/first/ references it.
class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  final _rng = Random();
  late List<FirstCard> _deck;
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _deck = _shuffled();
    _controller = PageController();
  }

  List<FirstCard> _shuffled() => List<FirstCard>.of(FirstData.cards)..shuffle(_rng);

  void _reshuffle() {
    setState(() {
      _deck = _shuffled();
      _page = 0;
    });
    _controller.jumpToPage(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final isHi = lang == AppLang.hi;
        final total = _deck.length;
        final onLastCard = _page >= total;
        return Scaffold(
          backgroundColor: const Color(0xFF1B0F3D),
          body: SafeArea(
            child: Column(
              children: [
                GameHeader(
                  title: isHi ? 'फर्स्ट' : 'First',
                  onBack: () => Navigator.of(context).pop(),
                  onHelp: () => _openHow(isHi),
                ),
                if (!onLastCard) _buildProgress(total),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: total + 1,
                    onPageChanged: (p) => setState(() => _page = p),
                    itemBuilder: (context, index) {
                      if (index >= total) return _buildEndScreen(isHi);
                      return _buildCardPage(_deck[index], isHi, total);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgress(int total) {
    final fraction = ((_page + 1) / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('${_page + 1}/$total', style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFBABABA))),
        ],
      ),
    );
  }

  Widget _buildCardPage(FirstCard card, bool isHi, int total) {
    final cat = FirstData.categories[card.catKey]!;
    final textColor = cat.darkText ? const Color(0xFF1A1A2E) : Colors.white;
    return Column(
      children: [
        const SizedBox(height: 6),
        Text(
          isHi ? 'अपनी कहानी बताएं...' : 'Share the story of your...',
          textAlign: TextAlign.center,
          style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFFFFC53D)),
        ),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cat.color,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 26, offset: Offset(0, 10))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: (cat.darkText ? Colors.black : Colors.white).withOpacity(0.22), width: 2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text(
                                  isHi ? card.titleHi : card.titleEn,
                                  textAlign: TextAlign.center,
                                  style: AppFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isHi ? card.subHi : card.subEn,
                                  textAlign: TextAlign.center,
                                  style: AppFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textColor.withOpacity(0.72),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Text(card.icon, style: const TextStyle(fontSize: 88)),
                            Text(
                              isHi ? cat.nameHi : cat.nameEn,
                              textAlign: TextAlign.center,
                              style: AppFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                                color: textColor.withOpacity(0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(
          isHi ? 'कार्ड दबाएं या स्वाइप करें' : 'Tap card or swipe to flip',
          style: AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFBABABA), letterSpacing: 0.4),
        ),
        const SizedBox(height: 12),
        _buildActionBar(isHi, total),
      ],
    );
  }

  Widget _buildActionBar(bool isHi, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          _roundBtn('←', _page > 0 ? () => _controller.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut) : null),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFC97F00)]),
                  boxShadow: const [BoxShadow(color: Color(0xFF7A4B00), offset: Offset(0, 4))],
                ),
                child: Text(
                  isHi ? 'अगला कार्ड →' : 'Next Card →',
                  style: AppFonts.baloo(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1B2340)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _roundBtn('↻', _reshuffle),
        ],
      ),
    );
  }

  Widget _roundBtn(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFF5B8CFF), Color(0xFF16307A)]),
            boxShadow: const [BoxShadow(color: Color(0xFF0C1A42), offset: Offset(0, 4))],
          ),
          child: Text(label, style: AppFonts.baloo(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildEndScreen(bool isHi) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(isHi ? 'शाबाश!' : 'All Done!', style: AppFonts.baloo(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFFFFD700))),
            const SizedBox(height: 10),
            Text(
              isHi ? 'सभी 51 कार्ड देख लिए!\nएक और राउंड खेलें?' : "You've gone through all 51 cards!\nReady for another round?",
              textAlign: TextAlign.center,
              style: AppFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _reshuffle,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFC97F00)]),
                  boxShadow: const [BoxShadow(color: Color(0xFF7A4B00), offset: Offset(0, 4))],
                ),
                child: Text(
                  isHi ? '🔀 फिर खेलें' : '🔀 Play Again',
                  style: AppFonts.baloo(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1B2340)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                isHi ? '🏠 होम पर जाएं' : '🏠 Back to Home',
                style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
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
            Text(title, style: AppFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900, color: badgeColors.first)),
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
                    child: Text('${i + 1}', style: AppFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: badgeTextColor)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i][0]!, style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(steps[i][1]!, style: AppFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60)),
                        if (steps[i].length > 2 && steps[i][2] != null) ...[
                          const SizedBox(height: 4),
                          Text(steps[i][2]!, style: AppFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white38).copyWith(fontStyle: FontStyle.italic)),
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
                  Text(goalText, style: AppFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
