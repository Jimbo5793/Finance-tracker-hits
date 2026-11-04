import 'dart:async';

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
import 'create_wallet_dialog.dart';

enum _LoadState { loading, error, empty, loaded }

class WalletsScreen extends StatefulWidget {
  final WalletRepository repository;
  const WalletsScreen({super.key, required this.repository});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  _LoadState _state = _LoadState.loading;
  List<Wallet> _wallets = const [];

  /// The wallet that was just created. Drives the green banner and card highlight.
  Wallet? _createdWallet;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _state = _LoadState.loading;
      _createdWallet = null;
    });
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
    final created = await showDialog<Wallet>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.scrim,
      builder: (_) => CreateWalletDialog(repository: widget.repository),
    );
    if (created == null || !mounted) return; // cancelled

    // If the list never loaded, reload it so the old wallets are not hidden.
    if (_state != _LoadState.loaded && _state != _LoadState.empty) {
      _load();
      return;
    }

    setState(() {
      _wallets = [..._wallets, created]; // backend lists oldest first
      _state = _LoadState.loaded;
      _createdWallet = created;
    });

    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _createdWallet = null);
    });
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_createdWallet != null) ...[
              _SuccessBanner(
                message: AppStrings.walletCreated(_createdWallet!.name),
              ),
              const SizedBox(height: 24),
            ],
            _WalletGrid(wallets: _wallets, highlightId: _createdWallet?.id),
          ],
        );
    }
  }
}

class _WalletGrid extends StatelessWidget {
  final List<Wallet> wallets;
  final int? highlightId;
  const _WalletGrid({required this.wallets, this.highlightId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 20.0;
        final columns = constraints.maxWidth >= 960
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final cardWidth =
            ((constraints.maxWidth - gap * (columns - 1)) / columns)
                .floorToDouble();

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final w in wallets)
              WalletCard(
                wallet: w,
                width: cardWidth,
                highlighted: w.id == highlightId,
              ),
          ],
        );
      },
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String message;
  const _SuccessBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.successBanner,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
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
