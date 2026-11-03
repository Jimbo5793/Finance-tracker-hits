import 'package:flutter/material.dart';

import 'core/colors.dart';
import 'core/strings.dart';
import 'data/wallet_repository.dart';
import 'screens/wallets_screen.dart';

void main() => runApp(const FinanceTrackerApp());

class FinanceTrackerApp extends StatelessWidget {
  /// Tests pass their own repository (with a mock HTTP client).
  final WalletRepository? repository;

  const FinanceTrackerApp({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    // TODO: replace with your real API address and your real login token.
    final repo =
        repository ??
        WalletRepository(
          baseUrl: 'http://localhost:5000',
          tokenProvider: () async => null,
        );

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: WalletsScreen(repository: repo),
    );
  }
}
