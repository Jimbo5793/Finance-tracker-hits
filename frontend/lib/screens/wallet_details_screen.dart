import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../data/category_repository.dart';
import '../data/operation_repository.dart';
import '../data/wallet_repository.dart';
import '../models/category.dart';
import '../models/operation.dart';
import '../models/wallet.dart';
import '../widgets/app_shell.dart';
import '../widgets/state_panel.dart';
import '../widgets/transactions_panel.dart';
import '../widgets/wallet_summary_card.dart';
import '../widgets/success_snack_bar.dart';
import 'record_expense_dialog.dart';
import 'create_category_dialog.dart';

enum _WalletStatus { loading, ready, error, notFound }

class WalletDetailsScreen extends StatefulWidget {
  final int walletId;

  /// The wallet from the list, so the header shows at once. Refreshed in the background.
  final Wallet? initialWallet;
  final WalletRepository walletRepository;
  final OperationRepository operationRepository;
  final CategoryRepository categoryRepository;
  final ShellController shell;

  const WalletDetailsScreen({
    super.key,
    required this.walletId,
    this.initialWallet,
    required this.walletRepository,
    required this.operationRepository,
    required this.categoryRepository,
    required this.shell,
  });

  @override
  State<WalletDetailsScreen> createState() => _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends State<WalletDetailsScreen> {
  /// The month shown in the header cards and the table.
  final DateTime _month = DateTime.now();

  Wallet? _wallet;
  _WalletStatus _walletStatus = _WalletStatus.loading;

  TransactionsStatus _status = TransactionsStatus.loading;
  List<Operation> _operations = const [];
  Map<int, Category> _categories = const {};

  @override
  void initState() {
    super.initState();
    final initial = widget.initialWallet;
    if (initial != null) {
      _wallet = initial;
      _walletStatus = _WalletStatus.ready;
      // The top bar is already built this frame, so tell it after the frame.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.shell.setWalletName(initial.id, initial.name),
      );
    }
    _loadWallet();
    _loadTransactions();
  }

  Future<void> _loadWallet() async {
    try {
      final wallets = await widget.walletRepository.getWallets();
      if (!mounted) return;

      Wallet? found;
      for (final w in wallets) {
        if (w.id == widget.walletId) found = w;
      }
      setState(() {
        _wallet = found;
        _walletStatus = found == null
            ? _WalletStatus.notFound
            : _WalletStatus.ready;
      });
      if (found != null) widget.shell.setWalletName(found.id, found.name);
    } on WalletLoadException {
      if (!mounted) return;
      // Keep showing the wallet we already have. Only show an error if there is none.
      if (_wallet == null) setState(() => _walletStatus = _WalletStatus.error);
    }
  }

  Future<void> _recordExpense() async {
    final recorded = await showRecordExpenseDialog(
      context,
      wallets: widget.walletRepository,
      categories: widget.categoryRepository,
      operations: widget.operationRepository,
      initialWallet: _wallet,
      onAddWallet: () => context.go('/wallets'),
    );
    if (recorded == null || !mounted) return;
    // The balance and this month's totals changed.
    _loadWallet();
    _loadTransactions();
  }

  Future<void> _addCategory() async {
    final created = await showCreateCategoryDialog(
      context,
      repository: widget.categoryRepository,
    );
    if (created == true) {
      if (!mounted) return;
      showSuccessSnackBar(context, 'Category added.');
      _loadTransactions();
    }
  }

  void _retryWallet() {
    setState(() => _walletStatus = _WalletStatus.loading);
    _loadWallet();
  }

  bool _inShownMonth(Operation o) =>
      o.date.year == _month.year && o.date.month == _month.month;

  int _newestFirst(Operation a, Operation b) {
    final byDate = b.date.compareTo(a.date);
    return byDate != 0 ? byDate : b.id.compareTo(a.id);
  }

  Future<void> _loadTransactions() async {
    setState(() => _status = TransactionsStatus.loading);
    try {
      final results = await Future.wait<Object>([
        widget.operationRepository.getOperations(widget.walletId),
        widget.categoryRepository.getCategories(),
      ]);
      if (!mounted) return;

      final operations =
          (results[0] as List<Operation>).where(_inShownMonth).toList()
            ..sort(_newestFirst);
      final categories = results[1] as List<Category>;

      setState(() {
        _operations = operations;
        _categories = {for (final c in categories) c.id: c};
        _status = TransactionsStatus.loaded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = TransactionsStatus.error);
    }
  }

  double _total({required bool income}) => _operations
      .where((o) => o.isIncome == income)
      .fold(0.0, (sum, o) => sum + o.amount);

  void _comingSoon(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final wallet = _wallet;
    if (wallet == null) return PageBody(child: _walletPlaceholder());

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WalletSummaryCard(
            wallet: wallet,
            monthIncome: _total(income: true),
            monthExpenses: _total(income: false),
            onAddIncome: () => _comingSoon(AppStrings.recordFormComingSoon),
            onAddExpense: _recordExpense,
            onAddCategory: _addCategory,
          ),
          const SizedBox(height: 24),
          TransactionsPanel(
            status: _status,
            operations: _operations,
            categories: _categories,
            currency: wallet.currency,
            month: _month,
            onRetry: _loadTransactions,
          ),
        ],
      ),
    );
  }

  /// Shown while there is no wallet to display yet (opened by address, or not found).
  Widget _walletPlaceholder() {
    switch (_walletStatus) {
      case _WalletStatus.error:
        return StatePanel(
          icon: Icons.cloud_off_outlined,
          tileColor: AppColors.errorTile,
          iconColor: AppColors.errorIcon,
          title: AppStrings.errorTitle,
          message: AppStrings.errorMessage,
          buttonLabel: AppStrings.retry,
          buttonIcon: Icons.refresh,
          onPressed: _retryWallet,
        );
      case _WalletStatus.notFound:
        return StatePanel(
          icon: Icons.account_balance_wallet_outlined,
          tileColor: AppColors.iconTile,
          iconColor: AppColors.iconTileIcon,
          title: AppStrings.walletNotFound,
          message: AppStrings.walletNotFoundMessage,
          buttonLabel: AppStrings.backToWallets,
          buttonIcon: Icons.arrow_back,
          onPressed: () => context.go('/wallets'),
        );
      case _WalletStatus.loading:
      case _WalletStatus.ready:
        return const Padding(
          padding: EdgeInsets.only(top: 48),
          child: Row(
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
        );
    }
  }
}
