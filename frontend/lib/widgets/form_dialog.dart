import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/strings.dart';

/// Frame shared by the form dialogs: title, close button, optional error banner,
/// the fields, and (when [onSubmit] is given) the Cancel / Save footer.
class FormDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback onClose;

  /// Null hides the footer (used for the loading / no wallets states).
  final VoidCallback? onSubmit;
  final bool saving;
  final bool saveFailed;

  const FormDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.onClose,
    this.onSubmit,
    this.saving = false,
    this.saveFailed = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !saving,
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
                if (saveFailed) ...[_errorBanner(), const SizedBox(height: 24)],
                ...children,
                if (onSubmit != null) ...[
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 20),
                  _footer(),
                ],
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: saving ? null : onClose,
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
    const padding = EdgeInsets.symmetric(horizontal: 22);
    const textStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            saving ? AppStrings.footerSaving : AppStrings.footerIdle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: saving ? null : onClose,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            backgroundColor: AppColors.surface,
            disabledBackgroundColor: AppColors.buttonDisabled,
            disabledForegroundColor: AppColors.buttonDisabledText,
            side: BorderSide(
              color: saving ? AppColors.buttonDisabled : AppColors.fieldBorder,
            ),
            minimumSize: const Size(0, 46),
            padding: padding,
            textStyle: textStyle,
            shape: shape,
          ),
          child: const Text(AppStrings.cancel),
        ),
        const SizedBox(width: 10),
        // Disabled while saving, so a double click cannot send the request twice.
        FilledButton(
          onPressed: saving ? null : onSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.buttonDisabled,
            disabledForegroundColor: AppColors.buttonDisabledText,
            minimumSize: const Size(0, 46),
            padding: padding,
            textStyle: textStyle,
            shape: shape,
          ),
          child: saving
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
              : Text(saveFailed ? AppStrings.tryAgain : AppStrings.save),
        ),
      ],
    );
  }
}
