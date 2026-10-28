import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Base URL of the backend. Empty means "same origin as the web page",
/// which is how it runs behind nginx in docker-compose.
/// Override when running outside Docker, e.g.
///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

void main() => runApp(const FinanceTrackerApp());

class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key, this.client});

  /// Injected in tests; a real client is created otherwise.
  final http.Client? client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finance Tracker',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: HomePage(client: client ?? http.Client()),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.client});

  final http.Client client;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _apiStatus = 'checking…';

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    final uri = apiBaseUrl.isEmpty
        ? Uri.base.resolve('/api/health')
        : Uri.parse('$apiBaseUrl/api/health');
    String status;
    try {
      final response = await widget.client.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      status = body['status'] as String? ?? 'unknown';
    } catch (_) {
      status = 'unreachable';
    }
    if (mounted) setState(() => _apiStatus = status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Finance Tracker')),
      body: Center(child: Text('API status: $_apiStatus')),
    );
  }
}
