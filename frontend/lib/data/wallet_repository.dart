import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/currency.dart';
import '../models/wallet.dart';

class WalletLoadException implements Exception {
  final String message;
  const WalletLoadException(this.message);
  @override
  String toString() => message;
}

class CurrencyLoadException implements Exception {
  const CurrencyLoadException();
}

/// Thrown when a wallet could not be created.
/// [fieldErrors] is filled when the backend answered 400. Keys are lower-case
/// ("name", "type", "currency", "startingbalance"). Empty means a general failure
/// (no connection, timeout, server error).
class CreateWalletException implements Exception {
  final Map<String, List<String>> fieldErrors;
  const CreateWalletException([this.fieldErrors = const {}]);
}

class WalletRepository {
  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  WalletRepository({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 10);

  Future<Map<String, String>> _headers() async {
    final token = await tokenProvider();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET /wallets
  Future<List<Wallet>> getWallets() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/wallets'), headers: await _headers())
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw WalletLoadException('Server answered ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Wallet.fromJson(e as Map<String, dynamic>))
          .toList();
    } on WalletLoadException catch (e) {
      debugPrint('Wallet load failed: $e');
      rethrow;
    } catch (e) {
      debugPrint('Wallet load failed: $e');
      throw WalletLoadException(e.toString());
    }
  }

  /// GET /currencies
  Future<List<Currency>> getCurrencies() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/currencies'), headers: await _headers())
          .timeout(_timeout);

      if (response.statusCode != 200) throw const CurrencyLoadException();

      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Currency.fromJson(e as Map<String, dynamic>))
          .toList();
    } on CurrencyLoadException {
      rethrow;
    } catch (_) {
      throw const CurrencyLoadException();
    }
  }

  /// POST /wallets. Returns the new wallet, or throws [CreateWalletException].
  /// A null [name] is left out, so the backend makes the default name.
  Future<Wallet> createWallet({
    String? name,
    required String type,
    required String currency,
    required double startingBalance,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/wallets'),
            headers: {...await _headers(), 'Content-Type': 'application/json'},
            body: jsonEncode({
              if (name != null) 'name': name,
              'type': type,
              'currency': currency,
              // sent as a JSON number, the backend rejects strings here
              'startingBalance': startingBalance,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Wallet.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      if (response.statusCode == 400) {
        throw CreateWalletException(_parseFieldErrors(response.body));
      }
      throw const CreateWalletException();
    } on CreateWalletException {
      rethrow;
    } catch (e) {
      debugPrint('Create wallet failed: $e');
      throw const CreateWalletException();
    }
  }

  /// Reads {"errors": {"name": ["..."], ...}} from the backend's 400 answer.
  Map<String, List<String>> _parseFieldErrors(String body) {
    try {
      final json = jsonDecode(body);
      final errors = json is Map ? json['errors'] : null;
      if (errors is! Map) return {};
      return {
        for (final entry in errors.entries)
          entry.key.toString().toLowerCase(): [
            for (final message in entry.value as List) message.toString(),
          ],
      };
    } catch (_) {
      return {};
    }
  }
}
