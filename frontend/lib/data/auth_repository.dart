import 'dart:convert';

import 'package:http/http.dart' as http;

enum LoginFailure {
  /// 401: the email or the password is wrong.
  wrongCredentials,

  /// No connection, a timeout, or any answer other than 200 / 401.
  /// Example: nginx answers 502 while the backend is stopped.
  unavailable,
}

class LoginException implements Exception {
  final LoginFailure failure;
  const LoginException(this.failure);
}

class LoginResult {
  final String token;
  final DateTime expiresAt;
  const LoginResult(this.token, this.expiresAt);
}

class AuthRepository {
  final String baseUrl;
  final http.Client _client;

  AuthRepository({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 10);

  /// POST /auth/login. The backend field is called "username", but it accepts
  /// an email as well (it looks for an "@"), so the email goes in there.
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'username': email, 'password': password}),
          )
          .timeout(_timeout);
    } catch (_) {
      throw const LoginException(LoginFailure.unavailable);
    }

    if (response.statusCode == 401) {
      throw const LoginException(LoginFailure.wrongCredentials);
    }
    if (response.statusCode != 200) {
      throw const LoginException(LoginFailure.unavailable);
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return LoginResult(
        json['token'] as String,
        _parseUtc(json['expiresAt'] as String),
      );
    } catch (_) {
      throw const LoginException(LoginFailure.unavailable);
    }
  }
  
  /// POST /auth/logout with the token that is being given up. Best effort: the
  /// caller has already signed out locally, so no connection, or a token the
  /// backend no longer knows, changes nothing for the user.
  Future<void> logout(String token) async {
    try {
      await _client
          .post(
            Uri.parse('$baseUrl/auth/logout'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);
    } catch (_) {
      // Ignored on purpose, see above.
    }
  }

  /// The backend sends UTC. If the "Z" is missing, it is still read as UTC.
  static DateTime _parseUtc(String value) {
    final hasZone =
        value.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(value);
    return DateTime.parse(hasZone ? value : '${value}Z').toUtc();
  }
}
