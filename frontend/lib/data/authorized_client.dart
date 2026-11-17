import 'package:http/http.dart' as http;

/// Wraps an HTTP client. When the backend answers 401 to a request that carried
/// a token, the saved login is no longer valid (expired, logged out elsewhere,
/// or the database was reset), so [onUnauthorized] signs the user out and the
/// router shows the login screen instead of an endless "could not load" error.
///
/// Requests without a token are left alone, so a wrong password at login
/// does not count.
class AuthorizedClient extends http.BaseClient {
  final http.Client _inner;
  final void Function() onUnauthorized;

  AuthorizedClient(this._inner, {required this.onUnauthorized});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (response.statusCode == 401 &&
        request.headers.containsKey('Authorization')) {
      onUnauthorized();
    }
    return response;
  }

  @override
  void close() => _inner.close();
}
