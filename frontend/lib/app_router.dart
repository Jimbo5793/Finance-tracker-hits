import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/strings.dart';
import 'data/category_repository.dart';
import 'data/operation_repository.dart';
import 'data/wallet_repository.dart';
import 'models/wallet.dart';
import 'screens/wallet_details_screen.dart';
import 'screens/wallets_screen.dart';
import 'widgets/app_shell.dart';

GoRouter buildRouter({
  required WalletRepository wallets,
  required OperationRepository operations,
  required CategoryRepository categories,
}) {
  final shell = ShellController();

  return GoRouter(
    initialLocation: '/wallets',
    routes: [
      // Everything inside this route shares one sidebar and one top bar.
      // TODO(login task): the login route goes OUTSIDE the ShellRoute, plus a redirect.
      ShellRoute(
        builder: (context, state, child) => AppShell(
          location: state.uri.path,
          controller: shell,
          // TODO(login task): call POST /auth/logout, clear the token, go to /login.
          onLogOut: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.logOutComingSoon)),
          ),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/wallets',
            pageBuilder: (context, state) => NoTransitionPage(
              child: WalletsScreen(
                repository: wallets,
                operationRepository: operations,
                categoryRepository: categories,
              ),
            ),
          ),
          GoRoute(
            path: '/wallets/:id',
            redirect: (context, state) =>
                int.tryParse(state.pathParameters['id'] ?? '') == null
                ? '/wallets'
                : null,
            pageBuilder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              final extra = state.extra;
              return NoTransitionPage(
                child: WalletDetailsScreen(
                  key: ValueKey(id),
                  walletId: id,
                  // Passed when coming from the list. Lost on a browser reload, so the screen
                  // can also load the wallet by itself.
                  initialWallet: extra is Wallet ? extra : null,
                  walletRepository: wallets,
                  operationRepository: operations,
                  categoryRepository: categories,
                  shell: shell,
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}
