import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_config.dart';
import '../auth/auth_service.dart';

/// Saved games + best scores for signed-in players.
///
/// • Unfinished games: each game hands over a small JSON snapshot when the
///   player leaves (and after every turn), and reads it back when the game
///   opens — so it continues exactly where they left off.
/// • Best scores / streaks: the device keeps them in SharedPreferences as
///   before; for signed-in players they're also kept on the account, and
///   the higher of the two wins.
///
/// Everything is stored on the phone first (so it works offline and is
/// instant), then copied to the player's own space in the Firebase
/// Realtime Database: users/{uid}/saves/{game} and users/{uid}/best/{key}.
/// Signing in on a new phone pulls both down.
///
/// Guests don't get saved games (that's what signing in is for).
class GameSaves {
  GameSaves._();
  static final GameSaves instance = GameSaves._();

  /// Best-score keys used by the games (SharedPreferences ints).
  static const List<String> bestKeys = ['blocks_jodo_best', 'mg-best-easy', 'mg-best-hard'];

  SharedPreferences? _prefs;
  String? _uid;
  final Map<String, Map<String, dynamic>> _saves = {};
  final Map<String, Timer> _pending = {};

  /// Fires after cloud data arrives (new device / sign-in), so open screens
  /// can refresh best scores if they want to.
  final ValueNotifier<int> changed = ValueNotifier<int>(0);

  String get _localKey => 'game_saves_v1_$_uid';

  /// Call once at app start, after [AuthService.load].
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {}
    AuthService.instance.user.addListener(_onUserChanged);
    _onUserChanged();
  }

  void _onUserChanged() {
    final uid = AuthService.instance.user.value?.uid;
    if (uid == _uid) return;
    _uid = uid;
    for (final t in _pending.values) {
      t.cancel();
    }
    _pending.clear();
    _saves.clear();
    if (uid == null) return; // signed out: no saved games
    // This player's saves on this phone…
    try {
      final raw = _prefs?.getString(_localKey);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        m.forEach((k, v) {
          if (v is Map) _saves[k] = Map<String, dynamic>.from(v);
        });
      }
    } catch (_) {}
    // …then whatever the account has (another phone may be newer).
    unawaited(pull());
  }

  // ───────────────────────── Saved games ─────────────────────────

  /// The saved state for [game], or null (guest / nothing saved).
  Map<String, dynamic>? peek(String game) {
    if (_uid == null) return null;
    final s = _saves[game];
    return s == null ? null : Map<String, dynamic>.from(s);
  }

  /// Saves [data] for [game]: on the phone right away, to the account a few
  /// seconds later (or immediately with [now], e.g. when leaving the game).
  void put(String game, Map<String, dynamic> data, {bool now = false}) {
    if (_uid == null) return;
    final copy = Map<String, dynamic>.from(data)..['t'] = DateTime.now().millisecondsSinceEpoch;
    _saves[game] = copy;
    _persistLocal();
    _pending[game]?.cancel();
    if (now) {
      _pending.remove(game);
      unawaited(_upload(game));
    } else {
      _pending[game] = Timer(const Duration(seconds: 4), () {
        _pending.remove(game);
        _upload(game);
      });
    }
  }

  /// Forgets the saved state for [game] (finished / restarted).
  void clear(String game) {
    if (_uid == null) return;
    _pending.remove(game)?.cancel();
    if (_saves.remove(game) == null) return;
    _persistLocal();
    unawaited(_request('DELETE', 'users/$_uid/saves/$game'));
  }

  void _persistLocal() {
    if (_uid == null) return;
    try {
      _prefs?.setString(_localKey, jsonEncode(_saves));
    } catch (_) {}
  }

  Future<void> _upload(String game) async {
    final uid = _uid;
    final data = _saves[game];
    if (uid == null || data == null) return;
    await _request('PUT', 'users/$uid/saves/$game', jsonEncode(data));
  }

  // ───────────────────────── Best scores ─────────────────────────

  /// A game saved a new best on the phone — copy it to the account.
  void bestChanged(String key, int value) {
    if (_uid == null) return;
    unawaited(_request('PATCH', 'users/$_uid/best', jsonEncode({key: value})));
  }

  // ───────────────────────── Sync ─────────────────────────

  /// Downloads the account's saves and bests and merges them with the
  /// phone's: for each game the newer save wins; for bests the higher wins.
  Future<void> pull() async {
    final uid = _uid;
    if (uid == null) return;
    final res = await _request('GET', 'users/$uid');
    if (uid != _uid) return;
    final remote = res is Map ? res : const {};

    // Saved games.
    final remoteSaves = remote['saves'];
    var savesChanged = false;
    if (remoteSaves is Map) {
      remoteSaves.forEach((k, v) {
        if (v is! Map) return;
        final local = _saves['$k'];
        final rt = (v['t'] as num?)?.toInt() ?? 0;
        final lt = (local?['t'] as num?)?.toInt() ?? -1;
        if (rt > lt) {
          _saves['$k'] = Map<String, dynamic>.from(v);
          savesChanged = true;
        }
      });
    }
    if (savesChanged) _persistLocal();
    // Phone saves the account doesn't have yet (e.g. made offline).
    for (final k in _saves.keys.toList()) {
      final rv = remoteSaves is Map ? remoteSaves[k] : null;
      final rt = rv is Map ? ((rv['t'] as num?)?.toInt() ?? 0) : -1;
      if (((_saves[k]!['t'] as num?)?.toInt() ?? 0) > rt) unawaited(_upload(k));
    }

    // Best scores: keep the higher of phone / account, everywhere.
    final remoteBest = remote['best'] is Map ? remote['best'] as Map : const {};
    final merged = <String, int>{};
    for (final key in bestKeys) {
      final local = _prefs?.getInt(key) ?? 0;
      final cloud = (remoteBest[key] as num?)?.toInt() ?? 0;
      final best = local > cloud ? local : cloud;
      if (best > local) {
        try {
          await _prefs?.setInt(key, best);
        } catch (_) {}
      }
      if (best > 0 && best != cloud) merged[key] = best;
    }
    if (merged.isNotEmpty) unawaited(_request('PATCH', 'users/$uid/best', jsonEncode(merged)));
    changed.value++;
  }

  /// Removes everything saved on this phone for player [uid] (default:
  /// the current one) — used after the profile is deleted.
  void forgetLocal([String? uid]) {
    final id = uid ?? _uid;
    if (id == null) return;
    if (id == _uid) _saves.clear();
    try {
      _prefs?.remove('game_saves_v1_$id');
    } catch (_) {}
  }

  // ───────────────────────── REST ─────────────────────────

  /// Realtime Database REST call as the signed-in player. Best effort:
  /// returns the decoded JSON, or null on any failure (offline, rules…).
  Future<Object?> _request(String method, String path, [String? body]) async {
    final token = await AuthService.instance.idToken();
    if (token == null) return null;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final url = Uri.parse('${AuthConfig.databaseUrl}/$path.json?auth=$token');
      final req = await client.openUrl(method, url);
      if (body != null) {
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        req.add(utf8.encode(body));
      }
      final resp = await req.close().timeout(const Duration(seconds: 15));
      final text = await resp.transform(utf8.decoder).join();
      if (resp.statusCode >= 400) {
        debugPrint('GameSaves $method $path → ${resp.statusCode}: $text');
        return null;
      }
      return text.isEmpty ? null : jsonDecode(text);
    } catch (e) {
      debugPrint('GameSaves $method $path failed: $e');
      return null;
    } finally {
      client.close();
    }
  }
}
