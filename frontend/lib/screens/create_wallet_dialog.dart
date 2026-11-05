import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../data/wallet_repository.dart';
import '../models/currency.dart';
import '../models/wallet.dart';
import '../models/wallet_type.dart';
import '../utils/wallet_validators.dart';
import '../widgets/form_fields.dart';
import '../widgets/wallet_card.dart';

/// Opens with showDialog<Wallet>. Pops the created wallet, or null on cancel.
class CreateWalletDialog extends StatefulWidget {
  final WalletRepository repository;
  const CreateWalletDialog({super.key, required this.repository});

  @override
  State<CreateWalletDialog> createState() => _CreateWalletDialogState();
}

class _CreateWalletDialogState extends State<CreateWalletDialog> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  String? _type;
  Currency? _currency;
  List<Currency>? _currencies;
  bool _currenciesFailed = false;

  String? _typeError;
  String? _nameError;
  String? _currencyError;
  String? _balanceError;

  bool _saving = false;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    try {
      final list = await widget.repository.getCurrencies();
      if (!mounted) return;
      setState(() {
        _currencies = list;
        _currenciesFailed = false;
      });
    } on CurrencyLoadException {
      if (!mounted) return;
      setState(() => _currenciesFailed = true);
    }
  }

  void _retryCurrencies() {
    setState(() => _currenciesFailed = false);
    _loadCurrencies();
  }

  Future<void> _submit() async {
    if (_saving) return; // a second click while the request runs does nothing

    final typeError = WalletValidators.type(_type);
    final nameError = WalletValidators.name(_nameController.text);
    final currencyError = WalletValidators.currency(_currency?.code);
    final balanceError = WalletValidators.balance(_balanceController.text);

    setState(() {
      _saveFailed = false;
      _typeError = typeError;
      _nameError = nameError;
      _currencyError = currencyError;
      _balanceError = balanceError;
    });

    // Nothing is sent while the form has errors.
    if (typeError != null ||
        nameError != null ||
        currencyError != null ||
        balanceError != null) {
      return;
    }

    setState(() => _saving = true);

    final name = _nameController.text.trim();
    try {
      final wallet = await widget.repository.createWallet(
        name: name.isEmpty ? null : name,
        type: _type!,
        currency: _currency!.code,
        startingBalance: double.parse(_balanceController.text.trim()),
      );
      if (!mounted) return;
      Navigator.of(context).pop<Wallet>(wallet);
    } on CreateWalletException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _applyBackendErrors(e);
      });
    }
  }

  /// Puts each backend error under its own field. Anything else (no connection,
  /// server error) becomes the general "Could not save" banner. Typed values stay.
  void _applyBackendErrors(CreateWalletException e) {
    final errors = e.fieldErrors;
    _typeError = errors['type']?.firstOrNull;
    _nameError = errors['name']?.firstOrNull;
    _currencyError = errors['currency']?.firstOrNull;
    _balanceError = errors['startingbalance']?.firstOrNull;
    _saveFailed =
        _typeError == null &&
        _nameError == null &&
        _currencyError == null &&
        _balanceError == null;
  }

  @override
  Widget build(BuildContext context) {
    final currencyHint = _currencies != null
        ? AppStrings.hintCurrency
        : (_currenciesFailed
              ? AppStrings.hintCurrenciesFailed
              : AppStrings.hintCurrenciesLoading);

    return PopScope(
      canPop: !_saving,
      child: Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 24),
                if (_saveFailed) ...[
                  _errorBanner(),
                  const SizedBox(height: 24),
                ],

                // 1. Type
                FormFieldBlock(
                  label: AppStrings.fieldType,
                  errorText: _typeError,
                  child: AppDropdownField<String>(
                    value: _type,
                    options: walletTypes,
                    hint: AppStrings.hintType,
                    hasError: _typeError != null,
                    labelOf: WalletCard.typeLabel,
                    optionBuilder: (t) => Row(
                      children: [
                        Icon(
                          WalletCard.typeIcon(t),
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 12),
                        Text(WalletCard.typeLabel(t)),
                      ],
                    ),
                    onChanged: _saving
                        ? null
                        : (v) => setState(() {
                            _type = v;
                            _typeError = null;
                          }),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Name
                FormFieldBlock(
                  label: AppStrings.fieldName,
                  errorText: _nameError,
                  helperText: _nameError != null
                      ? AppStrings.helperNameRules
                      : AppStrings.helperName,
                  child: AppTextField(
                    controller: _nameController,
                    hint: AppStrings.hintName,
                    hasError: _nameError != null,
                    enabled: !_saving,
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Currency
                FormFieldBlock(
                  label: AppStrings.fieldCurrency,
                  errorText: _currencyError,
                  child: AppDropdownField<Currency>(
                    value: _currency,
                    options: _currencies ?? const [],
                    hint: currencyHint,
                    hasError: _currencyError != null,
                    labelOf: (c) => c.code,
                    onEmptyTap: _currenciesFailed ? _retryCurrencies : null,
                    optionBuilder: (c) => Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            c.symbol,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          c.code,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            c.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onChanged: _saving
                        ? null
                        : (v) => setState(() {
                            _currency = v;
                            _currencyError = null;
                          }),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Starting balance
                FormFieldBlock(
                  label: AppStrings.fieldStartingBalance,
                  errorText: _balanceError,
                  helperText: AppStrings.helperBalance,
                  child: AppTextField(
                    controller: _balanceController,
                    hint: AppStrings.hintBalance,
                    hasError: _balanceError != null,
                    enabled: !_saving,
                    suffixText: _currency?.code,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) {
                      if (_balanceError != null) {
                        setState(() => _balanceError = null);
                      }
                    },
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 20),
                _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.createWalletTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                AppStrings.createWalletSubtitle,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 20),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.errorBannerBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: AppColors.errorText),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.saveFailed,
              style: TextStyle(fontSize: 14, color: AppColors.errorText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    const buttonShape = 8.0;
    final padding = const EdgeInsets.symmetric(horizontal: 22);
    const textStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    return Row(
      children: [
        Expanded(
          child: Text(
            _saving ? AppStrings.footerSaving : AppStrings.footerIdle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            backgroundColor: AppColors.surface,
            disabledBackgroundColor: AppColors.buttonDisabled,
            disabledForegroundColor: AppColors.buttonDisabledText,
            side: BorderSide(
              color: _saving ? AppColors.buttonDisabled : AppColors.fieldBorder,
            ),
            minimumSize: const Size(0, 46),
            padding: padding,
            textStyle: textStyle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonShape),
            ),
          ),
          child: const Text(AppStrings.cancel),
        ),
        const SizedBox(width: 10),
        // Disabled while saving, so a double click cannot create two wallets.
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.buttonDisabled,
            disabledForegroundColor: AppColors.buttonDisabledText,
            minimumSize: const Size(0, 46),
            padding: padding,
            textStyle: textStyle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonShape),
            ),
          ),
          child: _saving
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.buttonDisabledText,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(AppStrings.saving),
                  ],
                )
              : Text(_saveFailed ? AppStrings.tryAgain : AppStrings.save),
        ),
      ],
    );
  }
}
