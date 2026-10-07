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
import 'chess_screen.dart';
import 'chess_translations.dart';

/// Chess landing — Figma "Chess Home" (382:598, 360×720).
/// Layout: hero art · 48 · mode cards form one unit, centred vertically
/// via [GameLandingBody]:
///   Solo      (green,  312×80, radius 16, 5px ledge) "Play against the bot"
///   · 24 ·
///   2 Players (yellow, 312×80, radius 16, 5px ledge) "Play together on one device"
class ChessHomeScreen extends StatelessWidget {
  const ChessHomeScreen({super.key});

  static const Color screenBg = AppColors.screenCoral; // #3D1C0F

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final t = ChessText(lang);
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
                  child: GameHeader(
                    title: '',
                    onBack: () => Navigator.of(context).pop(),
                    onHelp: () => ChessScreen.showHowToPlay(context, t),
                  ),
                ),
                Expanded(
                  child: GameLandingBody(
                    hero: Image.asset(
                      'assets/home/card_chess_${t.hi ? 'hi' : 'en'}.webp',
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      semanticLabel: t.title,
                    ),
                    variants: [
                      Heartbeat(
                        child: _ModeCard(
                          title: t.solo,
                          subtitle: t.soloSub,
                          top: const Color(0xFF6EE0AC),
                          bottom: const Color(0xFF1E8A5C),
                          ledge: const Color(0xFF114C33),
                          onTap: () => _start(context, vsBot: true),
                        ),
                      ),
                      const SizedBox(height: 24 - _ModeCard.ledgeHeight),
                      Heartbeat(
                        delay: const Duration(milliseconds: 300),
                        child: _ModeCard(
                          title: t.twoPlayers,
                          subtitle: t.twoPlayersSub,
                          top: const Color(0xFFFFE08A),
                          bottom: const Color(0xFFC97F00),
                          ledge: const Color(0xFF7A4B00),
                          onTap: () => _start(context, vsBot: false),
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

  void _start(BuildContext context, {required bool vsBot}) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChessScreen(vsBot: vsBot)));
  }
}

/// Same mode card as Memory Grid L1 V2: 312×80, radius 16, 5px ledge,
/// outlined h1 title over a body/base subtitle.
class _ModeCard extends StatelessWidget {
  static const double faceHeight = 80;
  static const double ledgeHeight = 5;

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
            borderRadius: 16,
            shadowOffset: ledgeHeight,
            pressedOverlayColor: const Color(0x2E000000),
            onTap: onTap,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Stack(
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
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(subtitle,
                          maxLines: 1, style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
