import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../data/emoji_catalog.dart';
import 'emoji_icon.dart';

/// Left panel of the category form: big preview of the chosen icon + the icon grid.
class EmojiPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;
  final bool hasError;
  final bool enabled;

  const EmojiPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.hasError = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.emojiPanelBackground,
        borderRadius: BorderRadius.circular(16),
        border: hasError ? Border.all(color: AppColors.errorBorder) : null,
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: selected == null
                ? const Icon(
                    Icons.add_reaction_outlined,
                    size: 26,
                    color: AppColors.textMuted,
                  )
                : EmojiIcon(emoji: selected!, size: 34),
          ),
          const SizedBox(height: 8),
          Text(
            selected == null ? AppStrings.iconSelect : AppStrings.iconSelected,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 170),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.emojiGridBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final option in emojiCatalog)
                    Tooltip(
                      message: option.label,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: enabled ? () => onSelected(option.emoji) : null,
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: option.emoji == selected
                                ? AppColors.surface
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: option.emoji == selected
                                ? Border.all(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: EmojiIcon(emoji: option.emoji, size: 22),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
