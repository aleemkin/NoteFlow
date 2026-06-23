import 'package:noteflow/core/utils/typedefs.dart';

/// Result of parsing YAML frontmatter metadata from a document.
final class FrontmatterResult {
  /// Unique document identifier extracted from frontmatter, if present.
  final DocumentId? documentId;

  /// Schema version integer, if present.
  final int? schemaVersion;

  /// Character offset where markdown body content starts (after closing delimiter).
  final int contentStartOffset;

  /// Zero-indexed line number where markdown body content begins.
  final int contentStartLine;

  /// Creates a [FrontmatterResult] instance.
  const FrontmatterResult({
    this.documentId,
    this.schemaVersion,
    required this.contentStartOffset,
    required this.contentStartLine,
  });
}

/// Parses the `kn:` frontmatter metadata block from document text.
///
/// Looks for:
/// ```markdown
/// ---
/// kn:
///   id: doc_xxx
///   schema: 1
/// ---
/// ```
class FrontmatterParser {
  const FrontmatterParser._();

  /// Parses YAML frontmatter from [text], returning metadata and body start offset.
  static FrontmatterResult parse(String text) {
    if (!text.startsWith('---')) {
      return const FrontmatterResult(
        contentStartOffset: 0,
        contentStartLine: 0,
      );
    }

    // Find the closing ---
    final closeIndex = text.indexOf('\n---', 3);
    if (closeIndex == -1) {
      return const FrontmatterResult(
        contentStartOffset: 0,
        contentStartLine: 0,
      );
    }

    final frontmatter = text.substring(3, closeIndex).trim();
    final contentStart = closeIndex + 4; // skip \n---
    // Skip the newline after closing ---
    final actualStart = contentStart < text.length && text[contentStart] == '\n'
        ? contentStart + 1
        : contentStart;

    // Count lines up to actualStart
    var lineCount = 0;
    for (var i = 0; i < actualStart && i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x0A) lineCount++;
    }

    // Parse kn block
    DocumentId? docId;
    int? schema;

    final lines = frontmatter.split('\n');
    var inKnBlock = false;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed == 'kn:') {
        inKnBlock = true;
        continue;
      }
      if (inKnBlock) {
        if (!line.startsWith(' ') && !line.startsWith('\t')) {
          inKnBlock = false;
          continue;
        }
        final idMatch = RegExp(r'id:\s*(.+)').firstMatch(trimmed);
        if (idMatch != null) {
          docId = idMatch.group(1)!.trim();
        }
        final schemaMatch = RegExp(r'schema:\s*(\d+)').firstMatch(trimmed);
        if (schemaMatch != null) {
          schema = int.tryParse(schemaMatch.group(1)!);
        }
      }
    }

    return FrontmatterResult(
      documentId: docId,
      schemaVersion: schema,
      contentStartOffset: actualStart,
      contentStartLine: lineCount,
    );
  }

  /// Extracts the YAML frontmatter block including delimiters `---` if present,
  /// or returns an empty string if no frontmatter exists.
  static String extractFrontmatter(String text) {
    if (!text.startsWith('---')) return '';
    final firstNewline = text.indexOf('\n');
    if (firstNewline == -1) return '';
    final firstLine = text.substring(0, firstNewline).trim();
    if (firstLine != '---') return '';

    final closeIndex = text.indexOf('\n---', 3);
    if (closeIndex == -1) return '';

    final endOfClosingLine = text.indexOf('\n', closeIndex + 1);
    final closingLine =
        (endOfClosingLine == -1
                ? text.substring(closeIndex + 1)
                : text.substring(closeIndex + 1, endOfClosingLine))
            .trim();
    if (closingLine != '---') return '';

    final rawFm = endOfClosingLine == -1
        ? text.substring(0)
        : text.substring(0, endOfClosingLine);
    return rawFm.trim();
  }

  /// Extracts the markdown body content without the frontmatter block.
  static String extractBody(String text) {
    if (!text.startsWith('---')) return text;
    final firstNewline = text.indexOf('\n');
    if (firstNewline == -1) return text;
    final firstLine = text.substring(0, firstNewline).trim();
    if (firstLine != '---') return text;

    final closeIndex = text.indexOf('\n---', 3);
    if (closeIndex == -1) return text;

    final endOfClosingLine = text.indexOf('\n', closeIndex + 1);
    if (endOfClosingLine == -1) return '';

    final closingLine = text.substring(closeIndex + 1, endOfClosingLine).trim();
    if (closingLine != '---') return text;

    var bodyStart = endOfClosingLine + 1;
    if (bodyStart < text.length && text[bodyStart] == '\r') bodyStart++;
    if (bodyStart < text.length && text[bodyStart] == '\n') bodyStart++;

    return text.substring(bodyStart);
  }

  /// Combines a frontmatter block and markdown body content for persistence.
  static String combine(String frontmatter, String body) {
    final cleanFm = frontmatter.trim();
    if (cleanFm.isEmpty) return body;
    if (body.isEmpty) return '$cleanFm\n';
    return '$cleanFm\n\n$body';
  }
}
