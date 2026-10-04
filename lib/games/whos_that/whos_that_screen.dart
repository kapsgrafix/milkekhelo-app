import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/game_header.dart';
import '../../core/widgets/screen_bottom_bar.dart';

/// "Who's That?" / "पहचान कौन" — placeholder until the game is built.
///
/// Uses the Figma "Whosthat Home" (322:2089) shell: screen-pink background,
/// Game Empty header (no help yet), 180px hero art 60px below the header,
/// and the 50px bottom bar. In place of the Create / Join cards it shows a
/// "Coming Soon" message in heading/h1 + body/base.
class WhosThatScreen extends StatelessWidget {
  const WhosThatScreen({super.key});

  static const Color screenBg = Color(0xFF3D0F1E); // background/screen-pink

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final isHi = lang == AppLang.hi;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Color.alphaBlend(AppColors.surface, screenBg),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: screenBg,
            body: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: GameHeader(title: '', onBack: () => Navigator.of(context).pop()),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/home/card_whos_that_${isHi ? 'hi' : 'en'}.webp',
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          semanticLabel: isHi ? 'पहचान कौन' : "Who's That?",
                        ),
                        const SizedBox(height: 82),
                        Text(
                          isHi ? 'जल्द आ रहा है' : 'Coming Soon',
                          textAlign: TextAlign.center,
                          style: AppFonts.baloo(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15, color: AppColors.brandYellow),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHi
                              ? 'यह खेल अभी बन रहा है। जल्द ही दोस्तों के साथ खेलें!'
                              : "We're building this game. Play it with friends soon!",
                          textAlign: TextAlign.center,
                          style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
                        ),
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
}
