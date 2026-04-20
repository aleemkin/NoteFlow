import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'scroll_filter_mode.dart';

/// Top banner displayed when documents are filtered in the continuous folder surface.
class TaggedRollBanner extends StatelessWidget {
  final ScrollFilterMode filterMode;
  final String? activeTagFilter;
  final int totalMatchingBlocks;
  final int totalDocs;
  final double availableWidth;
  final VoidCallback? onCopyTaggedRoll;
  final VoidCallback? onExportTaggedRoll;
  final VoidCallback? onClearFilter;

  const TaggedRollBanner({
    super.key,
    required this.filterMode,
    this.activeTagFilter,
    required this.totalMatchingBlocks,
    required this.totalDocs,
    this.availableWidth = 800,
    this.onCopyTaggedRoll,
    this.onExportTaggedRoll,
    this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final (title, icon, color) = switch (filterMode) {
      ScrollFilterMode.importantOnly => (
        'Key Highlights',
        Icons.star_rounded,
        AppColors.markImportant,
      ),
      ScrollFilterMode.infoOnly => (
        'Reference Notes',
        Icons.bookmark_outline,
        AppColors.markInfo,
      ),
      ScrollFilterMode.diagramsOnly => (
        'Diagrams & Visuals',
        Icons.draw_outlined,
        AppColors.markDiagram,
      ),
      ScrollFilterMode.customTag => (
        '${(activeTagFilter ?? "Tag")} Notes',
        Icons.tag,
        AppColors.markTag,
      ),
      ScrollFilterMode.all => (
        'All Notes',
        Icons.auto_stories,
        AppColors.textPrimary,
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 3.5, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Fixed syntax error here
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(icon, size: 15, color: color),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSidebar,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          '$totalMatchingBlocks block${totalMatchingBlocks == 1 ? "" : "s"} in $totalDocs note${totalDocs == 1 ? "" : "s"}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ), // Replaced Spacer() with a fixed gap
                      if (onCopyTaggedRoll != null)
                        OutlinedButton.icon(
                          onPressed: onCopyTaggedRoll,
                          icon: const Icon(Icons.copy, size: 13),
                          label: const Text('Copy Markdown'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surfaceSidebar,
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(
                              color: AppColors.borderDefault,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 30),
                            textStyle: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      if (onExportTaggedRoll != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: onExportTaggedRoll,
                          icon: const Icon(Icons.save_as_outlined, size: 13),
                          label: const Text('Export to Note'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surfaceSidebar,
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(
                              color: AppColors.borderDefault,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 30),
                            textStyle: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                      if (onClearFilter != null) ...[
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: onClearFilter,
                          icon: const Icon(Icons.close, size: 16),
                          tooltip: 'Clear filter',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          style: IconButton.styleFrom(
                            foregroundColor: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
