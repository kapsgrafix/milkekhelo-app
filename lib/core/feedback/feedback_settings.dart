import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Player preferences for music, sound effects and vibration. All on by
/// default (like most casual/social games); every change is saved to
/// shared_preferences immediately and restored on the next launch.
class FeedbackSettings {
  FeedbackSettings._();
  static final FeedbackSettings instance = FeedbackSettings._();

  static const _kMusic = 'fx-music';
  static const _kSfx = 'fx-sfx';
  static const _kHaptics = 'fx-haptics';

  final ValueNotifier<bool> music = ValueNotifier(true);
  final ValueNotifier<bool> sfx = ValueNotifier(true);
  final ValueNotifier<bool> haptics = ValueNotifier(true);

  SharedPreferences? _prefs;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      music.value = _prefs!.getBool(_kMusic) ?? true;
      sfx.value = _prefs!.getBool(_kSfx) ?? true;
      haptics.value = _prefs!.getBool(_kHaptics) ?? true;
    } catch (_) {
      // Preferences unavailable — keep defaults.
    }
  }

  void setMusic(bool v) => _set(music, _kMusic, v);
  void setSfx(bool v) => _set(sfx, _kSfx, v);
  void setHaptics(bool v) => _set(haptics, _kHaptics, v);

  void _set(ValueNotifier<bool> n, String key, bool v) {
    if (n.value == v) return;
    n.value = v;
    _prefs?.setBool(key, v);
  }
}
