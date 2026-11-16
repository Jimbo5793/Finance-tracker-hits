import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../data/category_repository.dart';
import '../utils/category_validators.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/form_fields.dart';

/// Completes with true when a category was created.
/// Pass initialKind: 'income' when opened from the Income section.
Future<bool?> showCreateCategoryDialog(
  BuildContext context, {
  required CategoryRepository repository,
  String initialKind = 'expense',
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: AppColors.scrim,
    barrierDismissible: false,
    builder: (_) =>
        CreateCategoryDialog(repository: repository, initialKind: initialKind),
  );
}

class CreateCategoryDialog extends StatefulWidget {
  final CategoryRepository repository;
  final String initialKind;
  const CreateCategoryDialog({
    super.key,
    required this.repository,
    this.initialKind = 'expense',
  });

  @override
  State<CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<CreateCategoryDialog> {
  final _name = TextEditingController();
  String? _icon;
  late String _kind = widget.initialKind;
  bool _mandatory = false;

  String? _nameError;
  String? _iconError;
  bool _saving = false;
  bool _saveFailed = false;

  bool get _isExpense => _kind == 'expense';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return; // blocks double clicks
    final nameError = validateCategoryName(_name.text);
    final iconError = validateCategoryIcon(_icon);
    if (nameError != null || iconError != null) {
      setState(() {
        _nameError = nameError;
        _iconError = iconError;
        _saveFailed = false;
      });
      return; // no request
    }

    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await widget.repository.createCategory(
        name: _name.text.trim(),
        icon: _icon!,
        kind: _kind,
        mandatory: _isExpense ? _mandatory : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CreateCategoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _nameError = e.fieldErrors['name']?.first;
        _iconError = e.fieldErrors['icon']?.first;
        _saveFailed = e.fieldErrors.isEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 16),
                _body(),
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
      children: [
        const Expanded(
          child: Text(
            AppStrings.createCategoryTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          icon: const Icon(
            Icons.close,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _body() {
    final picker = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EmojiPicker(
          selected: _icon,
          hasError: _iconError != null,
          enabled: !_saving,
          onSelected: (e) => setState(() {
            _icon = e;
            _iconError = null;
            _saveFailed = false;
          }),
        ),
        if (_iconError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _iconError!,
              style: const TextStyle(fontSize: 12, color: AppColors.errorText),
            ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= 520) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              picker,
              const SizedBox(width: 28),
              Expanded(child: _fields()),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [picker, const SizedBox(height: 20), _fields()],
        );
      },
    );
  }

  Widget _fields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldBlock(
          label: AppStrings.fieldCategoryName,
          errorText: _nameError,
          child: AppTextField(
            controller: _name,
            hint: AppStrings.hintCategoryName,
            hasError: _nameError != null,
            enabled: !_saving,
            onChanged: (_) {
              if (_nameError != null || _saveFailed) {
                setState(() {
                  _nameError = null;
                  _saveFailed = false;
                });
              }
            },
            onSubmitted: (_) => _save(),
          ),
        ),
        const SizedBox(height: 18),
        FormFieldBlock(
          label: AppStrings.fieldCategoryKind,
          child: _KindToggle(
            kind: _kind,
            enabled: !_saving,
            onChanged: (k) => setState(() {
              _kind = k;
              _saveFailed = false;
            }),
          ),
        ),
        // Only expense categories can be mandatory.
        if (_isExpense) ...[
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _saving
                ? null
                : () => setState(() => _mandatory = !_mandatory),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _mandatory,
                    activeColor: AppColors.primary,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _mandatory = v ?? false),
                  ),
                  const Text(
                    AppStrings.markExpenseMandatory,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _footer() {
    return Row(
      children: [
        Expanded(
          child: _saveFailed
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorBannerBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.errorBorder),
                  ),
                  child: const Text(
                    AppStrings.saveFailed,
                    style: TextStyle(fontSize: 13, color: AppColors.errorText),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            backgroundColor: AppColors.segmentedBackground,
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(96, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(AppStrings.cancel),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.buttonDisabled,
            disabledForegroundColor: AppColors.buttonDisabledText,
            minimumSize: const Size(96, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            _saving
                ? AppStrings.saving
                : (_saveFailed ? AppStrings.tryAgain : AppStrings.save),
          ),
        ),
      ],
    );
  }
}

/// Expense / Income pills, styled like the All / Income / Expenses filter.
class _KindToggle extends StatelessWidget {
  final String kind;
  final bool enabled;
  final ValueChanged<String> onChanged;
  const _KindToggle({
    required this.kind,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.segmentedBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _segment('expense', AppStrings.kindExpense),
          _segment('income', AppStrings.kindIncome),
        ],
      ),
    );
  }

  Widget _segment(String value, String label) {
    final selected = kind == value;
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? () => onChanged(value) : null,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : null,
            borderRadius: BorderRadius.circular(8),
            border: selected ? Border.all(color: AppColors.border) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
