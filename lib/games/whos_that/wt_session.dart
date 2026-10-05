import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import 'wt_questions.dart';
import 'wt_rtdb.dart';

/// One player in the room.
class WtPlayer {
  final String id;
  final String name;
  final bool isHost;
  final int joinedAt;
  const WtPlayer({required this.id, required this.name, required this.isHost, required this.joinedAt});

  String get initial => name.isEmpty ? '?' : name.characters.first.toUpperCase();
}

enum WtOutcome { bullseye, crowdPick, tie }

/// What happened in the round being revealed (worked out on each device from
/// the answers, so it needs nothing extra in the database).
class WtRoundResult {
  final WtOutcome outcome;

  /// Bullseye / crowd's pick: the chosen player. Tie: the tied players.
  final List<String> picked;
  const WtRoundResult(this.outcome, this.picked);
}

/// Why a create / join attempt failed (shown as a toast).
enum WtFailure { network, notFound, started, full }

class WtException implements Exception {
  final WtFailure reason;
  const WtException(this.reason);
}

/// A live Who's That room. Uses exactly the same data layout as the web game
/// (`whosthat/<CODE>`), so phones and browsers can play in the same room:
///
///   qCount, target, qIdx[], phase (lobby|question|reveal|end), qIndex,
///   score, hostId, createdAt, players/{id: {name, isHost, joinedAt}},
///   answers/{playerId: pickedPlayerId}, lastUnanimous, lastPickedId,
///   targetHit, won
///
/// App-only addition: `seen/{playerId}` — a heartbeat timestamp every 8 s.
/// A player whose heartbeat stops for 25 s is shown as "Offline" so the host
/// can remove them (the web game removes players itself on disconnect).
///
/// Like the web game, the host's device runs the game: it scores each round
/// once everyone has answered, moves to the next question and ends the game.
class WtSession extends ChangeNotifier {
  static const int maxPlayers = 10;
  static const Duration _heartbeatEvery = Duration(seconds: 8);
  static const Duration _offlineAfter = Duration(seconds: 25);

  final WtRtdb _db = WtRtdb.instance;
  final String code;
  final String myId;
  final String myName;

  WtSession._(this.code, this.myId, this.myName);

  String get _root => 'whosthat/$code';

  // ───────────────────────── Create / join ─────────────────────────

  static final _rng = Random();

  static String _makeCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(4, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  static String _makeId() {
    final t = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final r = List.generate(5, (_) => '0123456789abcdefghijklmnopqrstuvwxyz'[_rng.nextInt(36)]).join();
    return 'p$t$r';
  }

  static List<int> freshQuestions(int count) {
    final all = List<int>.generate(WtQuestions.count, (i) => i)..shuffle(_rng);
    return all.take(count).toList();
  }

  static Future<WtSession> create({required String hostName, required int qCount, required int target}) async {
    final db = WtRtdb.instance;
    try {
      var code = _makeCode();
      for (var i = 0; i < 5; i++) {
        if (await db.get('whosthat/$code') == null) break;
        code = _makeCode();
      }
      final id = _makeId();
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.put('whosthat/$code', {
        'qCount': qCount,
        'target': target,
        'qIdx': freshQuestions(qCount),
        'phase': 'lobby',
        'qIndex': 0,
        'score': 0,
        'hostId': id,
        'createdAt': now,
        'players': {
          id: {'name': hostName, 'isHost': true, 'joinedAt': now},
        },
        'seen': {id: WtRtdb.serverTimestamp},
      });
      return WtSession._(code, id, hostName).._start();
    } on WtException {
      rethrow;
    } catch (_) {
      throw const WtException(WtFailure.network);
    }
  }

  static Future<WtSession> join({required String code, required String name}) async {
    final db = WtRtdb.instance;
    dynamic state;
    try {
      state = await db.get('whosthat/$code');
    } catch (_) {
      throw const WtException(WtFailure.network);
    }
    if (state is! Map) throw const WtException(WtFailure.notFound);
    if (state['phase'] != 'lobby') throw const WtException(WtFailure.started);
    final players = state['players'];
    if (players is Map && players.length >= maxPlayers) throw const WtException(WtFailure.full);
    final id = _makeId();
    try {
      await db.put('whosthat/$code/players/$id', {
        'name': name,
        'isHost': false,
        'joinedAt': DateTime.now().millisecondsSinceEpoch,
      });
      await db.put('whosthat/$code/seen/$id', WtRtdb.serverTimestamp);
    } catch (_) {
      throw const WtException(WtFailure.network);
    }
    return WtSession._(code, id, name).._start();
  }

  // ───────────────────────── Live state ─────────────────────────

  Map<String, dynamic>? _state;
  WtLiveValue? _live;
  StreamSubscription<dynamic>? _valuesSub;
  StreamSubscription<bool>? _connSub;
  Timer? _heartbeat;
  Timer? _ticker;
  bool _disposed = false;

  bool connected = true;

  /// The host deleted the room (or it vanished).
  bool ended = false;

  /// The host removed this player.
  bool removed = false;

  bool get ready => _state != null;

  /// Local time each player's heartbeat value last changed.
  final Map<String, DateTime> _seenChangedAt = {};
  final Map<String, Object?> _seenValue = {};

  void _start() {
    _live = _db.listen(_root);
    _valuesSub = _live!.values.listen(_onValue);
    _connSub = _live!.connection.listen((c) {
      if (connected != c) {
        connected = c;
        _notify();
      }
    });
    _live!.start();
    _heartbeat = Timer.periodic(_heartbeatEvery, (_) => _beat());
    // Re-check "Offline" labels every few seconds.
    _ticker = Timer.periodic(const Duration(seconds: 3), (_) => _notify());
  }

  void _beat() {
    if (removed || ended || _state == null) return;
    _db.put('$_root/seen/$myId', WtRtdb.serverTimestamp).catchError((_) {});
  }

  void _onValue(dynamic v) {
    if (_disposed) return;
    if (v is! Map) {
      if (_state != null || _live?.ready == true) {
        ended = true;
        _stopTimers();
      }
      _notify();
      return;
    }
    final s = Map<String, dynamic>.from(v);
    final hadMe = _state == null || _playersMap(_state!).containsKey(myId);
    _state = s;
    if (hadMe && !_playersMap(s).containsKey(myId)) {
      removed = true;
      _stopTimers();
    }

    // Track heartbeats.
    final seen = s['seen'];
    final now = DateTime.now();
    if (seen is Map) {
      seen.forEach((k, val) {
        final id = k.toString();
        if (!_seenValue.containsKey(id) || _seenValue[id] != val) {
          _seenValue[id] = val;
          _seenChangedAt[id] = now;
        }
      });
    }

    _hostDuties();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ───────────────────────── Reading the state ─────────────────────────

  static Map<String, dynamic> _playersMap(Map<String, dynamic> s) {
    final p = s['players'];
    if (p is Map) return p.map((k, v) => MapEntry(k.toString(), v));
    return const {};
  }

  static int _int(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

  String get phase => (_state?['phase'] as String?) ?? 'lobby';
  int get qCount => _int(_state?['qCount'], 10);
  int get target => _int(_state?['target'], 5);
  int get qIndex => _int(_state?['qIndex']);
  int get score => _int(_state?['score']);
  bool get won => _state?['won'] == true;
  String? get hostId => _state?['hostId'] as String?;
  bool get isHost => hostId == myId;

  List<WtPlayer> get players {
    final s = _state;
    if (s == null) return const [];
    final list = <WtPlayer>[];
    _playersMap(s).forEach((id, v) {
      if (v is! Map) return;
      final name = v['name'];
      if (name is! String) return;
      list.add(WtPlayer(id: id, name: name, isHost: v['isHost'] == true, joinedAt: _int(v['joinedAt'])));
    });
    list.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    return list;
  }

  WtPlayer? player(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  Map<String, String> get answers {
    final a = _state?['answers'];
    if (a is! Map) return const {};
    final out = <String, String>{};
    a.forEach((k, v) {
      if (v is String) out[k.toString()] = v;
    });
    return out;
  }

  String? get myAnswer => answers[myId];

  /// Question bank index for the current question.
  int get questionIndex {
    final q = _state?['qIdx'];
    final i = qIndex;
    if (q is List && i < q.length) return _int(q[i], -1);
    if (q is Map) return _int(q['$i'], -1);
    return -1;
  }

  /// A player whose app stopped sending heartbeats. Web players (no
  /// heartbeat) are never shown as offline — the web removes them itself.
  bool isOffline(String id) {
    if (id == myId) return false;
    final at = _seenChangedAt[id];
    if (at == null) return false;
    return DateTime.now().difference(at) > _offlineAfter;
  }

  /// Result of the round on screen (reveal phase).
  WtRoundResult? get roundResult {
    final ids = players.map((p) => p.id).toList();
    final a = answers;
    final picks = [for (final id in ids) if (a[id] != null) a[id]!];
    if (picks.isEmpty) return null;
    if (picks.every((x) => x == picks.first)) return WtRoundResult(WtOutcome.bullseye, [picks.first]);
    final counts = <String, int>{};
    for (final p in picks) {
      counts[p] = (counts[p] ?? 0) + 1;
    }
    final top = counts.values.reduce(max);
    // Keep players in lobby order so names read consistently.
    final leaders = [
      for (final id in ids) if (counts[id] == top) id,
      for (final id in counts.keys) if (counts[id] == top && !ids.contains(id)) id,
    ];
    if (leaders.length == 1) return WtRoundResult(WtOutcome.crowdPick, leaders);
    return WtRoundResult(WtOutcome.tie, leaders);
  }

  // ───────────────────────── Player actions ─────────────────────────

  Future<bool> answer(String targetId) async {
    if (phase != 'question' || myAnswer != null) return false;
    try {
      await _db.put('$_root/answers/$myId', targetId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Leave the room. The host leaving ends the game for everyone (as on web).
  Future<void> leave() async {
    _stopTimers();
    try {
      if (isHost) {
        await _db.delete(_root);
      } else if (!removed && !ended) {
        await _db.delete('$_root/players/$myId');
        await _db.delete('$_root/seen/$myId');
      }
    } catch (_) {}
  }

  // ───────────────────────── Host actions ─────────────────────────

  Future<bool> startGame() async {
    if (!isHost || players.length < 2) return false;
    return _update({'phase': 'question', 'qIndex': 0, 'score': 0, 'answers': null, 'won': null, 'targetHit': null});
  }

  Future<bool> nextQuestion() async {
    if (!isHost) return false;
    final isLast = qIndex + 1 >= qCount;
    final reached = score >= target;
    if (reached || isLast) return _update({'phase': 'end', 'won': reached});
    return _update({'phase': 'question', 'qIndex': qIndex + 1, 'answers': null});
  }

  Future<bool> playAgain() async {
    if (!isHost) return false;
    return _update({
      'phase': 'lobby',
      'qIndex': 0,
      'score': 0,
      'answers': null,
      'qIdx': freshQuestions(qCount),
      'won': null,
      'lastUnanimous': null,
      'lastPickedId': null,
      'targetHit': null,
    });
  }

  Future<bool> removePlayer(String id) async {
    if (!isHost || id == myId) return false;
    try {
      await _db.patch(_root, {'players/$id': null, 'answers/$id': null, 'seen/$id': null});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _update(Map<String, Object?> values) async {
    try {
      await _db.patch(_root, values);
      return true;
    } catch (_) {
      return false;
    }
  }

  String? _resolvingKey;
  Timer? _resolveTimer;
  Timer? _endTimer;

  /// Host only: score the round once everyone has answered (after a short
  /// beat, like the web game), and move on to the results when the target
  /// is reached.
  void _hostDuties() {
    if (!isHost || removed || ended) return;
    final key = '$qIndex';
    if (phase != 'question') _resolvingKey = null;
    if (phase == 'question') {
      final ps = players;
      final a = answers;
      final all = ps.length >= 2 && ps.every((p) => a[p.id] != null);
      if (all && _resolvingKey != key) {
        _resolvingKey = key;
        _resolveTimer?.cancel();
        _resolveTimer = Timer(const Duration(milliseconds: 600), _resolve);
      }
    } else if (phase == 'reveal' && _state?['targetHit'] == true) {
      _endTimer ??= Timer(const Duration(seconds: 2), () {
        _endTimer = null;
        if (phase == 'reveal') _update({'phase': 'end', 'won': true});
      });
    }
  }

  Future<void> _resolve() async {
    if (phase != 'question') return;
    final ps = players;
    final a = answers;
    final picks = [for (final p in ps) if (a[p.id] != null) a[p.id]!];
    if (ps.length < 2 || picks.length < ps.length) {
      _resolvingKey = null; // someone left / was removed — re-check later
      return;
    }
    final unanimous = picks.every((x) => x == picks.first);
    final newScore = score + (unanimous ? 1 : 0);
    await _update({
      'phase': 'reveal',
      'score': newScore,
      'lastUnanimous': unanimous,
      'lastPickedId': unanimous ? picks.first : null,
      'targetHit': newScore >= target,
    });
  }

  void _stopTimers() {
    _heartbeat?.cancel();
    _resolveTimer?.cancel();
    _endTimer?.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimers();
    _ticker?.cancel();
    _valuesSub?.cancel();
    _connSub?.cancel();
    _live?.close();
    super.dispose();
  }
}
