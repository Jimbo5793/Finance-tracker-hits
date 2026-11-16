import '../core/strings.dart';
import '../models/wallet.dart';

/// Checks done in the form before anything is sent. Each returns a message or null.
class OperationValidators {
  OperationValidators._();

  // digits, optionally "." and 1-2 digits. Rejects "abc", "-5", "10.123".
  static final _amountPattern = RegExp(r'^\d+(\.\d{1,2})?$');

  static String? wallet(Wallet? value) =>
      value == null ? AppStrings.errorWalletRequired : null;

  static String? amount(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return AppStrings.errorAmountRequired;
    if (!_amountPattern.hasMatch(text) || double.parse(text) <= 0) {
      return AppStrings.errorAmountInvalid; // also catches 0 and 0.00
    }
    return null;
  }
}
