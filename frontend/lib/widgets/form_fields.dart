import 'package:flutter/material.dart';

import '../core/colors.dart';

const double _fieldHeight = 46;

OutlineInputBorder _border(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );

/// Label above, field in the middle, error message and helper text below.
/// (Flutter's own errorText replaces the helper, the design shows both.)
class FormFieldBlock extends StatelessWidget {
  final String label;
  final Widget child;
  final String? errorText;
  final String? helperText;

  const FormFieldBlock({
    super.key,
    required this.label,
    required this.child,
    this.errorText,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorText!,
              style: const TextStyle(fontSize: 13, color: AppColors.errorText),
            ),
          ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              helperText!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool hasError;
  final bool enabled;

  /// Small grey text on the right side, e.g. the currency code.
  final String? suffixText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.hasError = false,
    this.enabled = true,
    this.suffixText,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
  });

  Widget? _suffix() {
    final children = <Widget>[
      if (suffixText != null)
        Text(
          suffixText!,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      if (suffixText != null && hasError) const SizedBox(width: 10),
      if (hasError)
        const Icon(Icons.error_outline, size: 18, color: AppColors.errorText),
    ];
    if (children.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idleBorder = hasError ? AppColors.errorBorder : AppColors.fieldBorder;
    return SizedBox(
      height: _fieldHeight,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        cursorColor: AppColors.primary,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.hint),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          suffixIcon: _suffix(),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          border: _border(idleBorder),
          enabledBorder: _border(idleBorder),
          disabledBorder: _border(idleBorder),
          focusedBorder: _border(
            hasError ? AppColors.errorBorder : AppColors.fieldBorderFocused,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Dropdown styled like the design. Pass [onChanged] as null to disable it.
class AppDropdownField<T> extends StatelessWidget {
  final T? value;
  final List<T> options;
  final String hint;

  /// Text shown in the closed field.
  final String Function(T) labelOf;

  /// Row shown in the open menu (icon + text).
  final Widget Function(T) optionBuilder;
  final ValueChanged<T?>? onChanged;
  final bool hasError;

  /// Called when the field is tapped while there are no options (e.g. to retry loading).
  final VoidCallback? onEmptyTap;

  const AppDropdownField({
    super.key,
    required this.value,
    required this.options,
    required this.hint,
    required this.labelOf,
    required this.optionBuilder,
    required this.onChanged,
    this.hasError = false,
    this.onEmptyTap,
  });

  @override
  Widget build(BuildContext context) {
    const valueStyle = TextStyle(fontSize: 14, color: AppColors.textPrimary);

    final field = Container(
      height: _fieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasError ? AppColors.errorBorder : AppColors.fieldBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: valueStyle,
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          menuMaxHeight: 320,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 14, color: AppColors.hint),
          ),
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasError) ...const [
                Icon(Icons.error_outline, size: 18, color: AppColors.errorText),
                SizedBox(width: 8),
              ],
              const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          selectedItemBuilder: (_) => [
            for (final o in options)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(labelOf(o), style: valueStyle),
              ),
          ],
          items: [
            for (final o in options)
              DropdownMenuItem<T>(value: o, child: optionBuilder(o)),
          ],
          onChanged: onChanged,
        ),
      ),
    );

    if (options.isEmpty && onEmptyTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onEmptyTap,
        child: IgnorePointer(child: field),
      );
    }
    return field;
  }
}
