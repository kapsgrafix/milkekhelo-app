import 'package:flutter/material.dart';

import '../core/localization/app_language.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/pressable_card.dart';
import '../core/widgets/stroked_text.dart';
import '../games/first/first_screen.dart';
import '../games/memory_grid/memory_grid_home_screen.dart';
import '../games/snakes_and_ladders/snl_screen.dart';
import '../games/thank_you/thank_you_screen.dart';

/// The launcher / home screen: entry point into each of the four games.
///
/// This screen only knows how to lay out four cards and push a route per
/// card — it holds no game logic itself. Adding a fifth game later means
/// adding one more _HomeGameEntry below and a new games/<name>/ folder;
/// nothing here needs to change about the existing four.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.shell,
      body: SafeArea(
        child: ValueListenableBuilder<AppLang>(
          valueListenable: AppLanguage.instance,
          builder: (context, lang, _) {
            final isHi = lang == AppLang.hi;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _LangToggle(isHi: isHi),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Mil ke Khelo',
                  style: AppFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  isHi ? 'कम स्क्रॉल, ज़्यादा कहानियाँ' : 'Less Scrolling. More Stories.',
                  style: AppFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 22,
                    childAspectRatio: 152 / 148,
                    children: [
                      _HomeGameCard(
                        palette: AppColors.snakesAndLadders,
                        emoji: '🐍',
                        name: isHi ? 'स्नेक्स एंड लैडर्स' : 'Snakes & Ladders',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SnlScreen()),
                        ),
                      ),
                      _HomeGameCard(
                        palette: AppColors.memoryGrid,
                        emoji: '🧠',
                        name: isHi ? 'मेमोरी ग्रिड' : 'Memory Grid',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MemoryGridHomeScreen()),
                        ),
                      ),
                      _HomeGameCard(
                        palette: AppColors.first,
                        emoji: '🎬',
                        name: isHi ? 'फर्स्ट' : 'First',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FirstScreen()),
                        ),
                      ),
                      _HomeGameCard(
                        palette: AppColors.thankYou,
                        emoji: '🙏',
                        name: isHi ? 'थैंक यू' : 'Thank You',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ThankYouScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeGameCard extends StatelessWidget {
  final GameCardPalette palette;
  final String emoji;
  final String name;
  final VoidCallback onTap;

  const _HomeGameCard({
    required this.palette,
    required this.emoji,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      topColor: palette.top,
      bottomColor: palette.bottom,
      shadowColor: palette.shadow,
      borderRadius: 24,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            StrokedText(
              name,
              textAlign: TextAlign.center,
              style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w800, height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  final bool isHi;
  const _LangToggle({required this.isHi});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.langToggleBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.langToggleBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(context, 'EN', !isHi, () => AppLanguage.instance.set(AppLang.en)),
          _btn(context, 'हिं', isHi, () => AppLanguage.instance.set(AppLang.hi)),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.langActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppFonts.baloo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.langActiveText : AppColors.langInactiveText,
          ),
        ),
      ),
    );
  }
}
