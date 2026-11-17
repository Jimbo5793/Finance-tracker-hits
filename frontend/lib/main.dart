import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'app_router.dart';
import 'core/colors.dart';
import 'core/strings.dart';
import 'data/auth_repository.dart';
import 'data/auth_session.dart';
import 'data/authorized_client.dart';
import 'data/category_repository.dart';
import 'data/operation_repository.dart';
import 'data/wallet_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read the saved login before the first screen, so a reload does not flash
  // the login screen for a user who is still logged in.
  final session = await AuthSession.load();
  runApp(FinanceTrackerApp(session: session));
}

class FinanceTrackerApp extends StatefulWidget {
  final AuthSession session;

  /// Tests pass their own repositories (with a mock HTTP client).
  final AuthRepository? authRepository;
  final WalletRepository? repository;
  final OperationRepository? operationRepository;
  final CategoryRepository? categoryRepository;

  const FinanceTrackerApp({
    super.key,
    required this.session,
    this.authRepository,
    this.repository,
    this.operationRepository,
    this.categoryRepository,
  });

  @override
  State<FinanceTrackerApp> createState() => _FinanceTrackerAppState();
}

class _FinanceTrackerAppState extends State<FinanceTrackerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // "/api" is the same-origin route through nginx (see frontend/nginx.conf).
    // `flutter run` has no such route: pass --dart-define=API_BASE_URL=<backend address>.
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '/api',
    );
    final session = widget.session;
    Future<String?> token() async => session.token;

    // A 401 to a request that carried our token means the login is no longer
    // valid, so the user is signed out and sent to the login screen.
    final client = AuthorizedClient(
      http.Client(),
      onUnauthorized: session.signOut,
    );

    _router = buildRouter(
      session: session,
      auth:
          widget.authRepository ??
          AuthRepository(baseUrl: baseUrl),
      wallets:
          widget.repository ??
          WalletRepository(
            baseUrl: baseUrl,
            tokenProvider: token,
            client: client,
          ),
      operations:
          widget.operationRepository ??
          OperationRepository(
            baseUrl: baseUrl,
            tokenProvider: token,
            client: client,
          ),
      categories:
          widget.categoryRepository ??
          CategoryRepository(
            baseUrl: baseUrl,
            tokenProvider: token,
            client: client,
          ),
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      routerConfig: _router,
    );
  }
}
