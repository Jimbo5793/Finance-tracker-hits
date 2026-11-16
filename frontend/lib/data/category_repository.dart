import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category.dart';
import 'api_errors.dart';

class CategoryLoadException implements Exception {
  const CategoryLoadException();
}

class CreateCategoryException implements Exception {
  /// Field errors from the backend, keys lower-cased ('name', 'icon', ...).
  final Map<String, List<String>> fieldErrors;
  const CreateCategoryException([this.fieldErrors = const {}]);
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

  /// POST /categories. kind is "expense" or "income".
  Future<Category> createCategory({
    required String name,
    required String icon,
    String kind = 'expense',
    bool? mandatory, // only for expense categories; leave null for income
  }) async {
    final http.Response response;
    try {
      final token = await tokenProvider();
      response = await _client
          .post(
            Uri.parse('$baseUrl/categories'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': name,
              'icon': icon,
              'kind': kind,
              if (mandatory != null) 'mandatory': mandatory,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const CreateCategoryException();
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return Category.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } catch (_) {
        throw const CreateCategoryException();
      }
    }
    if (response.statusCode == 400) {
      throw CreateCategoryException(parseFieldErrors(response.body));
    }
    throw const CreateCategoryException();
  }
}
