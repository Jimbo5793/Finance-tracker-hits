import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The logged-in state: the token the backend gave us and when it stops working.
///
/// It is saved in the browser's storage, so a page reload keeps the user logged in.
/// The router listens to this object: signing in or out changes the screen.
class AuthSession extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _expiresKey = 'auth_expires_at';

  final SharedPreferences? _prefs;
  String? _token;
  DateTime? _expiresAt;

  /// Without [prefs] nothing is saved (used by tests).
  AuthSession({SharedPreferences? prefs, String? token, DateTime? expiresAt})
    : _prefs = prefs,
      _token = token,
      _expiresAt = expiresAt;

  /// Reads the saved login. A token that has already expired is thrown away.
  static Future<AuthSession> load() async {
    final prefs = await SharedPreferences.getInstance();
    final session = AuthSession(
      prefs: prefs,
      token: prefs.getString(_tokenKey),
      expiresAt: DateTime.tryParse(prefs.getString(_expiresKey) ?? ''),
    );
    if (!session.isLoggedIn) await session._forget();
    return session;
  }

  bool get isLoggedIn {
    final expiresAt = _expiresAt;
    return _token != null &&
        expiresAt != null &&
        expiresAt.isAfter(DateTime.now());
  }

  /// The token to send with requests, or null when logged out.
  String? get token => isLoggedIn ? _token : null;

  Future<void> signIn(String token, DateTime expiresAt) async {
    _token = token;
    _expiresAt = expiresAt;
    notifyListeners();
    await _prefs?.setString(_tokenKey, token);
    await _prefs?.setString(_expiresKey, expiresAt.toUtc().toIso8601String());
  }

  Future<void> signOut() async {
    if (_token == null) return; // already signed out (several requests can fail at once)
    _token = null;
    _expiresAt = null;
    notifyListeners();
    await _forget();
  }

  Future<void> _forget() async {
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_expiresKey);
  }
}
