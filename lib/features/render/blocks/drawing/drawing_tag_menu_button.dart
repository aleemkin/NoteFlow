import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';

/// Tagging popup menu button positioned over a drawing block.
class DrawingTagMenuButton extends StatelessWidget {
  final void Function(String tagType)? onTag;

  const DrawingTagMenuButton({super.key, this.onTag});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(cardColor: AppColors.surfaceElevated),
      child: PopupMenuButton<String>(
        tooltip: 'Tag Diagram',
        icon: const Icon(
          Icons.label_outline,
          size: 15,
          color: AppColors.textPrimary,
        ),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceElevated,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.all(6),
          minimumSize: const Size(28, 28),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        onSelected: onTag,
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'imp',
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: AppColors.markImportant,
                ),
                SizedBox(width: 8),
                Text('Important (@@imp)'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'info',
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.markInfo),
                SizedBox(width: 8),
                Text('Info Reference (@@info)'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'todo',
            child: Row(
              children: [
                Icon(
                  Icons.check_box_outlined,
                  size: 16,
                  color: AppColors.secondary,
                ),
                SizedBox(width: 8),
                Text('To-Do Task (@@todo)'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'review',
            child: Row(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 16,
                  color: AppColors.accent,
                ),
                SizedBox(width: 8),
                Text('Review (@@review)'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: '__remove__',
            child: Row(
              children: [
                Icon(
                  Icons.label_off_outlined,
                  size: 16,
                  color: AppColors.markDanger,
                ),
                SizedBox(width: 8),
                Text('Remove Tag'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
