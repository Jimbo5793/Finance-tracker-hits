import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/operation.dart';
import 'api_errors.dart';

class OperationLoadException implements Exception {
  const OperationLoadException();
}

/// Thrown when an operation could not be recorded. [fieldErrors] is filled when the
/// backend names wrong fields (keys in lower case). Empty means a general failure
/// (no connection, timeout, server error).
class CreateOperationException implements Exception {
  final Map<String, List<String>> fieldErrors;
  const CreateOperationException([this.fieldErrors = const {}]);
}

class OperationRepository {
  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  OperationRepository({
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

  /// GET /operations?walletId=...&limit=500 (500 is the backend maximum, the default is 100).
  Future<List<Operation>> getOperations(int walletId) async {
    try {
      final uri = Uri.parse('$baseUrl/operations').replace(
        queryParameters: {'walletId': '$walletId', 'limit': '500'},
      );
      final response = await _client
          .get(uri, headers: await _headers())
          .timeout(_timeout);

      if (response.statusCode != 200) throw const OperationLoadException();

      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Operation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on OperationLoadException {
      rethrow;
    } catch (_) {
      throw const OperationLoadException();
    }
  }

  /// POST /operations. [date] is "yyyy-MM-dd". Returns the new operation,
  /// or throws [CreateOperationException].
  Future<Operation> createOperation({
    required int walletId,
    required double amount,
    required String date,
    String type = 'expense',
    int? categoryId,
    String? comment,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/operations'),
            headers: {...await _headers(), 'Content-Type': 'application/json'},
            body: jsonEncode({
              'walletId': walletId,
              'type': type,
              'amount':
                  amount, // a JSON number, the backend rejects strings here
              'date': date,
              if (categoryId != null) 'categoryId': categoryId,
              if (comment != null) 'comment': comment,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Operation.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      if (response.statusCode == 400) {
        throw CreateOperationException(parseFieldErrors(response.body));
      }
      if (response.statusCode == 404) {
        // The wallet is not the user's (or does not exist).
        throw CreateOperationException({
          'walletid': [parseTitle(response.body) ?? 'Wallet not found.'],
        });
      }
      throw const CreateOperationException();
    } on CreateOperationException {
      rethrow;
    } catch (_) {
      throw const CreateOperationException();
    }
  }
}
