import 'package:flutter/material.dart';
import 'package:noteflow/core/platform/app_platform.dart';
import 'package:noteflow/core/theme/app_theme.dart';

/// Top AppBar for the drawing editor with title, unsaved indicator, and save/close actions.
class DrawingEditorAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String fileName;
  final bool isDirty;
  final VoidCallback? onClose;
  final VoidCallback onSave;

  const DrawingEditorAppBar({
    super.key,
    required this.fileName,
    required this.isDirty,
    this.onClose,
    required this.onSave,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceNavbar,
      elevation: 0,
      leading: onClose != null
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
              tooltip: 'Back to notes',
              onPressed: onClose,
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.draw_rounded, size: 18, color: Color(0xFFEC4899)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fileName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isDirty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.markImportant.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.markImportant.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'UNSAVED',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.markImportant,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save_outlined, size: 16),
          label: const Text('Save'),
          style: FilledButton.styleFrom(
            backgroundColor: isDirty
                ? AppColors.secondary
                : AppColors.surfaceCard,
            foregroundColor: isDirty ? Colors.black : AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 32),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onClose != null && AppPlatform.isDesktop) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Close drawing',
            onPressed: onClose,
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }
}
