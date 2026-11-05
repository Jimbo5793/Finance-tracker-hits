import '../core/strings.dart';

class WalletValidators {
  WalletValidators._();

  static const maxNameLength = 50;

  static final _balancePattern = RegExp(r'^\d+(\.\d{1,2})?$');

  static String? type(String? value) =>
      value == null ? AppStrings.errorTypeRequired : null;

  static String? currency(String? code) =>
      code == null ? AppStrings.errorCurrencyRequired : null;

  static String? name(String raw) {
    if (raw.isEmpty) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return AppStrings.errorNameSpaces;
    if (trimmed.length > maxNameLength) return AppStrings.errorNameTooLong;
    return null;
  }

  static String? balance(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return AppStrings.errorBalanceRequired;
    if (!_balancePattern.hasMatch(trimmed))
      return AppStrings.errorBalanceInvalid;
    return null;
  }
}
