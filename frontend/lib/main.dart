import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';
import 'core/colors.dart';
import 'core/strings.dart';
import 'data/category_repository.dart';
import 'data/operation_repository.dart';
import 'data/wallet_repository.dart';

void main() => runApp(const FinanceTrackerApp());

class FinanceTrackerApp extends StatefulWidget {
  /// Tests pass their own repositories (with a mock HTTP client).
  final WalletRepository? repository;
  final OperationRepository? operationRepository;
  final CategoryRepository? categoryRepository;

  const FinanceTrackerApp({
    super.key,
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
    // TODO: replace with your real API address and the real login token (login task).
    const baseUrl = 'https://localhost:5001';
    Future<String?> token() async => null;

    _router = buildRouter(
      wallets:
          widget.repository ??
          WalletRepository(baseUrl: baseUrl, tokenProvider: token),
      operations:
          widget.operationRepository ??
          OperationRepository(baseUrl: baseUrl, tokenProvider: token),
      categories:
          widget.categoryRepository ??
          CategoryRepository(baseUrl: baseUrl, tokenProvider: token),
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
