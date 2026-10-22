import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../auth/auth_service.dart';

/// Google AdMob banner ads, shown in the 50px bottom strip of every screen
/// ([ScreenBottomBar]).
///
/// Start-up order (Google's rules): ask for consent where the law needs it
/// (the EU / UK form only appears there), then start the Mobile Ads SDK,
/// then banners may load. Nothing here blocks the app from opening.
///
/// IDs: MilkeKhelo's AdMob app (ca-app-pub-9391078867590803~1476168468 —
/// set in the AndroidManifest by the CI workflow, ADMOB_APP_ID in
/// build-apk.yml) and its "Bottom strip banner" unit below.
///
/// Never tap real ads on your own phone (AdMob treats it as invalid
/// traffic). Accounts listed in [testAccounts] always get Google's test
/// banner instead.
class Ads {
  Ads._();

  /// MilkeKhelo's "Bottom strip banner" (AdMob → Apps → MilkeKhelo → Ad units).
  static const String _bannerUnit = 'ca-app-pub-9391078867590803/8368879873';

  /// Google's test banner ("Test Ad", earns nothing).
  static const String _testBannerUnit = 'ca-app-pub-3940256099942544/6300978111';

  /// Firebase user IDs (Firebase → Authentication → Users → User UID) of
  /// the team's own accounts: signed in with one of these, the app shows
  /// test ads only, so testing never counts as invalid clicks.
  static const Set<String> testAccounts = {};

  /// The banner unit to request right now.
  static String get bannerUnitId =>
      testAccounts.contains(AuthService.instance.user.value?.uid) ? _testBannerUnit : _bannerUnit;

  /// True once ads may be requested (consent handled + SDK started).
  static final ValueNotifier<bool> ready = ValueNotifier<bool>(false);

  static bool _started = false;

  /// Call once after the app is on screen (the consent form needs it).
  static Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      final done = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((_) {
            if (!done.isCompleted) done.complete();
          });
        },
        (_) {
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(const Duration(seconds: 15), onTimeout: () {});
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.initialize();
      ready.value = true;
    } catch (e) {
      debugPrint('Ads: start-up failed: $e');
    }
  }
}
