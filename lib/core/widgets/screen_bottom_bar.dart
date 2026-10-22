import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ads.dart';
import '../theme/app_colors.dart';

/// The 50px full-width strip at the bottom of every screen. It holds the
/// 320×50 Google banner ad (centred), and is a few shades darker than the
/// page. It extends under the Android gesture / navigation area, and each
/// screen sets the system navigation bar to the same colour
/// ([AppColors.adStripOn] of its background) so the two read as one band.
///
/// By default it's a translucent dark shade over whatever sits behind it;
/// pass [color] for a solid colour (used over gradient backgrounds).
/// Until a banner arrives (or if none can load — offline, no fill) the
/// strip simply stays empty.
class ScreenBottomBar extends StatefulWidget {
  final Color? color;
  const ScreenBottomBar({super.key, this.color});

  /// Size of the banner ad that goes inside the strip.
  static const Size adSize = Size(320, 50);

  @override
  State<ScreenBottomBar> createState() => _ScreenBottomBarState();
}

class _ScreenBottomBarState extends State<ScreenBottomBar> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Ads.ready.addListener(_load);
    _load();
  }

  void _load() {
    if (!Ads.ready.value || _ad != null) return;
    _ad = BannerAd(
      size: AdSize.banner, // 320×50
      adUnitId: Ads.bannerUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: ${error.code} ${error.message}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    Ads.ready.removeListener(_load);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;
    final ad = _ad;
    return Container(
      width: double.infinity,
      height: 50 + inset,
      color: widget.color ?? AppColors.adStripShade,
      alignment: Alignment.topCenter,
      child: SizedBox.fromSize(
        size: ScreenBottomBar.adSize,
        child: ad != null && _loaded ? AdWidget(ad: ad) : null,
      ),
    );
  }
}
