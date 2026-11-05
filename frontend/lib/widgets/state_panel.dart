import 'package:flutter/material.dart';

import '../core/colors.dart';
import 'primary_button.dart';

/// Big bordered panel used for the empty state and the error state.
class StatePanel extends StatelessWidget {
  final IconData icon;
  final Color tileColor;
  final Color iconColor;
  final String title;
  final String message;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onPressed;

  const StatePanel({
    super.key,
    required this.icon,
    required this.tileColor,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 470),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 30, color: iconColor),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
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
          const SizedBox(height: 22),
          PrimaryButton(
            label: buttonLabel,
            icon: buttonIcon,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
