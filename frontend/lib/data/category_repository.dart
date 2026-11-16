import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category.dart';

class CategoryLoadException implements Exception {
  const CategoryLoadException();
}

class CategoryRepository {
  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  CategoryRepository({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// GET /categories, optionally only "income" or "expense".
  Future<List<Category>> getCategories({String? kind}) async {
    try {
      final token = await tokenProvider();
      final base = Uri.parse('$baseUrl/categories');
      final uri = kind == null
          ? base
          : base.replace(queryParameters: {'kind': kind});

      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) throw const CategoryLoadException();

      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } on CategoryLoadException {
      rethrow;
    } catch (_) {
      throw const CategoryLoadException();
    }
  }
}
