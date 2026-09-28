import 'dart:async';

import 'package:flutter/services.dart';

import 'app_audio.dart';
import 'feedback_settings.dart';

/// The app's feedback vocabulary — one call per *moment*, each pairing a
/// sound with a matching haptic. Screens call these (e.g. `Fx.win()`)
/// instead of touching audio or vibration directly, so the whole app feels
/// consistent and can be retuned in one file.
///
/// Haptic language follows the platform guidelines that leading social and
/// casual apps use:
///  * selection click — every ordinary tap, toggle, step (barely-there tick)
///  * light impact    — soft confirmations: card flip, turn change, correct
///  * medium impact   — something landed: dice result, GO!, round won
///  * heavy impact    — something big / bad: snake bite, wrong answer
///  * patterns        — success (win) and failure (lose / time-up)
/// Haptics follow the phone's own "touch vibration" setting and the in-app
/// Vibration toggle.
class Fx {
  Fx._();

  static final _audio = AppAudio.instance;
  static final _settings = FeedbackSettings.instance;

  // ---- UI --------------------------------------------------------------------
  static void tap() => _go(Sfx.tap, _Haptic.selection);
  static void toggle() => _go(Sfx.toggle, _Haptic.selection);

  // ---- Card decks (First, Thank You) ----------------------------------------
  static void cardFlip() => _go(Sfx.cardFlip, _Haptic.light);
  static void shuffle() {
    _audio.play(Sfx.shuffle);
    _pattern(const [_Haptic.light, _Haptic.light, _Haptic.light], 70);
  }

  // ---- Countdown / timer ----------------------------------------------------
  static void countdown() => _go(Sfx.countdown, _Haptic.light);
  static void goSignal() => _go(Sfx.go, _Haptic.medium);
  static void timerTick() => _go(Sfx.timerTick, _Haptic.selection);

  // ---- Board game (Snakes & Ladders) -----------------------------------------
  static void diceRoll() => _go(Sfx.diceRoll, _Haptic.light);

  /// Haptic-only tick for each face flip while the dice tumbles.
  static void diceTick() => _haptic(_Haptic.selection);
  static void diceLand() => _go(Sfx.diceLand, _Haptic.medium);
  static void step() => _go(Sfx.step, _Haptic.selection);
  static void ladder() {
    _audio.play(Sfx.ladder);
    _pattern(const [_Haptic.light, _Haptic.medium, _Haptic.heavy], 90);
  }

  static void snake() {
    _audio.play(Sfx.snake);
    _pattern(const [_Haptic.heavy, _Haptic.medium], 160);
  }

  static void turn() => _go(Sfx.turn, _Haptic.light);

  // ---- Puzzle (Memory Grid) -------------------------------------------------
  static void correct() => _go(Sfx.correct, _Haptic.light);
  static void wrong() {
    _audio.play(Sfx.wrong);
    _pattern(const [_Haptic.heavy, _Haptic.heavy], 110);
  }

  static void hint() => _go(Sfx.hint, _Haptic.light);
  static void roundWin() {
    _audio.play(Sfx.roundWin);
    _pattern(const [_Haptic.medium, _Haptic.light], 100);
  }

  // ---- Game over -------------------------------------------------------------
  static void win() {
    _audio.duckMusic();
    _audio.play(Sfx.win);
    _pattern(const [_Haptic.heavy, _Haptic.medium, _Haptic.medium, _Haptic.heavy], 130);
  }

  static void lose() {
    _audio.duckMusic(const Duration(milliseconds: 1800));
    _audio.play(Sfx.lose);
    _pattern(const [_Haptic.medium, _Haptic.heavy], 220);
  }

  // ---- internals -------------------------------------------------------------
  static void _go(Sfx s, _Haptic h) {
    _audio.play(s);
    _haptic(h);
  }

  static void _haptic(_Haptic h) {
    if (!_settings.haptics.value) return;
    switch (h) {
      case _Haptic.selection:
        HapticFeedback.selectionClick();
      case _Haptic.light:
        HapticFeedback.lightImpact();
      case _Haptic.medium:
        HapticFeedback.mediumImpact();
      case _Haptic.heavy:
        HapticFeedback.heavyImpact();
    }
  }

  static void _pattern(List<_Haptic> hs, int gapMs) {
    for (var i = 0; i < hs.length; i++) {
      if (i == 0) {
        _haptic(hs[0]);
      } else {
        Timer(Duration(milliseconds: gapMs * i), () => _haptic(hs[i]));
      }
    }
  }
}

enum _Haptic { selection, light, medium, heavy }
