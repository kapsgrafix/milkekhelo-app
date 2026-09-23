import 'package:flutter/foundation.dart';

/// The two languages the app supports (English / Hindi), matching the web
/// app's `lang` global. This is the ONLY thing shared across game modules
/// for localization — each game keeps its own translation strings in its
/// own folder (e.g. games/memory_grid/mg_translations.dart) keyed off this
/// enum, so adding a language or a string to one game never touches another.
enum AppLang { en, hi }

/// App-wide current-language holder. A single instance, listened to by the
/// shared [GameHeader] language toggle and by every game screen that needs
/// to rebuild when the language changes.
///
/// Deliberately NOT persisted (matches the web app: language always starts
/// as English on a fresh launch).
class AppLanguage extends ValueNotifier<AppLang> {
  AppLanguage._() : super(AppLang.en);

  static final AppLanguage instance = AppLanguage._();

  bool get isHindi => value == AppLang.hi;

  void set(AppLang lang) {
    if (value != lang) value = lang;
  }

  void toggle() => set(value == AppLang.en ? AppLang.hi : AppLang.en);
}
