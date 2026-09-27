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

  static const double appBarHeight = 38.0;

  @override
  Size get preferredSize => const Size.fromHeight(appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: appBarHeight,
      backgroundColor: AppColors.surfaceNavbar,
      elevation: 0,
      leadingWidth: onClose != null ? 36.0 : 0.0,
      leading: onClose != null
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 16,
              ),
              tooltip: 'Back to notes',
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onClose,
            )
          : null,
      titleSpacing: onClose != null ? 4.0 : 12.0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.draw_rounded, size: 14, color: Color(0xFFEC4899)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              fileName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isDirty) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.markImportant.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: AppColors.markImportant.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'UNSAVED',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.markImportant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save_outlined, size: 13),
          label: const Text('Save'),
          style: FilledButton.styleFrom(
            backgroundColor: isDirty
                ? AppColors.secondary
                : AppColors.surfaceCard,
            foregroundColor: isDirty ? Colors.black : AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            minimumSize: const Size(0, 26),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onClose != null && AppPlatform.isDesktop) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
              size: 16,
            ),
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Close drawing',
            onPressed: onClose,
          ),
        ],
        const SizedBox(width: 6),
      ],
    );
  }
}
