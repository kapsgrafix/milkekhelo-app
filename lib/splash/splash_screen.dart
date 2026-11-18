import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/localization/app_language.dart';
import '../home/home_screen.dart';

/// Launch splash, shown once before the home screen: BinnyTechLabs, then
/// the MilkeKhelo logo, then home.
///
/// Timeline (3.4 s):
///   0.0–1.7 s  BinnyTechLabs logo (assets/splash/binnytechlabs.webp, 240px
///              wide) on #151515 — pops in, a light band sweeps across,
///              then it fades out.
///   1.5–1.9 s  background turns from #151515 to the home navy.
///   1.8–3.4 s  MilkeKhelo logo (assets/splash/mkk_logo.webp — the app icon
///              art, 168px, rounded) pops in with a soft glow and a light
///              sweep; the milkekhelo.com wordmark fades in below it.
///   3.4 s      cross-fade to home, where the page builds itself in.
/// Home card art is pre-decoded while the splash is up.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const Color _bgBinny = Color(0xFF151515);
  static const Color _bgMkk = Color(0xFF001453); // home navy
  static const int _totalMs = 3400;
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: _totalMs));
  Timer? _timer;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(const Duration(milliseconds: _totalMs), _goHome);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    precacheImage(const AssetImage('assets/splash/binnytechlabs.webp'), context);
    precacheImage(const AssetImage('assets/splash/mkk_logo.webp'), context);
    precacheImage(const AssetImage('assets/home/wordmark.webp'), context);
    precacheImage(const AssetImage('assets/home/banner_bg.webp'), context);
    precacheImage(const AssetImage('assets/home/avatar_default.webp'), context);
    final lang = AppLanguage.instance.value == AppLang.hi ? 'hi' : 'en';
    for (final g in const ['memory_grid', 'whos_that', 'my_first', 'snl', 'chess', 'blocks_jodo', 'thank_you']) {
      precacheImage(AssetImage('assets/home/card_${g}_$lang.webp'), context);
    }
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
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

  /// 0 → 1 between [fromMs] and [toMs] of the timeline.
  static double _seg(double ms, int fromMs, int toMs) => ((ms - fromMs) / (toMs - fromMs)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final ms = _c.value * _totalMs;
        final bg = Color.lerp(_bgBinny, _bgMkk, Curves.easeInOut.transform(_seg(ms, 1500, 1900)))!;

        // Phase 1: BinnyTechLabs.
        final bIn = _seg(ms, 0, 600);
        final bOut = _seg(ms, 1450, 1700);
        final bSweep = reduceMotion ? 0.0 : _seg(ms, 700, 1300);

        // Phase 2: MilkeKhelo.
        final mIn = _seg(ms, 1800, 2400);
        final mSweep = reduceMotion ? 0.0 : _seg(ms, 2350, 2950);
        final wIn = _seg(ms, 2200, 2700);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: bg,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: bg,
            body: SizedBox.expand(
              child: Stack(
              alignment: Alignment.center,
              children: [
                if (ms < 1750)
                  Opacity(
                    opacity: (Curves.easeOut.transform((bIn / 0.75).clamp(0.0, 1.0)) * (1 - bOut)).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: reduceMotion ? 1 : 0.8 + 0.2 * Curves.easeOutBack.transform(bIn) + 0.04 * bOut,
                      child: _Wordmark(sweep: bSweep),
                    ),
                  ),
                if (ms >= 1750)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: Curves.easeOut.transform((mIn / 0.6).clamp(0.0, 1.0)),
                        child: Transform.scale(
                          scale: reduceMotion ? 1 : 0.7 + 0.3 * Curves.easeOutBack.transform(mIn),
                          child: _MkkLogo(sweep: mSweep, glow: mIn),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Opacity(
                        opacity: Curves.easeOut.transform(wIn),
                        child: Transform.translate(
                          offset: Offset(0, reduceMotion ? 0 : 8 * (1 - Curves.easeOutCubic.transform(wIn))),
                          child: Image.asset(
                            'assets/home/wordmark.webp',
                            width: 150,
                            height: 150 / 7.2,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            semanticLabel: 'milkekhelo.com',
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }
}

/// The MilkeKhelo logo (the app icon art) as a 168px rounded tile with a
/// soft blue glow and a light band that sweeps across once.
class _MkkLogo extends StatelessWidget {
  final double sweep;
  final double glow;
  const _MkkLogo({required this.sweep, required this.glow});

  static const double size = 168;

  @override
  Widget build(BuildContext context) {
    Widget logo = Image.asset(
      'assets/splash/mkk_logo.webp',
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      semanticLabel: 'MilkeKhelo',
    );
    if (sweep > 0 && sweep < 1) {
      logo = ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Color(0x00FFFFFF), Color(0x66FFFFFF), Color(0x00FFFFFF)],
          stops: [
            (sweep * 1.4 - 0.4).clamp(0.0, 1.0).toDouble(),
            (sweep * 1.4 - 0.2).clamp(0.0, 1.0).toDouble(),
            (sweep * 1.4).clamp(0.0, 1.0).toDouble(),
          ],
        ).createShader(rect),
        child: logo,
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.23),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F6BFF).withAlpha((90 * glow).round()),
            blurRadius: 48,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(size * 0.23), child: logo),
    );
  }
}

/// The BinnyTechLabs logo with a light band that sweeps across it once
/// ([sweep] 0 → 1).
class _Wordmark extends StatelessWidget {
  final double sweep;
  const _Wordmark({required this.sweep});

  static const double width = 240;
  static const double aspect = 1718 / 296; // trimmed logo file

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/splash/binnytechlabs.webp',
      width: width,
      height: width / aspect,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'BinnyTechLabs',
    );
    if (sweep <= 0 || sweep >= 1) return logo;
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
      child: logo,
    );
  }
}
