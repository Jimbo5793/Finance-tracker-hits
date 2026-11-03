import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../data/wallet_repository.dart';
import '../models/wallet.dart';
import '../widgets/app_shell.dart';
import '../widgets/primary_button.dart';
import '../widgets/state_panel.dart';
import '../widgets/wallet_card.dart';
import '../widgets/wallet_card_skeleton.dart';

enum _LoadState { loading, error, empty, loaded }

class WalletsScreen extends StatefulWidget {
  final WalletRepository repository;

  /// Opens the create wallet form. Should complete with true when a wallet
  /// was created, so the list reloads. (The form is the next task.)
  final Future<bool?> Function(BuildContext context)? onAddWallet;

  const WalletsScreen({super.key, required this.repository, this.onAddWallet});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  _LoadState _state = _LoadState.loading;
  List<Wallet> _wallets = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _LoadState.loading);
    try {
      final wallets = await widget.repository.getWallets();
      if (!mounted) return;
      setState(() {
        _wallets = wallets;
        _state = wallets.isEmpty ? _LoadState.empty : _LoadState.loaded;
      });
    } on WalletLoadException {
      if (!mounted) return;
      setState(() => _state = _LoadState.error);
    }
  }

  Future<void> _openCreateForm() async {
    final handler = widget.onAddWallet;
    if (handler == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.createFormComingSoon)),
      );
      return;
    }
    final created = await handler(context);
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onAddWallet: _openCreateForm),
          const SizedBox(height: 32),
          _body(),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_state) {
      case _LoadState.loading:
        return const _LoadingView();
      case _LoadState.error:
        return StatePanel(
          icon: Icons.cloud_off_outlined,
          tileColor: AppColors.errorTile,
          iconColor: AppColors.errorIcon,
          title: AppStrings.errorTitle,
          message: AppStrings.errorMessage,
          buttonLabel: AppStrings.retry,
          buttonIcon: Icons.refresh,
          onPressed: _load,
        );
      case _LoadState.empty:
        return StatePanel(
          icon: Icons.account_balance_wallet_outlined,
          tileColor: AppColors.iconTile,
          iconColor: AppColors.iconTileIcon,
          title: AppStrings.emptyTitle,
          message: AppStrings.emptyMessage,
          buttonLabel: AppStrings.addWallet,
          buttonIcon: Icons.add,
          onPressed: _openCreateForm,
        );
      case _LoadState.loaded:
        // No total is shown on purpose: every card stays in its own currency.
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [for (final w in _wallets) WalletCard(wallet: w)],
        );
    }
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onAddWallet;
  const _Header({required this.onAddWallet});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.walletsTitle,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                AppStrings.walletsSubtitle,
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        // Always on screen, including while loading and on error.
        PrimaryButton(
          label: AppStrings.addWallet,
          icon: Icons.add,
          onPressed: onAddWallet,
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [WalletCardSkeleton(), WalletCardSkeleton()],
        ),
        SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(width: 10),
            Text(
              AppStrings.loadingWallets,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
