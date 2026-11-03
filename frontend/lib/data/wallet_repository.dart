import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallet.dart';

class WalletLoadException implements Exception {
  final String message;
  const WalletLoadException(this.message);
  @override
  String toString() => message;
}

/// Talks to the backend for wallets.
///
/// [baseUrl] is the API address, e.g. http://localhost:5000
/// [tokenProvider] returns the logged-in user's token (the endpoints use [Authorize]).
class WalletRepository {
  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  WalletRepository({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// GET /wallets. Throws [WalletLoadException] on any failure.
  Future<List<Wallet>> getWallets() async {
    try {
      final token = await tokenProvider();
      final response = await _client.get(
        Uri.parse('$baseUrl/wallets'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw WalletLoadException('Server answered ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Wallet.fromJson(e as Map<String, dynamic>))
          .toList();
    } on WalletLoadException {
      rethrow;
    } catch (e) {
      // No connection, timeout, bad JSON, etc. The screen only needs to know it failed.
      throw WalletLoadException(e.toString());
    }
  }
}
