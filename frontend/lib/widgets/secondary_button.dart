import 'package:flutter/material.dart';

import '../core/colors.dart';

/// White button with a border (Add Expense, Add Category).
class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onPressed;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    this.iconColor = AppColors.textPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: iconColor),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.fieldBorder),
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
