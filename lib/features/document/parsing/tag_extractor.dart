import 'package:flutter/material.dart';
import 'package:noteflow/features/document/domain/models.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/features/render/surfaces/continuous_folder_surface.dart';

/// Represents an occurrence of a tagged/marked block in a document.
class TagOccurrence {
  /// The URI of the document containing this tagged occurrence.
  final VaultUri docUri;

  /// Human-readable title of the document.
  final String docTitle;

  /// Target block identifier.
  final String blockId;

  /// Short preview snippet of the tagged content.
  final String textSnippet;

  /// The underlying semantic mark annotation.
  final SemanticMark mark;

  /// Creates a [TagOccurrence] instance.
  const TagOccurrence({
    required this.docUri,
    required this.docTitle,
    required this.blockId,
    required this.textSnippet,
    required this.mark,
  });
}

/// Aggregated summary of a specific mark tag type across documents.
class TagSummary {
  /// Slug identifier (e.g. 'imp', 'info', 'review').
  final String slug;

  /// Human-readable display label.
  final String label;

  /// Accent color associated with this tag.
  final Color color;

  /// Total count of occurrences across documents.
  final int count;

  /// Detailed list of all occurrences.
  final List<TagOccurrence> occurrences;

  /// Creates a [TagSummary] instance.
  const TagSummary({
    required this.slug,
    required this.label,
    required this.color,
    required this.count,
    required this.occurrences,
  });
}

/// Utility for extracting, aggregating, and generating Markdown for tagged sections.
class TagExtractor {
  const TagExtractor._();

  /// Default color map for mark types (standard unified accent color).
  static Color colorForTag(
    String slug, [
    List<MarkDefinition> customDefs = const [],
  ]) {
    for (final def in customDefs) {
      if (def.slug.toLowerCase() == slug.toLowerCase()) return def.color;
    }
    return const Color(0xFF58A6FF);
  }

  /// Default human-readable label for a mark slug.
  static String labelForTag(
    String slug, [
    List<MarkDefinition> customDefs = const [],
  ]) {
    for (final def in customDefs) {
      if (def.slug.toLowerCase() == slug.toLowerCase()) return def.label;
    }
    return switch (slug.toLowerCase()) {
      'imp' => 'Important',
      'info' => 'Info Reference',
      'review' => 'Review',
      'todo' => 'To Do',
      'question' => 'Question',
      'summary' => 'Summary',
      _ => slug[0].toUpperCase() + (slug.length > 1 ? slug.substring(1) : ''),
    };
  }

  /// Extracts all tag summaries and occurrences across the provided documents.
  static List<TagSummary> extractTags(
    List<NotebookDocument> docs, {
    List<MarkDefinition> customDefinitions = const [],
  }) {
    final map = <String, List<TagOccurrence>>{};

    for (final doc in docs) {
      for (final block in doc.blocks) {
        for (final mark in block.marks) {
          final slug = mark.type.toLowerCase();
          final text = block is TextBlock ? block.inlineContent.plainText : '';
          final snippet = text.length > 80
              ? '${text.substring(0, 77)}...'
              : text;

          map
              .putIfAbsent(slug, () => [])
              .add(
                TagOccurrence(
                  docUri: doc.uri,
                  docTitle: doc.title,
                  blockId: block.id,
                  textSnippet: snippet,
                  mark: mark,
                ),
              );
        }
      }
    }

    final summaries = <TagSummary>[];
    for (final entry in map.entries) {
      final slug = entry.key;
      final occurrences = entry.value;
      summaries.add(
        TagSummary(
          slug: slug,
          label: labelForTag(slug, customDefinitions),
          color: colorForTag(slug, customDefinitions),
          count: occurrences.length,
          occurrences: occurrences,
        ),
      );
    }

    // Sort by frequency descending
    summaries.sort((a, b) => b.count.compareTo(a.count));
    return summaries;
  }

  /// Generates a synthesized Markdown document containing all blocks matching [filterMode].
  static String generateRollMarkdown({
    required List<NotebookDocument> docs,
    required ScrollFilterMode filterMode,
    String? activeTagFilter,
    String? folderName,
  }) {
    final buffer = StringBuffer();
    final tagTitle = switch (filterMode) {
      ScrollFilterMode.importantOnly => 'Key Highlights',
      ScrollFilterMode.infoOnly => 'Reference Notes',
      ScrollFilterMode.diagramsOnly => 'Diagrams & Visuals',
      ScrollFilterMode.customTag =>
        '${activeTagFilter != null && activeTagFilter.isNotEmpty ? activeTagFilter[0].toUpperCase() + activeTagFilter.substring(1) : "Tagged"} Notes',
      ScrollFilterMode.all => 'All Notes Summary',
    };

    final folderContext = folderName != null && folderName.isNotEmpty
        ? ' — $folderName'
        : '';
    buffer.writeln('# $tagTitle$folderContext');
    buffer.writeln();

    for (final doc in docs) {
      final matchingBlocks = doc.blocks.where((block) {
        if (filterMode == ScrollFilterMode.all) return true;
        if (filterMode == ScrollFilterMode.importantOnly) {
          return block.marks.any((m) => m.type.toLowerCase() == 'imp');
        }
        if (filterMode == ScrollFilterMode.infoOnly) {
          return block.marks.any((m) => m.type.toLowerCase() == 'info');
        }
        if (filterMode == ScrollFilterMode.diagramsOnly) {
          return block is DrawingBlock;
        }
        if (filterMode == ScrollFilterMode.customTag &&
            activeTagFilter != null) {
          return block.marks.any(
            (m) => m.type.toLowerCase() == activeTagFilter.toLowerCase(),
          );
        }
        return false;
      }).toList();

      if (matchingBlocks.isEmpty) continue;

      buffer.writeln('## 📄 ${doc.title} (`${doc.uri.path}`)');
      buffer.writeln();

      for (final block in matchingBlocks) {
        if (block is TextBlock) {
          if (block.marks.isNotEmpty) {
            for (final mark in block.marks) {
              buffer.writeln('@@${mark.type} #${mark.id}');
              buffer.writeln(block.inlineContent.plainText);
              buffer.writeln('@@/${mark.type}');
              buffer.writeln();
            }
          } else {
            buffer.writeln(block.inlineContent.plainText);
            buffer.writeln();
          }
        } else if (block is DrawingBlock) {
          buffer.writeln(
            '@@drawing ./${block.drawingUri.fileName} #${block.id}',
          );
          buffer.writeln('@@/drawing');
          buffer.writeln();
        }
      }

      buffer.writeln('---');
      buffer.writeln();
    }

    return buffer.toString();
  }
}
