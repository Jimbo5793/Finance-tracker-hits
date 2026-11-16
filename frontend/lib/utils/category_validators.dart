import '../core/strings.dart';

String? validateCategoryName(String value) {
  final name = value.trim();
  if (name.isEmpty) return AppStrings.errorCategoryNameEmpty;
  if (name.length > 30) return AppStrings.errorCategoryNameTooLong;
  return null;
}

String? validateCategoryIcon(String? icon) =>
    (icon == null || icon.isEmpty) ? AppStrings.errorCategoryIconEmpty : null;
