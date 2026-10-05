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
import 'snl_data.dart';
import 'snl_screen.dart';
import 'snl_translations.dart';

/// Snakes & Ladders mode select — Figma "SnL Home" (14:1485, 360×720).
/// Layout: hero art · 48 · mode cards form one unit, centred vertically
/// via [GameLandingBody]. Figma reference positions:
///   0    Header (Game Empty)                                   56
///   116  Hero art (game name baked in, EN / HI)               180
///   378  Classic card (pink, 312×80, radius 24, 6px ledge)
///   490  Timer card   (purple, 312×80, radius 24, 6px ledge)
///   670  Bottom bar                                            50
/// Card title: heading/h1 (ExtraBold 28 / 115%) white with a thin outline in
/// the card's ledge colour; subtitle: body/base (Medium 15 / 140%) white.
/// Both cards pulse gently (shared [Heartbeat]).
class SnlHomeScreen extends StatelessWidget {
  const SnlHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final t = SnlText(lang);
        final isHi = lang == AppLang.hi;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Color.alphaBlend(AppColors.surface, SnlData.screenBg),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: SnlData.screenBg,
            body: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: GameHeader(
                    title: '',
                    onBack: () => Navigator.of(context).pop(),
                    onHelp: () => SnlScreen.showHowToPlay(context, t, timed: false),
                  ),
                ),
                Expanded(
                  child: GameLandingBody(
                    hero: Image.asset(
                          'assets/home/card_snl_${isHi ? 'hi' : 'en'}.webp',
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          semanticLabel: t.title,
                        ),
                        variants: [
                        Heartbeat(
                          child: _ModeCard(
                            title: t.classic,
                            subtitle: t.classicSub,
                            top: const Color(0xFFFF93B3),
                            bottom: const Color(0xFFCC2F63),
                            ledge: const Color(0xFF701A36),
                            onTap: () => _start(context, timed: false),
                          ),
                        ),
                        const SizedBox(height: 26), // 32 gap − 6px ledge
                        Heartbeat(
                          delay: const Duration(milliseconds: 300),
                          child: _ModeCard(
                            title: t.timer,
                            subtitle: t.timerSub,
                            top: const Color(0xFFC3B0F5),
                            bottom: const Color(0xFF6A4FC2),
                            ledge: const Color(0xFF3A2B6B),
                            onTap: () => _start(context, timed: true),
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

  void _start(BuildContext context, {required bool timed}) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SnlScreen(timed: timed)));
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color top;
  final Color bottom;
  final Color ledge;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.top,
    required this.bottom,
    required this.ledge,
    required this.onTap,
  });

  static const double faceHeight = 80;
  static const double ledgeHeight = 6;

  @override
  Widget build(BuildContext context) {
    final h1 = AppFonts.baloo(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15);
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 312),
        child: SizedBox(
          height: faceHeight + ledgeHeight,
          child: PressableCard(
            topColor: top,
            bottomColor: bottom,
            shadowColor: ledge,
            borderRadius: 24,
            shadowOffset: ledgeHeight,
            pressedOverlayColor: const Color(0x2E000000),
            onTap: onTap,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // White title over a thin outline in the ledge colour.
                  Stack(
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
                            ..color = ledge,
                        ),
                      ),
                      Text(title, maxLines: 1, style: h1),
                    ],
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
    );
  }
}
