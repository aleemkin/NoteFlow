import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';

/// Renders a transclusion preview of a referenced tagged block.
///
/// Displays the referenced block content inside a dashed-border container
/// with a provenance link showing the source document path.
class ViewBlockRenderer extends StatelessWidget {
  /// The mark ID being referenced.
  final String markRef;

  /// Optional document path for cross-document references.
  final String? docPath;

  /// The semantic mark type (e.g. 'imp', 'info', 'todo') if resolved.
  final String? markType;

  /// The resolved block content widgets to display inside the transclusion container.
  /// If null, an unresolved placeholder is shown.
  final Widget? resolvedContent;

  /// Callback when the provenance link is tapped.
  final VoidCallback? onNavigateToSource;

  const ViewBlockRenderer({
    super.key,
    required this.markRef,
    this.docPath,
    this.markType,
    this.resolvedContent,
    this.onNavigateToSource,
  });

  static Color _badgeColor(String type) => switch (type.toLowerCase()) {
    'imp' || 'important' => AppColors.markImportant,
    'info' => AppColors.markInfo,
    'todo' => AppColors.secondary,
    'review' => AppColors.accent,
    'question' => AppColors.markImportant,
    _ => AppColors.markTag,
  };

  @override
  Widget build(BuildContext context) {
    final accentColor = markType != null ? _badgeColor(markType!) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color:
                accentColor?.withValues(alpha: 0.35) ?? AppColors.borderSubtle,
          ),
          borderRadius: BorderRadius.circular(8.0),
          color: AppColors.surfaceCard.withValues(alpha: 0.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Provenance header
            InkWell(
              onTap: onNavigateToSource,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7.0),
                topRight: Radius.circular(7.0),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7.0),
                    topRight: Radius.circular(7.0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      size: 13,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        docPath != null ? '$docPath#$markRef' : '#$markRef',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    if (markType != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        markType!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: accentColor,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (onNavigateToSource != null)
                      const Tooltip(
                        message: 'Jump to original tagged block',
                        child: Icon(
                          Icons.open_in_new,
                          size: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Content area
            if (resolvedContent != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14.0, 8.0, 14.0, 12.0),
                child: resolvedContent!,
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14.0, 12.0, 14.0, 12.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Referenced mark #$markRef not found',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
