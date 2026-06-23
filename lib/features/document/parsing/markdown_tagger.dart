import 'package:noteflow/features/document/parsing/block_scanner.dart';

/// Represents a character span in source text.
class SourceSpan {
  final int start;
  final int end;

  const SourceSpan(this.start, this.end);

  @override
  String toString() => 'SourceSpan($start, $end)';
}

/// Represents a scanned directive block in markdown source.
class DirectiveSpan {
  final int start;
  final int end;
  final String tagType;
  final String? markId;
  final String rawContent;

  const DirectiveSpan({
    required this.start,
    required this.end,
    required this.tagType,
    this.markId,
    required this.rawContent,
  });
}

/// Robust atomic-level Markdown tagger that respects Markdown block grammar,
/// expands selections to atomic block boundaries (tables, code blocks, blockquotes, lists),
/// merges overlapping and consecutive same-tag directives into a single clean tag,
/// prevents nested directive corruption, and preserves block properties (headings, lists, code, tables).
class MarkdownTagger {
  const MarkdownTagger._();

  /// Strips directive markers from [text], returning clean markdown.
  ///
  /// - If [targetTagType] is provided, ONLY opening headers and closing markers for that
  ///   specific tag type are stripped. All other directives (including drawings and other tags)
  ///   are preserved intact as atomic units.
  /// - If [targetTagType] is null:
  ///   - When [preserveDrawings] is true, `@@drawing` blocks are kept intact.
  ///   - When [preserveDrawings] is false, all directive headers and closers are stripped.
  static String stripDirectives(
    String text, {
    bool preserveDrawings = false,
    String? targetTagType,
  }) {
    if (text.isEmpty) return text;

    final filterType = targetTagType?.trim().toLowerCase();
    final lines = text.split('\n');
    final outputLines = <String>[];
    final tagStack = <String>[];
    var inCodeBlock = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // Track fenced code blocks so directive markers inside code are never stripped
      if (trimmed.startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        outputLines.add(line);
        continue;
      }
      if (inCodeBlock) {
        outputLines.add(line);
        continue;
      }

      // Check single-line shorthand: @@tag> content
      final singleLineMatch = RegExp(
        r'^@@([a-zA-Z][\w-]*)>\s*(.*)$',
      ).firstMatch(trimmed);
      if (singleLineMatch != null) {
        final tag = singleLineMatch.group(1)!.toLowerCase();
        final rest = singleLineMatch.group(2)!;
        final shouldStrip = filterType != null
            ? (tag == filterType)
            : (tag != 'drawing' || !preserveDrawings);

        if (shouldStrip) {
          if (rest.isNotEmpty) outputLines.add(rest);
        } else {
          outputLines.add(line);
        }
        continue;
      }

      // Check directive opening header: @@tag [attrs]
      if (trimmed.startsWith('@@') &&
          trimmed.length > 2 &&
          RegExp(r'^@@[a-zA-Z][\w-]*').hasMatch(trimmed)) {
        final tagMatch = RegExp(r'^@@([a-zA-Z][\w-]*)').firstMatch(trimmed);
        final tag = tagMatch != null ? tagMatch.group(1)!.toLowerCase() : '';
        tagStack.add(tag);

        final shouldStrip = filterType != null
            ? (tag == filterType)
            : (tag != 'drawing' || !preserveDrawings);

        if (!shouldStrip) {
          outputLines.add(line);
        }
        continue;
      }

      // Check directive closer: @@/tag, @/tag, @@/, @/, @@
      final closerMatch = RegExp(
        r'^(?:@@/|@/)([a-zA-Z][\w-]*)(?:\s+.*)?$',
      ).firstMatch(trimmed);
      final isCloser =
          closerMatch != null ||
          trimmed == '@@' ||
          trimmed == '@@/' ||
          trimmed == '@/';
      if (isCloser) {
        if (tagStack.isNotEmpty) {
          final closerTag = closerMatch?.group(1)?.toLowerCase();
          String poppedTag;
          if (closerTag != null && tagStack.contains(closerTag)) {
            do {
              poppedTag = tagStack.removeLast();
            } while (tagStack.isNotEmpty && poppedTag != closerTag);
          } else {
            poppedTag = tagStack.removeLast();
          }

          final shouldStrip = filterType != null
              ? (poppedTag == filterType)
              : (poppedTag != 'drawing' || !preserveDrawings);

          if (!shouldStrip) {
            outputLines.add(line);
          }
        }
        continue;
      }

      outputLines.add(line);
    }

    return outputLines.join('\n').trim();
  }

  /// Scans all top-level directive spans in [source].
  static List<DirectiveSpan> findDirectives(String source) {
    final scannedBlocks = BlockScanner.scan(source);
    final spans = <DirectiveSpan>[];
    for (final block in scannedBlocks) {
      if (block.type == ScannedBlockType.markDirective ||
          block.type == ScannedBlockType.drawingDirective) {
        final tagType =
            block.attributes['markType'] ??
            (block.type == ScannedBlockType.drawingDirective ? 'drawing' : '');
        final markId = block.attributes['id'];
        final start = block.sourceRange.startOffset.clamp(0, source.length);
        final end = block.sourceRange.endOffset.clamp(0, source.length);
        spans.add(
          DirectiveSpan(
            start: start,
            end: end,
            tagType: tagType,
            markId: markId,
            rawContent: block.content,
          ),
        );
      }
    }
    return spans;
  }

  /// Merges any consecutive directives with the identical [tagType] that are adjacent
  /// (separated only by whitespace or blank lines) into a single cohesive directive block.
  static String mergeConsecutiveDirectives(String source) {
    var current = source;
    var changed = true;

    while (changed) {
      changed = false;
      final directives = findDirectives(current);

      for (var i = 0; i < directives.length - 1; i++) {
        final d1 = directives[i];
        final d2 = directives[i + 1];

        // Never merge drawings! Drawings are individual files with distinct paths.
        if (d1.tagType.toLowerCase() != 'drawing' &&
            d1.tagType.toLowerCase() == d2.tagType.toLowerCase()) {
          // Check if between d1.end and d2.start there is only whitespace / blank lines
          final inBetween = current.substring(d1.end, d2.start);
          if (inBetween.trim().isEmpty) {
            final content1 = stripDirectives(
              d1.rawContent,
              targetTagType: d1.tagType,
            );
            final content2 = stripDirectives(
              d2.rawContent,
              targetTagType: d2.tagType,
            );
            final combinedContent = '$content1\n\n$content2';

            final markId =
                d1.markId ?? 'mark_${DateTime.now().millisecondsSinceEpoch}';
            final mergedDirective =
                '@@${d1.tagType} #$markId\n$combinedContent\n@@/${d1.tagType}';

            current =
                current.substring(0, d1.start) +
                mergedDirective +
                current.substring(d2.end);
            changed = true;
            break; // Restart matching pass
          }
        }
      }
    }

    return current;
  }

  /// Locates the corresponding source span for [selectedText] in [source],
  /// tolerating markdown syntax, inline formatting, stripped directive markers,
  /// list bullets, and whitespace differences.
  static SourceSpan? findSourceSpan(String source, String selectedText) {
    if (source.isEmpty || selectedText.trim().isEmpty) return null;
    final clean = selectedText.trim();

    // 1. Direct exact match
    final exactIdx = source.indexOf(clean);
    if (exactIdx != -1) {
      return SourceSpan(exactIdx, exactIdx + clean.length);
    }

    // 2. Case-insensitive exact match
    final lowerIdx = source.toLowerCase().indexOf(clean.toLowerCase());
    if (lowerIdx != -1) {
      return SourceSpan(lowerIdx, lowerIdx + clean.length);
    }

    // 3. Token-based flexible regex matching
    final tokens = clean
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map((t) => t.replaceAll(RegExp(r'^[\W_]+|[\W_]+$'), ''))
        .where((t) => t.isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      final directFirst = source.indexOf(clean.split(RegExp(r'\s+')).first);
      if (directFirst != -1) {
        final endPos = (directFirst + clean.length).clamp(
          directFirst,
          source.length,
        );
        return SourceSpan(directFirst, endPos);
      }
      return null;
    }

    if (tokens.length == 1) {
      final token = tokens.first;
      final idx = source.indexOf(token);
      if (idx != -1) {
        return SourceSpan(idx, idx + token.length);
      }
      final lIdx = source.toLowerCase().indexOf(token.toLowerCase());
      if (lIdx != -1) {
        return SourceSpan(lIdx, lIdx + token.length);
      }
    } else {
      // Match tokens in sequence allowing any markdown formatting, punctuation, or tags in between
      final escapedTokens = tokens.map(RegExp.escape).toList();
      final patternStr = escapedTokens.join(
        r'(?:[^\w\s]|[\s\n]|@@[\s\S]*?(?:@@/[a-zA-Z][\w-]*|@/[a-zA-Z][\w-]*|@@)|@@[a-zA-Z][\w-]*[^\n]*|(?:@@/|@/)[a-zA-Z][\w-]*)+',
      );
      final regex = RegExp(patternStr, caseSensitive: false);
      final match = regex.firstMatch(source);
      if (match != null) {
        return SourceSpan(match.start, match.end);
      }

      // 4. Fallback: Boundary search using first & last token
      final firstToken = tokens.first;
      final lastToken = tokens.last;

      var searchPos = 0;
      while (searchPos < source.length) {
        final startIdx = source.toLowerCase().indexOf(
          firstToken.toLowerCase(),
          searchPos,
        );
        if (startIdx == -1) break;

        final afterStart = startIdx + firstToken.length;
        final endIdx = source.toLowerCase().indexOf(
          lastToken.toLowerCase(),
          afterStart,
        );
        if (endIdx != -1) {
          final spanEnd = endIdx + lastToken.length;
          final snippet = source.substring(startIdx, spanEnd).toLowerCase();

          // Check token density (at least 60% of tokens present in snippet)
          var count = 0;
          for (final t in tokens) {
            if (snippet.contains(t.toLowerCase())) count++;
          }
          if (count >= (tokens.length * 0.6).ceil()) {
            return SourceSpan(startIdx, spanEnd);
          }
        }
        searchPos = startIdx + 1;
      }
    }

    // 5. First line fallback
    final firstLine = clean.split('\n').first.trim();
    if (firstLine.isNotEmpty && firstLine != clean) {
      final firstLineSpan = findSourceSpan(source, firstLine);
      if (firstLineSpan != null) {
        return firstLineSpan;
      }
    }

    return null;
  }

  /// Expands a character range `[targetStart, targetEnd]` to strictly align with
  /// atomic Markdown block boundaries (preventing split tables, split code blocks,
  /// split blockquotes, or frontmatter contamination).
  ///
  /// When [tagType] is provided and the selection is completely enclosed inside the content
  /// of a different-type directive, it recursively expands within that inner directive so that
  /// individual blocks inside it can be tagged cleanly without forcibly expanding to the entire
  /// outer directive.
  static SourceSpan expandToAtomicBlockBoundaries(
    String source,
    int targetStart,
    int targetEnd, {
    String? tagType,
  }) {
    if (source.isEmpty) return const SourceSpan(0, 0);

    final normalizedTag = tagType?.trim().toLowerCase();
    final blocks = BlockScanner.scan(source);

    // If targetStart and targetEnd are completely inside a single markDirective's content
    // of a DIFFERENT tag type, recurse into its inner content.
    for (final b in blocks) {
      if (b.type == ScannedBlockType.markDirective) {
        final bTag = (b.attributes['markType'] ?? '').toLowerCase();
        if (normalizedTag == null || bTag != normalizedTag) {
          final firstNewline = source.indexOf('\n', b.sourceRange.startOffset);
          if (firstNewline != -1 && firstNewline < b.sourceRange.endOffset) {
            final contentStart = firstNewline + 1;
            final lastNewline = source.lastIndexOf(
              '\n',
              b.sourceRange.endOffset - 1,
            );
            final contentEnd = lastNewline != -1 && lastNewline > contentStart
                ? lastNewline
                : (source.lastIndexOf('@@', b.sourceRange.endOffset) != -1 &&
                          source.lastIndexOf('@@', b.sourceRange.endOffset) >
                              contentStart
                      ? source.lastIndexOf('@@', b.sourceRange.endOffset)
                      : b.sourceRange.endOffset);

            if (targetStart >= contentStart && targetEnd <= contentEnd) {
              final innerContent = source.substring(contentStart, contentEnd);
              final innerSpan = expandToAtomicBlockBoundaries(
                innerContent,
                targetStart - contentStart,
                targetEnd - contentStart,
                tagType: tagType,
              );
              return SourceSpan(
                contentStart + innerSpan.start,
                contentStart + innerSpan.end,
              );
            }
          }
        }
      }
    }

    // Find all content blocks (excluding pure blank blocks) that intersect [targetStart, targetEnd]
    final contentBlocks = blocks.where((b) {
      if (b.type == ScannedBlockType.blank) return false;
      final bStart = b.sourceRange.startOffset;
      final bEnd = b.sourceRange.endOffset;
      return bStart < targetEnd && bEnd > targetStart;
    }).toList();

    var expandedStart = targetStart;
    var expandedEnd = targetEnd;

    if (contentBlocks.isNotEmpty) {
      // If frontmatter is in the intersected blocks, do not include frontmatter in the tag
      final nonFrontmatterBlocks = contentBlocks
          .where((b) => b.type != ScannedBlockType.frontmatter)
          .toList();
      if (nonFrontmatterBlocks.isNotEmpty) {
        expandedStart = nonFrontmatterBlocks.first.sourceRange.startOffset;
        expandedEnd = nonFrontmatterBlocks.last.sourceRange.endOffset;
      } else {
        final fm = contentBlocks.first;
        expandedStart = fm.sourceRange.endOffset;
        expandedEnd = fm.sourceRange.endOffset;
      }
    } else {
      var lineStart = source.lastIndexOf(
        '\n',
        targetStart == 0 ? 0 : targetStart - 1,
      );
      expandedStart = lineStart == -1 ? 0 : lineStart + 1;
      var lineEnd = source.indexOf('\n', targetEnd);
      expandedEnd = lineEnd == -1 ? source.length : lineEnd;
    }

    // Also expand across any overlapping directive boundaries
    final directives = findDirectives(source);
    var expanded = true;
    while (expanded) {
      expanded = false;
      for (final d in directives) {
        if (d.start < expandedEnd && d.end > expandedStart) {
          if (d.start < expandedStart) {
            expandedStart = d.start;
            expanded = true;
          }
          if (d.end > expandedEnd) {
            expandedEnd = d.end;
            expanded = true;
          }
        }
      }
    }

    // Ensure we don't start inside or before frontmatter
    if (source.startsWith('---\n') || source.startsWith('---\r\n')) {
      final closeIdx = source.indexOf('\n---', 3);
      if (closeIdx != -1) {
        final fmEnd = closeIdx + 4;
        if (expandedStart < fmEnd) {
          expandedStart = fmEnd;
          while (expandedStart < source.length &&
              (source[expandedStart] == '\n' ||
                  source[expandedStart] == '\r')) {
            expandedStart++;
          }
          if (expandedEnd < expandedStart) {
            expandedEnd = expandedStart;
          }
        }
      }
    }

    return SourceSpan(
      expandedStart.clamp(0, source.length),
      expandedEnd.clamp(0, source.length),
    );
  }

  /// Tags the atomic markdown block in [source] containing [selectedText] with [tagType].
  ///
  /// Guarantees:
  /// 1. Expands selections to complete atomic block units (tables, code blocks, lists, blockquotes).
  /// 2. Treats any other tag directives (e.g. @@info, @@drawing) as opaque atomic units without
  ///    dismantling or splitting them.
  /// 3. Only strips and merges same-type tag directives to avoid redundant duplicate nesting of the same tag.
  /// 4. Merges consecutive same-type tag directives cleanly into a single tag.
  /// 5. Preserves frontmatter, drawings, and document structural integrity.
  static String tagText(String source, String selectedText, String tagType) {
    if (selectedText.trim().isEmpty) return source;

    final span = findSourceSpan(source, selectedText);
    if (span == null) return source;

    final atomicSpan = expandToAtomicBlockBoundaries(
      source,
      span.start,
      span.end,
      tagType: tagType,
    );
    final targetStart = atomicSpan.start;
    final targetEnd = atomicSpan.end;

    final targetSegment = source.substring(targetStart, targetEnd).trim();
    if (targetSegment.isEmpty) return source;

    // Strip only same-type directives from the target segment.
    // Different-type directives (like @@info, @@drawing, etc.) are treated as opaque atomic units.
    final cleanTarget = stripDirectives(targetSegment, targetTagType: tagType);
    if (cleanTarget.isEmpty) return source;

    final markId = 'mark_${DateTime.now().millisecondsSinceEpoch}';
    final replacement = '@@$tagType #$markId\n$cleanTarget\n@@/$tagType';

    final before = source.substring(0, targetStart).trimRight();
    final after = source.substring(targetEnd).trimLeft();

    final buffer = StringBuffer();
    if (before.isNotEmpty) {
      buffer.write(before);
      buffer.write('\n\n');
    }
    buffer.write(replacement);
    if (after.isNotEmpty) {
      buffer.write('\n\n');
      buffer.write(after);
    }

    return mergeConsecutiveDirectives(buffer.toString());
  }

  /// Removes semantic tag directive surrounding [selectedText] from [source].
  ///
  /// If [tagType] is provided, only directives matching [tagType] are removed.
  /// When a directive is removed, all other directives inside its content (such as nested
  /// tags of different types or drawings) are preserved intact as atomic units.
  static String removeTag(
    String source,
    String selectedText, {
    String? tagType,
  }) {
    if (selectedText.trim().isEmpty) return source;

    final span = findSourceSpan(source, selectedText);
    if (span == null) return source;

    final targetStart = span.start;
    final targetEnd = span.end;

    // Find all overlapping directives
    final directives = findDirectives(source);
    final targetFilter = tagType?.trim().toLowerCase();

    final overlapping = directives.where((d) {
      if (d.tagType.toLowerCase() == 'drawing') {
        return false;
      }
      if (targetFilter != null && d.tagType.toLowerCase() != targetFilter) {
        return false;
      }
      return d.start < targetEnd && d.end > targetStart;
    }).toList();

    if (overlapping.isNotEmpty) {
      var result = source;
      // Process in reverse order so character offsets remain valid
      for (final d in overlapping.reversed) {
        // Strip only the directive matching d.tagType, preserving any nested directives inside it
        final innerClean = stripDirectives(
          d.rawContent,
          targetTagType: d.tagType,
        );
        result =
            result.substring(0, d.start) + innerClean + result.substring(d.end);
      }
      return mergeConsecutiveDirectives(result);
    }

    // Fallback regex replacement
    final cleanInner = stripDirectives(selectedText, targetTagType: tagType);
    final tagPattern = targetFilter != null
        ? RegExp.escape(targetFilter)
        : r'[a-zA-Z][\w-]*';
    final pattern = RegExp(
      '@@$tagPattern[^\n]*\r?\n?${RegExp.escape(cleanInner)}\\s*\r?\n?(?:@@/$tagPattern|@/$tagPattern|@@/|@/|@@)',
    );
    if (pattern.hasMatch(source)) {
      return mergeConsecutiveDirectives(
        source.replaceFirst(pattern, cleanInner),
      );
    }

    return source;
  }
}
