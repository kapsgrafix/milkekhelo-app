import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_config.dart';

enum SignInProvider { google, facebook }

/// The signed-in player.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final SignInProvider provider;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.provider,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photo': photoUrl,
        'provider': provider.name,
      };

  static AppUser? fromJson(Map<String, dynamic> j) {
    final uid = j['uid'];
    if (uid is! String || uid.isEmpty) return null;
    return AppUser(
      uid: uid,
      name: (j['name'] as String?) ?? '',
      email: (j['email'] as String?) ?? '',
      photoUrl: (j['photo'] as String?) ?? '',
      provider: j['provider'] == 'facebook' ? SignInProvider.facebook : SignInProvider.google,
    );
  }
}

class AuthException implements Exception {
  /// 'cancelled' (player closed the picker), 'busy', 'network', or a
  /// short provider/Firebase code — shown in the error toast to help debug.
  final String code;
  final String? detail;
  const AuthException(this.code, [this.detail]);

  bool get cancelled => code == 'cancelled';

  @override
  String toString() => 'AuthException($code${detail == null ? '' : ': $detail'})';
}

/// Player accounts: Google (now) and Facebook (next) sign-in, exchanged for
/// a Firebase session through the Firebase Auth REST API — the same
/// no-native-SDK approach the multiplayer games use for the database.
///
/// The session (refresh token + profile) is kept on the device, so the
/// player stays signed in between launches. [idToken] returns a fresh
/// Firebase ID token for database calls (cloud save, next stage).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// The signed-in player, or null for a guest. Listen to rebuild UI.
  final ValueNotifier<AppUser?> user = ValueNotifier<AppUser?>(null);

  /// True while a sign-in is in progress (buttons show a spinner).
  final ValueNotifier<bool> busy = ValueNotifier<bool>(false);

  bool get signedIn => user.value != null;

  static const _kUser = 'auth_user';
  static const _kRefresh = 'auth_refresh_token';

  String? _refreshToken;
  String? _idToken;
  DateTime _idTokenExpiry = DateTime.fromMillisecondsSinceEpoch(0);
  bool _googleReady = false;

  /// Restore a saved session. Call once at app start (fast: local only).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kUser);
      final refresh = prefs.getString(_kRefresh);
      if (raw != null && refresh != null && refresh.isNotEmpty) {
        final u = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (u != null) {
          _refreshToken = refresh;
          user.value = u;
        }
      }
    } catch (_) {
      // A broken saved session just means "signed out".
    }
  }

  // ───────────────────────── Google ─────────────────────────

  Future<void> _ensureGoogle() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(serverClientId: AuthConfig.googleWebClientId);
    _googleReady = true;
  }

  Future<AppUser> signInWithGoogle() async {
    if (busy.value) throw const AuthException('busy');
    busy.value = true;
    try {
      await _ensureGoogle();
      final GoogleSignInAccount account;
      try {
        account = await GoogleSignIn.instance.authenticate(scopeHint: const ['email']);
      } on GoogleSignInException catch (e) {
        // Note: a misconfigured app (fingerprint not registered with Google)
        // is also reported as "canceled" — keep Google's reason so it shows.
        if (e.code == GoogleSignInExceptionCode.canceled) throw AuthException('cancelled', e.description);
        throw AuthException('google_${e.code.name}', e.description);
      }
      final googleIdToken = account.authentication.idToken;
      if (googleIdToken == null || googleIdToken.isEmpty) throw const AuthException('google_no_token');
      return await _signInWithIdp(
        postBody: 'id_token=${Uri.encodeQueryComponent(googleIdToken)}&providerId=google.com',
        provider: SignInProvider.google,
        fallbackName: account.displayName,
        fallbackEmail: account.email,
        fallbackPhoto: account.photoUrl,
      );
    } finally {
      busy.value = false;
    }
  }

  // ───────────────────────── Facebook (next) ─────────────────────────

  /// Exchanges a Facebook access token for a Firebase session. Wired up
  /// once the Facebook app is set up.
  Future<AppUser> signInWithFacebookToken(String accessToken) => _signInWithIdp(
        postBody: 'access_token=${Uri.encodeQueryComponent(accessToken)}&providerId=facebook.com',
        provider: SignInProvider.facebook,
      );

  // ───────────────────────── Firebase REST ─────────────────────────

  Future<AppUser> _signInWithIdp({
    required String postBody,
    required SignInProvider provider,
    String? fallbackName,
    String? fallbackEmail,
    String? fallbackPhoto,
  }) async {
    final res = await _post(
      Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=${AuthConfig.apiKey}'),
      jsonEncode({
        'postBody': postBody,
        'requestUri': 'http://localhost',
        'returnSecureToken': true,
        'returnIdpCredential': true,
      }),
      'application/json',
    );
    final uid = res['localId'] as String?;
    final idToken = res['idToken'] as String?;
    final refresh = res['refreshToken'] as String?;
    if (uid == null || idToken == null || refresh == null) throw const AuthException('firebase_bad_response');

    final u = AppUser(
      uid: uid,
      name: (res['displayName'] as String?) ?? fallbackName ?? '',
      email: (res['email'] as String?) ?? fallbackEmail ?? '',
      photoUrl: (res['photoUrl'] as String?) ?? fallbackPhoto ?? '',
      provider: provider,
    );
    _idToken = idToken;
    _idTokenExpiry = DateTime.now().add(Duration(seconds: (int.tryParse('${res['expiresIn']}') ?? 3600) - 120));
    _refreshToken = refresh;
    user.value = u;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUser, jsonEncode(u.toJson()));
      await prefs.setString(_kRefresh, refresh);
    } catch (_) {}
    return u;
  }

  /// A valid Firebase ID token for the signed-in player (refreshed when
  /// needed), or null for a guest / if the session has expired.
  Future<String?> idToken() async {
    if (!signedIn || _refreshToken == null) return null;
    if (_idToken != null && DateTime.now().isBefore(_idTokenExpiry)) return _idToken;
    try {
      final res = await _post(
        Uri.parse('https://securetoken.googleapis.com/v1/token?key=${AuthConfig.apiKey}'),
        'grant_type=refresh_token&refresh_token=${Uri.encodeQueryComponent(_refreshToken!)}',
        'application/x-www-form-urlencoded',
      );
      _idToken = res['id_token'] as String?;
      final newRefresh = res['refresh_token'] as String?;
      _idTokenExpiry = DateTime.now().add(Duration(seconds: (int.tryParse('${res['expires_in']}') ?? 3600) - 120));
      if (newRefresh != null && newRefresh != _refreshToken) {
        _refreshToken = newRefresh;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kRefresh, newRefresh);
      }
      return _idToken;
    } on AuthException catch (e) {
      // The account was removed / disabled: sign out locally.
      if (e.code.contains('TOKEN_EXPIRED') || e.code.contains('USER_NOT_FOUND') || e.code.contains('USER_DISABLED') ||
          e.code.contains('INVALID_REFRESH_TOKEN')) {
        await signOut();
      }
      return null;
    }
  }

  /// Permanently deletes the player's account and their saved data.
  /// Firebase asks for a recent sign-in before deleting; if the session is
  /// too old, Google sign-in runs again first (the account picker shows).
  Future<void> deleteAccount() async {
    final u = user.value;
    if (u == null) return;
    var token = await idToken();
    if (token == null) throw const AuthException('not_signed_in');

    // Saved data first (best scores / games) — ignore if there's none yet.
    await _deleteUrl(Uri.parse('${AuthConfig.databaseUrl}/users/${u.uid}.json?auth=$token'));

    Future<void> deleteUser(String t) => _post(
          Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${AuthConfig.apiKey}'),
          jsonEncode({'idToken': t}),
          'application/json',
        );
    try {
      await deleteUser(token);
    } on AuthException catch (e) {
      if (!e.code.contains('CREDENTIAL_TOO_OLD') || u.provider != SignInProvider.google) rethrow;
      await signInWithGoogle(); // fresh sign-in, then try again
      token = await idToken();
      if (token == null) throw const AuthException('not_signed_in');
      await deleteUser(token);
    }
    if (u.provider == SignInProvider.google) {
      try {
        await _ensureGoogle();
        await GoogleSignIn.instance.disconnect(); // also forget the app grant
      } catch (_) {}
    }
    await signOut();
  }

  Future<void> _deleteUrl(Uri url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.deleteUrl(url);
      final resp = await req.close().timeout(const Duration(seconds: 20));
      await resp.drain<void>();
    } catch (_) {
      // Best effort.
    } finally {
      client.close(force: true);
    }
  }

  Future<void> signOut() async {
    final provider = user.value?.provider;
    user.value = null;
    _idToken = null;
    _refreshToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUser);
      await prefs.remove(_kRefresh);
    } catch (_) {}
    if (provider == SignInProvider.google) {
      try {
        await _ensureGoogle();
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> _post(Uri url, String body, String contentType) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.postUrl(url);
      req.headers.set(HttpHeaders.contentTypeHeader, contentType);
      req.headers.set('X-Android-Package', AuthConfig.androidPackage);
      req.headers.set('X-Android-Cert', AuthConfig.androidCertSha1);
      req.add(utf8.encode(body));
      final resp = await req.close().timeout(const Duration(seconds: 20));
      final text = await resp.transform(utf8.decoder).join();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(text) as Map<String, dynamic>;
      } catch (_) {
        throw AuthException('http_${resp.statusCode}');
      }
      if (resp.statusCode >= 400) {
        final err = data['error'];
        final msg = err is Map ? '${err['message']}' : '$err';
        debugPrint('Auth error ${resp.statusCode}: $msg');
        throw AuthException(msg.split(' ').first, msg);
      }
      return data;
    } on AuthException {
      rethrow;
    } on SocketException {
      throw const AuthException('network');
    } on TimeoutException {
      throw const AuthException('network');
    } on HandshakeException {
      throw const AuthException('network');
    } finally {
      client.close(force: true);
    }
  }
}
