import 'package:noteflow/features/document/domain/models.dart';
import 'scroll_filter_mode.dart';

/// Pure domain filter for notebook documents rendered in a continuous roll.
class DocumentRollFilter {
  DocumentRollFilter._();

  /// Filters documents and their blocks according to the given [filterMode] and optional [activeTagFilter].
  static List<NotebookDocument> filter({
    required List<NotebookDocument> documents,
    required ScrollFilterMode filterMode,
    String? activeTagFilter,
  }) {
    if (filterMode == ScrollFilterMode.all) return documents;

    final result = <NotebookDocument>[];
    for (final doc in documents) {
      final matchingBlocks = doc.blocks.where((b) {
        if (filterMode == ScrollFilterMode.importantOnly) {
          return b.marks.any((m) => m.type == 'imp');
        }
        if (filterMode == ScrollFilterMode.infoOnly) {
          return b.marks.any((m) => m.type == 'info');
        }
        if (filterMode == ScrollFilterMode.customTag &&
            activeTagFilter != null) {
          return b.marks.any(
            (m) => m.type.toLowerCase() == activeTagFilter.toLowerCase(),
          );
        }
        if (filterMode == ScrollFilterMode.diagramsOnly) {
          return b is DrawingBlock;
        }
        return true;
      }).toList();

      if (matchingBlocks.isNotEmpty) {
        result.add(doc.copyWith(blocks: matchingBlocks));
      }
    }
    return result;
  }
}
