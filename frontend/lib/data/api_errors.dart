import 'dart:convert';

/// Reads {"errors": {"amount": ["..."], ...}} from the backend's 400 answer.
/// Field names are lower-cased ("walletid", "categoryid", ...).
Map<String, List<String>> parseFieldErrors(String body) {
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

/// Reads {"title": "..."} from answers like 404 / 401.
String? parseTitle(String body) {
  try {
    final json = jsonDecode(body);
    final title = json is Map ? json['title'] : null;
    return title is String ? title : null;
  } catch (_) {
    return null;
  }
}
