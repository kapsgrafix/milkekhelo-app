import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/localization/app_language.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../home/home_screen.dart';

/// BinnyTechLabs splash, shown once at launch before the home screen.
///
/// There is no splash frame in Figma and no logo file yet, so the studio
/// name is set as a Baloo 2 wordmark ("Binny" white · "TechLabs" brand
/// yellow) on a flat dark-grey background. To use a real logo later, swap
/// [_Wordmark] for an `Image.asset`.
///
/// Timeline: wordmark pops in (0–0.6 s) → light sweep (0.7–1.3 s) →
/// hold → cross-fade to home at ~2 s. Home card art is pre-decoded while
/// the splash is up so the home screen appears fully drawn.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF1E1E1E); // dark grey
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  Timer? _timer;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(const Duration(milliseconds: 2000), _goHome);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    precacheImage(const AssetImage('assets/home/wordmark.webp'), context);
    final lang = AppLanguage.instance.value == AppLang.hi ? 'hi' : 'en';
    for (final g in const ['memory_grid', 'whos_that', 'my_first', 'snl', 'blocks_jodo', 'thank_you']) {
      precacheImage(AssetImage('assets/home/card_${g}_$lang.webp'), context);
    }
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final v = reduceMotion ? 1.0 : _c.value;
              final pop = Curves.easeOutBack.transform((v / 0.4).clamp(0.0, 1.0));
              final fade = Curves.easeOut.transform((v / 0.3).clamp(0.0, 1.0));
              final sweep = ((v - 0.47) / 0.4).clamp(0.0, 1.0);
              return Opacity(
                opacity: fade,
                child: Transform.scale(
                  scale: 0.8 + 0.2 * pop,
                  child: _Wordmark(sweep: reduceMotion ? 0 : sweep),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// "BinnyTechLabs" set in Baloo 2 ExtraBold with a light band that sweeps
/// across once ([sweep] 0 → 1).
class _Wordmark extends StatelessWidget {
  final double sweep;
  const _Wordmark({required this.sweep});

  @override
  Widget build(BuildContext context) {
    final style = AppFonts.baloo(fontSize: 36, fontWeight: FontWeight.w800, height: 1.1);
    final text = Text.rich(
      TextSpan(children: [
        TextSpan(text: 'Binny', style: style),
        TextSpan(text: 'TechLabs', style: style.copyWith(color: AppColors.brandYellow)),
      ]),
    );
    if (sweep <= 0 || sweep >= 1) return text;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [Color(0x00FFFFFF), Color(0xB3FFFFFF), Color(0x00FFFFFF)],
        stops: [
          (sweep * 1.4 - 0.4).clamp(0.0, 1.0).toDouble(),
          (sweep * 1.4 - 0.2).clamp(0.0, 1.0).toDouble(),
          (sweep * 1.4).clamp(0.0, 1.0).toDouble(),
        ],
      ).createShader(rect),
      child: text,
    );
  }
}
