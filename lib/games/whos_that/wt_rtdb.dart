import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// A small Firebase Realtime Database client that talks to the same database
/// as the web game (milkekhelo.com/whosthat.html), over Firebase's public
/// REST API: plain HTTPS reads/writes plus a live "event-stream" for changes.
///
/// Why REST instead of the Firebase SDK plugin: it needs no native setup
/// (no google-services.json, no Gradle plugin, no minSdk changes) and no new
/// packages — only `dart:io`. The database rules already allow the web game
/// to read/write without sign-in, so the same calls work from the app.
///
/// The only thing REST can't do is Firebase's server-side "remove me when I
/// disconnect", so presence is a heartbeat instead (see WtSession).
class WtRtdb {
  WtRtdb._();
  static final WtRtdb instance = WtRtdb._();

  /// Same database as the web game (FIREBASE_CONFIG.databaseURL).
  static const String baseUrl = 'https://whosthat-f2c0c-default-rtdb.asia-southeast1.firebasedatabase.app';

  static const Duration _timeout = Duration(seconds: 12);

  final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..idleTimeout = const Duration(seconds: 30);

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl/$path.json').replace(queryParameters: query);

  /// Server-side timestamp placeholder (resolved by Firebase on write).
  static const Map<String, String> serverTimestamp = {'.sv': 'timestamp'};

  Future<dynamic> get(String path) async {
    final req = await _http.getUrl(_uri(path)).timeout(_timeout);
    final res = await req.close().timeout(_timeout);
    final body = await res.transform(utf8.decoder).join().timeout(_timeout);
    if (res.statusCode != 200) throw WtNetException(res.statusCode, body);
    return jsonDecode(body);
  }

  Future<void> put(String path, Object? value) => _send('PUT', path, value);
  Future<void> patch(String path, Map<String, Object?> value) => _send('PATCH', path, value);
  Future<void> delete(String path) => _send('DELETE', path, null);

  Future<void> _send(String method, String path, Object? value) async {
    final req = await _http.openUrl(method, _uri(path, const {'print': 'silent'})).timeout(_timeout);
    if (method != 'DELETE') {
      final bytes = utf8.encode(jsonEncode(value));
      req.headers.contentType = ContentType.json;
      req.contentLength = bytes.length;
      req.add(bytes);
    }
    final res = await req.close().timeout(_timeout);
    final body = await res.transform(utf8.decoder).join().timeout(_timeout);
    if (res.statusCode >= 300) throw WtNetException(res.statusCode, body);
  }

  /// Live view of the value at [path]: emits the whole value every time any
  /// part of it changes (null when it's deleted). Reconnects by itself.
  WtLiveValue listen(String path) => WtLiveValue._(this, path);
}

class WtNetException implements Exception {
  final int status;
  final String body;
  WtNetException(this.status, this.body);
  @override
  String toString() => 'WtNetException($status): $body';
}

/// Firebase REST streaming (Server-Sent Events). Keeps a local copy of the
/// node and applies each `put` / `patch` event to it.
class WtLiveValue {
  final WtRtdb _db;
  final String path;

  WtLiveValue._(this._db, this.path);

  final _values = StreamController<dynamic>.broadcast();
  final _connected = StreamController<bool>.broadcast();

  /// Every new full value of the node (null = node deleted).
  Stream<dynamic> get values => _values.stream;

  /// true while the live stream is open.
  Stream<bool> get connection => _connected.stream;

  dynamic _tree;
  bool _closed = false;
  bool _receivedFirst = false;
  HttpClientResponse? _res;
  StreamSubscription<String>? _sub;
  int _failures = 0;

  void start() => _connect();

  Future<void> _connect() async {
    if (_closed) return;
    try {
      final req = await _db._http.getUrl(_db._uri(path)).timeout(WtRtdb._timeout);
      req.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      req.followRedirects = true;
      final res = await req.close().timeout(WtRtdb._timeout);
      if (_closed) {
        res.detachSocket().then((s) => s.destroy()).catchError((_) {});
        return;
      }
      if (res.statusCode != 200) {
        await res.drain<void>().catchError((_) {});
        throw WtNetException(res.statusCode, 'stream');
      }
      _res = res;
      _failures = 0;
      _connected.add(true);

      String? event;
      final data = StringBuffer();
      _sub = res.transform(utf8.decoder).transform(const LineSplitter()).listen(
        (line) {
          if (line.isEmpty) {
            if (event != null) _handle(event!, data.toString());
            event = null;
            data.clear();
          } else if (line.startsWith('event:')) {
            event = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            if (data.isNotEmpty) data.write('\n');
            data.write(line.substring(5).trim());
          }
        },
        onError: (_) => _retry(),
        onDone: _retry,
        cancelOnError: true,
      );
    } catch (_) {
      _retry();
    }
  }

  void _handle(String event, String data) {
    switch (event) {
      case 'put':
      case 'patch':
        final msg = jsonDecode(data);
        if (msg is! Map) return;
        final keys = (msg['path'] as String? ?? '/').split('/').where((k) => k.isNotEmpty).toList();
        if (event == 'put') {
          _tree = _setAt(_tree, keys, msg['data']);
        } else if (msg['data'] is Map) {
          (msg['data'] as Map).forEach((k, v) {
            final sub = [...keys, ...k.toString().split('/').where((x) => x.isNotEmpty)];
            _tree = _setAt(_tree, sub, v);
          });
        }
        _receivedFirst = true;
        if (!_values.isClosed) _values.add(_tree);
        break;
      case 'cancel':
      case 'auth_revoked':
        _retry();
        break;
      default: // keep-alive
        break;
    }
  }

  /// true once the first full value has arrived.
  bool get ready => _receivedFirst;

  void _retry() {
    _sub?.cancel();
    _sub = null;
    _res = null;
    if (_closed) return;
    if (!_connected.isClosed) _connected.add(false);
    _failures++;
    final wait = Duration(milliseconds: min(8000, 500 * (1 << min(_failures, 4))));
    Future.delayed(wait, _connect);
  }

  Future<void> close() async {
    _closed = true;
    await _sub?.cancel();
    try {
      final s = await _res?.detachSocket();
      s?.destroy();
    } catch (_) {}
    await _values.close();
    await _connected.close();
  }

  static dynamic _setAt(dynamic node, List<String> keys, dynamic value) {
    if (keys.isEmpty) return value;
    final map = <String, dynamic>{};
    if (node is Map) {
      node.forEach((k, v) => map[k.toString()] = v);
    } else if (node is List) {
      for (var i = 0; i < node.length; i++) {
        if (node[i] != null) map['$i'] = node[i];
      }
    }
    final child = _setAt(map[keys.first], keys.sublist(1), value);
    if (child == null) {
      map.remove(keys.first);
    } else {
      map[keys.first] = child;
    }
    return map.isEmpty ? null : map;
  }
}
