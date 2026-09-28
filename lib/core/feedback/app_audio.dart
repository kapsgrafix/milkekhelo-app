import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'feedback_settings.dart';

/// Every sound effect in the app. File = assets/audio/sfx/<fileName>.ogg.
enum Sfx {
  tap('tap', 0.55, 3),
  toggle('toggle', 0.6, 2),
  cardFlip('card_flip', 0.7, 2),
  shuffle('shuffle', 0.7, 1),
  diceRoll('dice_roll', 0.75, 1),
  diceLand('dice_land', 0.9, 1),
  step('step', 0.5, 3),
  ladder('ladder', 0.85, 1),
  snake('snake', 0.85, 1),
  turn('turn', 0.5, 1),
  countdown('countdown', 0.7, 2),
  go('go', 0.8, 1),
  timerTick('timer_tick', 0.6, 2),
  correct('correct', 0.7, 3),
  wrong('wrong', 0.75, 2),
  roundWin('round_win', 0.8, 1),
  hint('hint', 0.65, 1),
  win('win', 0.9, 1),
  lose('lose', 0.8, 1);

  const Sfx(this.fileName, this.volume, this.voices);

  final String fileName;

  /// Per-sound mix level (0–1) so taps sit under celebrations.
  final double volume;

  /// How many copies can overlap (e.g. quick repeated taps / steps).
  final int voices;

  String get asset => 'audio/sfx/$fileName.ogg';
}

/// Background music + sound effects.
///
/// Behaviour modelled on leading casual / social games:
///  * One gentle looping track, mixed low (≈30%) so it never competes with
///    speech — these are party games people talk over.
///  * Music ducks under win / lose jingles, then fades back.
///  * Music pauses when the app goes to the background and resumes after.
///  * Sound effects never take audio focus, so they don't stop the player's
///    own music app; on iOS they follow the silent switch ("ambient").
///  * Music, sound effects and vibration each have their own toggle
///    ([FeedbackSettings]), remembered between launches.
class AppAudio {
  AppAudio._();
  static final AppAudio instance = AppAudio._();

  static const double musicVolume = 0.30;
  static const double duckedVolume = 0.08;
  static const String _musicAsset = 'audio/music/bgm_loop.ogg';

  final FeedbackSettings _settings = FeedbackSettings.instance;
  final Map<Sfx, List<AudioPlayer>> _voices = {};
  final Map<Sfx, int> _nextVoice = {};
  AudioPlayer? _music;
  bool _musicPlaying = false;
  bool _inBackground = false;
  Timer? _duckTimer;
  Timer? _fadeTimer;
  bool _ready = false;

  static final AudioContext _sfxContext = AudioContext(
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.game,
      contentType: AndroidContentType.sonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  static final AudioContext _musicContext = AudioContext(
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.game,
      contentType: AndroidContentType.music,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  /// Preload everything. Safe to call once at startup; failures are
  /// swallowed so audio problems can never block the app.
  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      for (final s in Sfx.values) {
        final players = <AudioPlayer>[];
        for (var i = 0; i < s.voices; i++) {
          final p = AudioPlayer();
          await p.setPlayerMode(PlayerMode.lowLatency);
          await p.setAudioContext(_sfxContext);
          await p.setReleaseMode(ReleaseMode.stop);
          await p.setSource(AssetSource(s.asset));
          await p.setVolume(s.volume);
          players.add(p);
        }
        _voices[s] = players;
        _nextVoice[s] = 0;
      }
    } catch (e) {
      debugPrint('AppAudio: sfx preload failed: $e');
    }

    _settings.music.addListener(_syncMusic);
    await _syncMusic();
  }

  // ---- Sound effects -------------------------------------------------------

  void play(Sfx s) {
    if (!_settings.sfx.value || _inBackground) return;
    final players = _voices[s];
    if (players == null || players.isEmpty) return;
    final i = _nextVoice[s]! % players.length;
    _nextVoice[s] = i + 1;
    final p = players[i];
    () async {
      try {
        await p.stop();
        await p.resume();
      } catch (_) {}
    }();
  }

  // ---- Music -----------------------------------------------------------------

  Future<void> _syncMusic() async {
    final want = _settings.music.value && !_inBackground;
    try {
      if (want && !_musicPlaying) {
        _music ??= await _createMusicPlayer();
        _currentVolume = musicVolume;
        await _music!.setVolume(musicVolume);
        await _music!.resume();
        _musicPlaying = true;
      } else if (!want && _musicPlaying) {
        await _music?.pause();
        _musicPlaying = false;
      }
    } catch (e) {
      debugPrint('AppAudio: music failed: $e');
    }
  }

  Future<AudioPlayer> _createMusicPlayer() async {
    final p = AudioPlayer(playerId: 'bgm');
    await p.setPlayerMode(PlayerMode.mediaPlayer);
    await p.setAudioContext(_musicContext);
    await p.setReleaseMode(ReleaseMode.loop);
    await p.setSource(AssetSource(_musicAsset));
    return p;
  }

  /// Lower the music for [duration] (e.g. under a win jingle), then fade it
  /// back up.
  void duckMusic([Duration duration = const Duration(milliseconds: 2600)]) {
    if (_music == null || !_musicPlaying) return;
    _duckTimer?.cancel();
    _fade(to: duckedVolume, over: const Duration(milliseconds: 150));
    _duckTimer = Timer(duration, () => _fade(to: musicVolume, over: const Duration(milliseconds: 900)));
  }

  double _currentVolume = musicVolume;

  void _fade({required double to, required Duration over}) {
    _fadeTimer?.cancel();
    const stepMs = 50;
    final steps = (over.inMilliseconds / stepMs).ceil().clamp(1, 1000).toInt();
    final from = _currentVolume;
    var i = 0;
    _fadeTimer = Timer.periodic(const Duration(milliseconds: stepMs), (t) {
      i++;
      _currentVolume = from + (to - from) * (i / steps);
      _music?.setVolume(_currentVolume);
      if (i >= steps) t.cancel();
    });
  }

  // ---- App lifecycle -------------------------------------------------------

  void onBackground() {
    _inBackground = true;
    _syncMusic();
  }

  void onForeground() {
    _inBackground = false;
    _syncMusic();
  }
}
