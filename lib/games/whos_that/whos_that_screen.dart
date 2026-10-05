import 'package:flutter/material.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/heartbeat.dart';
import '../../core/widgets/pressable_card.dart';
import 'wt_create_screen.dart';
import 'wt_join_screen.dart';
import 'wt_translations.dart';
import 'wt_widgets.dart';

/// Who's That? landing — Figma "Whosthat Home" (322:2089, 360×720):
///   0    Header (Game Empty)                                   56
///   116  Hero art (name baked in, EN / HI)                    180
///   378  Create Game (pink,   312×80, radius 24, 6px ledge)
///   490  Join Game   (purple, 312×80, radius 24, 6px ledge)
///   670  Bottom bar                                            50
/// Card titles use the same outlined h1 as the other mode cards.
class WhosThatScreen extends StatelessWidget {
  const WhosThatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final t = WtText(lang);
        return WtScaffold(
          t: t,
          onBack: () => Navigator.of(context).pop(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            child: Column(
              children: [
                Image.asset(
                  'assets/home/card_whos_that_${t.hi ? 'hi' : 'en'}.webp',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  semanticLabel: t.title,
                ),
                const SizedBox(height: 82),
                Heartbeat(
                  child: _ModeCard(
                    title: t.createGame,
                    subtitle: t.createSub,
                    top: const Color(0xFFFF93B3),
                    bottom: const Color(0xFFCC2F63),
                    ledge: const Color(0xFF701A36),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WtCreateScreen())),
                  ),
                ),
                const SizedBox(height: 26), // 32 gap − 6px ledge
                Heartbeat(
                  delay: const Duration(milliseconds: 300),
                  child: _ModeCard(
                    title: t.joinGame,
                    subtitle: t.joinCardSub,
                    top: const Color(0xFFC3B0F5),
                    bottom: const Color(0xFF6A4FC2),
                    ledge: const Color(0xFF3A2B6B),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WtJoinScreen())),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      ),
    );
  }
}
