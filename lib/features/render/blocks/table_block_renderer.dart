import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/domain/models.dart';

/// Renders a Markdown table with horizontal scrolling, dark styling, zebra rows, and aligned columns.
class TableBlockRenderer extends StatelessWidget {
  final TableBlock table;

  const TableBlockRenderer({super.key, required this.table});

  TextAlign _toTextAlign(int colIndex) {
    if (colIndex < table.alignments.length) {
      return switch (table.alignments[colIndex]) {
        TableColumnAlign.center => TextAlign.center,
        TableColumnAlign.right => TextAlign.right,
        TableColumnAlign.left => TextAlign.left,
      };
    }
    return TextAlign.left;
  }

  Alignment _toAlignment(int colIndex) {
    if (colIndex < table.alignments.length) {
      return switch (table.alignments[colIndex]) {
        TableColumnAlign.center => Alignment.center,
        TableColumnAlign.right => Alignment.centerRight,
        TableColumnAlign.left => Alignment.centerLeft,
      };
    }
    return Alignment.centerLeft;
  }

  @override
  Widget build(BuildContext context) {
    if (table.headers.isEmpty && table.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final columnCount = table.headers.isNotEmpty
        ? table.headers.length
        : (table.rows.isNotEmpty ? table.rows.first.length : 0);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: const TableBorder(
              horizontalInside: BorderSide(color: AppColors.borderSubtle),
              verticalInside: BorderSide(color: AppColors.borderSubtle),
            ),
            children: [
              if (table.headers.isNotEmpty)
                TableRow(
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceElevated,
                  ),
                  children: [
                    for (var col = 0; col < columnCount; col++)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        alignment: _toAlignment(col),
                        child: Text(
                          col < table.headers.length ? table.headers[col] : '',
                          textAlign: _toTextAlign(col),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              for (var rowIdx = 0; rowIdx < table.rows.length; rowIdx++)
                TableRow(
                  decoration: BoxDecoration(
                    color: rowIdx.isEven
                        ? Colors.transparent
                        : AppColors.surfaceElevated.withValues(alpha: 0.3),
                  ),
                  children: [
                    for (var col = 0; col < columnCount; col++)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        alignment: _toAlignment(col),
                        child: Text(
                          col < table.rows[rowIdx].length
                              ? table.rows[rowIdx][col]
                              : '',
                          textAlign: _toTextAlign(col),
                          style: const TextStyle(
                            fontSize: 14.0,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
      ),
    );
  }
}
