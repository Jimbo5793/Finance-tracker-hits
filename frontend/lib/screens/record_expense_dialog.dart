import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../data/category_repository.dart';
import '../data/operation_repository.dart';
import '../data/wallet_repository.dart';
import '../models/category.dart';
import '../models/operation.dart';
import '../models/wallet.dart';
import '../utils/money.dart';
import '../utils/operation_validators.dart';
import '../widgets/emoji_icon.dart';
import '../widgets/form_dialog.dart';
import '../widgets/form_fields.dart';
import '../widgets/primary_button.dart';
import '../widgets/success_snack_bar.dart';
import '../widgets/wallet_card.dart';

/// Opens the record expense form. Completes with the new operation, or null if cancelled.
/// [initialWallet] is preselected. [onAddWallet] runs after the form closes when
/// the user has no wallets and presses "Add wallet".
Future<Operation?> showRecordExpenseDialog(
  BuildContext context, {
  required WalletRepository wallets,
  required CategoryRepository categories,
  required OperationRepository operations,
  Wallet? initialWallet,
  VoidCallback? onAddWallet,
}) {
  return showDialog<Operation>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.scrim,
    builder: (_) => RecordExpenseDialog(
      wallets: wallets,
      categories: categories,
      operations: operations,
      initialWallet: initialWallet,
      onAddWallet: onAddWallet,
    ),
  );
}

enum _Stage { loading, loadFailed, noWallets, form }

class RecordExpenseDialog extends StatefulWidget {
  final WalletRepository wallets;
  final CategoryRepository categories;
  final OperationRepository operations;
  final Wallet? initialWallet;
  final VoidCallback? onAddWallet;

  const RecordExpenseDialog({
    super.key,
    required this.wallets,
    required this.categories,
    required this.operations,
    this.initialWallet,
    this.onAddWallet,
  });

  @override
  State<RecordExpenseDialog> createState() => _RecordExpenseDialogState();
}

class _RecordExpenseDialogState extends State<RecordExpenseDialog> {
  /// First entry of the category list. Means "send no category".
  static const _noCategory = Category(
    id: -1,
    name: AppStrings.noCategory,
    icon: '',
    kind: 'expense',
  );

  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  _Stage _stage = _Stage.loading;
  List<Wallet> _wallets = const [];
  List<Category> _categories = const [];
  bool _categoriesFailed = false;

  Wallet? _wallet;
  Category _category = _noCategory;

  // The backend only accepts days of the current month in UTC, so the picker follows UTC too.
  late final DateTime _firstDay;
  late final DateTime _lastDay;
  late DateTime _date;

  String? _walletError;
  String? _amountError;
  String? _dateError;
  String? _categoryError;
  String? _commentError;

  bool _saving = false;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _firstDay = DateTime(now.year, now.month, 1);
    _lastDay = DateTime(now.year, now.month + 1, 0);
    _date = DateTime(now.year, now.month, now.day); // today
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<List<Category>> _fetchCategories() async {
    try {
      return await widget.categories.getCategories(kind: 'expense');
    } on CategoryLoadException {
      // The category is optional, so this must not block the form.
      _categoriesFailed = true;
      return const [];
    }
  }

  Future<void> _load() async {
    setState(() {
      _stage = _Stage.loading;
      _categoriesFailed = false;
    });
    try {
      final results = await Future.wait<Object>([
        widget.wallets.getWallets(),
        _fetchCategories(),
      ]);
      if (!mounted) return;

      final wallets = results[0] as List<Wallet>;
      setState(() {
        _wallets = wallets;
        _categories = results[1] as List<Category>;
        // Preselect only when opened from a wallet. Otherwise the user must choose.
        _wallet = wallets
            .where((w) => w.id == widget.initialWallet?.id)
            .firstOrNull;
        _stage = wallets.isEmpty ? _Stage.noWallets : _Stage.form;
      });
    } on WalletLoadException {
      if (!mounted) return;
      setState(() => _stage = _Stage.loadFailed);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _firstDay, // days of other months cannot be picked
      lastDate: _lastDay,
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
      _dateError = null;
    });
  }

  Future<void> _submit() async {
    if (_saving) return; // a second click while the request runs does nothing

    final walletError = OperationValidators.wallet(_wallet);
    final amountError = OperationValidators.amount(_amountController.text);

    setState(() {
      _saveFailed = false;
      _walletError = walletError;
      _amountError = amountError;
      _dateError = null;
      _categoryError = null;
      _commentError = null;
    });

    // Nothing is sent while the form has errors.
    if (walletError != null || amountError != null) return;

    setState(() => _saving = true);

    final wallet = _wallet!;
    final comment = _commentController.text.trim();
    try {
      final operation = await widget.operations.createOperation(
        walletId: wallet.id,
        amount: double.parse(_amountController.text.trim()),
        date: DateFormat('yyyy-MM-dd').format(_date),
        categoryId: _category.id == _noCategory.id ? null : _category.id,
        comment: comment.isEmpty ? null : comment,
      );
      if (!mounted) return;
      showSuccessSnackBar(
        context,
        AppStrings.expenseRecorded(
          '${formatBalance(operation.amount)} ${wallet.currency}',
          wallet.name,
        ),
      );
      Navigator.of(context).pop<Operation>(operation);
    } on CreateOperationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _applyBackendErrors(e);
      });
    }
  }

  /// Each backend error goes under its own field. Anything else (no connection,
  /// server error) becomes the general "Could not save" banner. Typed values stay.
  void _applyBackendErrors(CreateOperationException e) {
    final errors = e.fieldErrors;
    _walletError = errors['walletid']?.firstOrNull;
    _amountError = errors['amount']?.firstOrNull;
    _dateError = errors['date']?.firstOrNull;
    _categoryError = errors['categoryid']?.firstOrNull;
    _commentError = errors['comment']?.firstOrNull;
    _saveFailed =
        _walletError == null &&
        _amountError == null &&
        _dateError == null &&
        _categoryError == null &&
        _commentError == null;
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.loading:
        return _frame([
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
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
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]);

      case _Stage.loadFailed:
        return _frame([
          _centered(
            title: AppStrings.errorTitle,
            message: AppStrings.errorMessage,
            button: PrimaryButton(
              label: AppStrings.retry,
              icon: Icons.refresh,
              onPressed: _load,
            ),
          ),
        ]);

      case _Stage.noWallets:
        return _frame([
          _centered(
            title: AppStrings.emptyTitle,
            message: AppStrings.noWalletsForExpense,
            button: PrimaryButton(
              label: AppStrings.addWallet,
              icon: Icons.add,
              onPressed: () {
                Navigator.of(context).pop();
                widget.onAddWallet?.call();
              },
            ),
          ),
        ]);

      case _Stage.form:
        return _form();
    }
  }

  /// Dialog without the Save footer (loading and no wallets states).
  Widget _frame(List<Widget> children) => FormDialog(
    title: AppStrings.recordExpense,
    subtitle: AppStrings.recordExpenseSubtitle,
    onClose: _close,
    children: children,
  );

  Widget _centered({
    required String title,
    required String message,
    required Widget button,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            button,
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return FormDialog(
      title: AppStrings.recordExpense,
      subtitle: AppStrings.recordExpenseSubtitle,
      onClose: _close,
      onSubmit: _submit,
      saving: _saving,
      saveFailed: _saveFailed,
      children: [
        // 1. Wallet
        FormFieldBlock(
          label: AppStrings.fieldWallet,
          errorText: _walletError,
          child: AppDropdownField<Wallet>(
            value: _wallet,
            options: _wallets,
            hint: AppStrings.hintWallet,
            hasError: _walletError != null,
            labelOf: (w) => w.name,
            optionBuilder: (w) => Row(
              children: [
                Icon(
                  WalletCard.typeIcon(w.type),
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 12),
                Flexible(child: Text(w.name, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 10),
                Text(
                  w.currency,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            onChanged: _saving
                ? null
                : (w) => setState(() {
                    _wallet = w;
                    _walletError = null;
                  }),
          ),
        ),
        const SizedBox(height: 20),

        // 2. Amount
        FormFieldBlock(
          label: AppStrings.fieldAmount,
          errorText: _amountError,
          helperText: AppStrings.helperAmount,
          child: AppTextField(
            controller: _amountController,
            hint: AppStrings.hintAmount,
            hasError: _amountError != null,
            enabled: !_saving,
            suffixText: _wallet?.currency,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              if (_amountError != null) setState(() => _amountError = null);
            },
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: 20),

        // 3. Date (today by default)
        FormFieldBlock(
          label: AppStrings.fieldDate,
          errorText: _dateError,
          helperText: AppStrings.helperDate,
          child: AppDateField(
            value: _date,
            hasError: _dateError != null,
            onTap: _saving ? null : _pickDate,
          ),
        ),
        const SizedBox(height: 20),

        // 4. Category (optional)
        FormFieldBlock(
          label: AppStrings.fieldCategory,
          errorText: _categoryError,
          helperText: _categoriesFailed ? AppStrings.categoriesFailed : null,
          child: AppDropdownField<Category>(
            value: _category,
            options: [_noCategory, ..._categories],
            hint: AppStrings.noCategory,
            hasError: _categoryError != null,
            labelOf: (c) => c.name,
            optionBuilder: (c) => Row(
              children: [
                if (c.id != _noCategory.id) ...[
                  EmojiIcon(emoji: c.icon, size: 18),
                  const SizedBox(width: 12),
                ],
                Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
            onChanged: _saving
                ? null
                : (c) => setState(() {
                    _category = c ?? _noCategory;
                    _categoryError = null;
                  }),
          ),
        ),
        const SizedBox(height: 20),

        // 5. Comment (optional)
        FormFieldBlock(
          label: AppStrings.fieldComment,
          errorText: _commentError,
          child: AppTextField(
            controller: _commentController,
            hint: AppStrings.hintComment,
            hasError: _commentError != null,
            enabled: !_saving,
            onChanged: (_) {
              if (_commentError != null) setState(() => _commentError = null);
            },
          ),
        ),
      ],
    );
  }
}
