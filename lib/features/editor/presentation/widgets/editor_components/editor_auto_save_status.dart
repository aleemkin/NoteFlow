import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';

/// Status indicator for editor auto-save and syntax warnings.
class EditorAutoSaveStatus extends StatelessWidget {
  final String? saveError;
  final String? syntaxWarning;
  final bool isSaving;
  final bool isDirty;
  final bool isCompact;

  const EditorAutoSaveStatus({
    super.key,
    this.saveError,
    this.syntaxWarning,
    required this.isSaving,
    required this.isDirty,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    if (saveError != null) {
      return Tooltip(
        message: saveError!,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.markDanger.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.markDanger.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 13,
                color: AppColors.markDanger,
              ),
              const SizedBox(width: 4),
              Text(
                isCompact ? 'Error' : 'Save Failed',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.markDanger,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (syntaxWarning != null) {
      return Tooltip(
        message: syntaxWarning!,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.markImportant.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.markImportant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 13,
                color: AppColors.markImportant,
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isCompact ? 100 : 160),
                child: Text(
                  syntaxWarning!,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.markImportant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isSaving) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isCompact ? '' : 'Saving...',
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
        ],
      );
    }

    if (isDirty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text(
            isCompact ? '' : 'Editing...',
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 13,
          color: AppColors.markSuccess.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 4),
        Text(
          isCompact ? '' : 'Auto-saved',
          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
