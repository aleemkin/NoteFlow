import 'package:noteflow/features/document/domain/source_range.dart';
import 'package:noteflow/features/document/parsing/directive_header_parser.dart';
import 'package:noteflow/features/document/parsing/scanned_block.dart';

export 'package:noteflow/features/document/parsing/directive_header_parser.dart';
export 'package:noteflow/features/document/parsing/scanned_block.dart';

/// Scans document text into raw blocks with accurate source ranges.
///
/// Handles notebook-specific directives (@@drawing, @@imp, @@info, @@view)
/// and info references ({{info:...}}) before delegating standard
/// Markdown patterns.
class BlockScanner {
  BlockScanner._();

  static List<ScannedBlock> scan(String text) {
    final blocks = <ScannedBlock>[];
    final lines = text.split('\n');
    var lineIndex = 0;
    var offset = 0;

    // Skip frontmatter
    if (text.startsWith('---\n') || text.startsWith('---\r\n')) {
      final closeIdx = text.indexOf('\n---', 3);
      if (closeIdx != -1) {
        final endOffset = closeIdx + 4;
        final fmLines = text.substring(0, endOffset).split('\n').length - 1;
        blocks.add(
          ScannedBlock(
            type: ScannedBlockType.frontmatter,
            sourceRange: SourceRange(
              startOffset: 0,
              endOffset: endOffset,
              startLine: 0,
              endLine: fmLines,
            ),
            content: text.substring(0, endOffset),
          ),
        );

        // Advance past frontmatter
        while (lineIndex < lines.length && offset < endOffset) {
          offset += lines[lineIndex].length + 1;
          lineIndex++;
        }
      }
    }

    // Accumulator for paragraph lines
    var paraLines = <String>[];
    var paraStartLine = lineIndex;
    var paraStartOffset = offset;

    void flushParagraph() {
      if (paraLines.isEmpty) return;
      final content = paraLines.join('\n');
      blocks.add(
        ScannedBlock(
          type: ScannedBlockType.paragraph,
          sourceRange: SourceRange(
            startOffset: paraStartOffset,
            endOffset: paraStartOffset + content.length,
            startLine: paraStartLine,
            endLine: paraStartLine + paraLines.length - 1,
          ),
          content: content,
        ),
      );
      paraLines = [];
    }

    while (lineIndex < lines.length) {
      final line = lines[lineIndex];
      final trimmed = line.trim();

      // Blank line
      if (trimmed.isEmpty) {
        flushParagraph();
        blocks.add(
          ScannedBlock(
            type: ScannedBlockType.blank,
            sourceRange: SourceRange(
              startOffset: offset,
              endOffset: offset + line.length,
              startLine: lineIndex,
              endLine: lineIndex,
            ),
            content: line,
          ),
        );
        offset += line.length + 1;
        lineIndex++;
        paraStartLine = lineIndex;
        paraStartOffset = offset;
        continue;
      }

      // Fenced code block
      if (trimmed.startsWith('```')) {
        flushParagraph();
        final language = trimmed.length > 3
            ? trimmed.substring(3).trim()
            : null;
        final startLine = lineIndex;
        final startOffset = offset;
        final codeLines = <String>[];
        offset += line.length + 1;
        lineIndex++;
        // Collect until closing ```
        while (lineIndex < lines.length) {
          final cl = lines[lineIndex];
          if (cl.trim() == '```') {
            offset += cl.length + 1;
            lineIndex++;
            break;
          }
          codeLines.add(cl);
          offset += cl.length + 1;
          lineIndex++;
        }
        final content = codeLines.join('\n');
        blocks.add(
          ScannedBlock(
            type: ScannedBlockType.codeBlock,
            sourceRange: SourceRange(
              startOffset: startOffset,
              endOffset: offset,
              startLine: startLine,
              endLine: lineIndex - 1,
            ),
            content: content,
            attributes: {
              if (language != null && language.isNotEmpty) 'language': language,
            },
          ),
        );
        paraStartLine = lineIndex;
        paraStartOffset = offset;
        continue;
      }

      // @@view transclusion (single-line, no closer)
      if (trimmed.startsWith('@@view ')) {
        flushParagraph();
        final startLine = lineIndex;
        final startOffset = offset;
        final refPart = trimmed.substring(7).trim();
        final attrs = <String, String>{};

        // Parse: "#mark-id" or "path/to/note.md#mark-id"
        final hashIdx = refPart.indexOf('#');
        if (hashIdx > 0) {
          attrs['docPath'] = refPart.substring(0, hashIdx);
          attrs['ref'] = refPart.substring(hashIdx + 1);
        } else if (hashIdx == 0) {
          attrs['ref'] = refPart.substring(1);
        } else {
          attrs['ref'] = refPart;
        }

        blocks.add(
          ScannedBlock(
            type: ScannedBlockType.viewDirective,
            sourceRange: SourceRange(
              startOffset: startOffset,
              endOffset: offset + line.length,
              startLine: startLine,
              endLine: startLine,
            ),
            content: refPart,
            attributes: attrs,
          ),
        );
        offset += line.length + 1;
        lineIndex++;
        paraStartLine = lineIndex;
        paraStartOffset = offset;
        continue;
      }

      // @@tag> single-line shorthand
      final singleLineTagMatch = RegExp(
        r'^@@([a-zA-Z][\w-]*)>\s*(.+)$',
      ).firstMatch(trimmed);
      if (singleLineTagMatch != null) {
        flushParagraph();
        final startLine = lineIndex;
        final startOffset = offset;
        final tagSlug = singleLineTagMatch.group(1)!;
        final content = singleLineTagMatch.group(2)!;
        final attrs = <String, String>{'markType': tagSlug};
        DirectiveHeaderParser.parseBraceAttributes(content, attrs);

        final blockType = tagSlug == 'drawing'
            ? ScannedBlockType.drawingDirective
            : ScannedBlockType.markDirective;

        blocks.add(
          ScannedBlock(
            type: blockType,
            sourceRange: SourceRange(
              startOffset: startOffset,
              endOffset: offset + line.length,
              startLine: startLine,
              endLine: startLine,
            ),
            content: content,
            attributes: attrs,
          ),
        );
        offset += line.length + 1;
        lineIndex++;
        paraStartLine = lineIndex;
        paraStartOffset = offset;
        continue;
      }

      // @@tag multi-line directive blocks
      if (trimmed.startsWith('@@') &&
          trimmed.length > 2 &&
          RegExp(r'^@@[a-zA-Z][\w-]*').hasMatch(trimmed)) {
        flushParagraph();
        final startLine = lineIndex;
        final startOffset = offset;

        final headerRaw = trimmed.substring(2).trim();
        final attrs = <String, String>{};
        final directiveType = DirectiveHeaderParser.parseDirectiveHeader(
          headerRaw,
          attrs,
        );

        final contentLines = <String>[];
        // Multi-line: collect until matching balanced closer (@@/tag, @/tag, or @@)
        offset += line.length + 1;
        lineIndex++;
        final tagStack = <String>[directiveType.toLowerCase()];
        while (lineIndex < lines.length) {
          final dl = lines[lineIndex];
          final dlTrimmed = dl.trim();

          if (dlTrimmed.startsWith('@@') &&
              dlTrimmed.length > 2 &&
              RegExp(r'^@@[a-zA-Z][\w-]*').hasMatch(dlTrimmed)) {
            // Nested opener: push tag to stack
            final innerRaw = dlTrimmed.substring(2).trim();
            final dummyAttrs = <String, String>{};
            final innerTag = DirectiveHeaderParser.parseDirectiveHeader(
              innerRaw,
              dummyAttrs,
            ).toLowerCase();
            tagStack.add(innerTag);
          } else {
            // Check closer: @@/tag, @/tag, @@/, @/, or @@
            final closerMatch = RegExp(
              r'^(?:@@/|@/)([a-zA-Z][\w-]*)(?:\s+.*)?$',
            ).firstMatch(dlTrimmed);
            final isCloser =
                closerMatch != null ||
                dlTrimmed == '@@' ||
                dlTrimmed == '@@/' ||
                dlTrimmed == '@/';
            if (isCloser) {
              final closerTag = closerMatch?.group(1)?.toLowerCase();
              if (closerTag == null) {
                // Anonymous closer pops top of stack
                if (tagStack.isNotEmpty) tagStack.removeLast();
              } else if (tagStack.contains(closerTag)) {
                // HTML-style unwinding until matching tag is closed
                while (tagStack.isNotEmpty) {
                  final popped = tagStack.removeLast();
                  if (popped == closerTag) break;
                }
              } else {
                // Typo or mismatch: close innermost tag to avoid unclosed runaway
                if (tagStack.isNotEmpty) tagStack.removeLast();
              }

              if (tagStack.isEmpty) {
                // Root directive has closed
                offset += dl.length + 1;
                lineIndex++;
                break;
              }
            }
          }

          contentLines.add(dl);
          offset += dl.length + 1;
          lineIndex++;
        }

        // Also extract attributes from content lines for drawing directives
        if (directiveType == 'drawing') {
          for (final cl in contentLines) {
            final clTrimmed = cl.trim();
            if (clTrimmed.contains('{') && clTrimmed.contains('}')) {
              DirectiveHeaderParser.parseBraceAttributes(clTrimmed, attrs);
            }
            if (!attrs.containsKey('path')) {
              if (clTrimmed.isNotEmpty &&
                  !clTrimmed.startsWith('{') &&
                  !clTrimmed.startsWith('@@') &&
                  !clTrimmed.startsWith('@/')) {
                attrs['path'] = clTrimmed;
              }
            }
          }
        }

        final content = contentLines.join('\n').trim();

        final blockType = switch (directiveType) {
          'drawing' => ScannedBlockType.drawingDirective,
          _ => ScannedBlockType.markDirective,
        };
        attrs['markType'] = directiveType;

        blocks.add(
          ScannedBlock(
            type: blockType,
            sourceRange: SourceRange(
              startOffset: startOffset.clamp(0, text.length),
              endOffset: offset.clamp(0, text.length),
              startLine: startLine,
              endLine: lineIndex - 1,
            ),
            content: content,
            attributes: attrs,
          ),
        );
        paraStartLine = lineIndex;
        paraStartOffset = offset;
        continue;
      }

      // Stray closing marker (ignore so it doesn't render in paragraph)
      final isStrayCloser =
          trimmed == '@@' ||
          trimmed == '@@/' ||
          trimmed == '@/' ||
          RegExp(r'^(?:@@/|@/)[a-zA-Z][\w-]*').hasMatch(trimmed);
      if (isStrayCloser) {
        flushParagraph();
        offset += line.length + 1;
        lineIndex++;
        paraStartLine = lineIndex;
        paraStartOffset = offset;
        continue;
      }

      // Info reference: {{info:...}}
      if (trimmed.startsWith('{{info:') && trimmed.endsWith('}}')) {
        flushParagraph();
        final ref = trimmed.substring(7, trimmed.length - 2);
        blocks.add(
          ScannedBlock(
            type: ScannedBlockType.infoReference,
            sourceRange: SourceRange(
              startOffset: offset,
              endOffset: offset + line.length,
              startLine: lineIndex,
              endLine: lineIndex,
            ),
            content: ref,
            attributes: {'ref': ref},
          ),
        );
        offset += line.length + 1;
        lineIndex++;
        paraStartLine = lineIndex;
        paraStartOffset = offset;
        continue;
      }

      // Heading
      if (trimmed.startsWith('#')) {
        final match = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmed);
        if (match != null) {
          flushParagraph();
          blocks.add(
            ScannedBlock(
              type: ScannedBlockType.heading,
              sourceRange: SourceRange(
                startOffset: offset,
                endOffset: offset + line.length,
                startLine: lineIndex,
                endLine: lineIndex,
              ),
              content: match.group(2)!,
              attributes: {'level': match.group(1)!.length.toString()},
            ),
          );
          offset += line.length + 1;
          lineIndex++;
          paraStartLine = lineIndex;
          paraStartOffset = offset;
          continue;
        }
      }

      // Blockquote
      if (trimmed.startsWith('> ')) {
        flushParagraph();
        final quoteLines = <String>[];
        final startLine = lineIndex;
        final startOff = offset;
        while (lineIndex < lines.length &&
            lines[lineIndex].trim().startsWith('> ')) {
          quoteLines.add(lines[lineIndex].trim().substring(2));
          offset += lines[lineIndex].length + 1;
          lineIndex++;
        }
        blocks.add(
          ScannedBlock(
            type: ScannedBlockType.blockquote,
            sourceRange: SourceRange(
              startOffset: startOff,
              endOffset: offset,
              startLine: startLine,
              endLine: lineIndex - 1,
            ),
            content: quoteLines.join('\n'),
          ),
        );
        paraStartLine = lineIndex;
        paraStartOffset = offset;
        continue;
      }

      // Table block: starts with | ... | and next line has |-+-|
      if (trimmed.startsWith('|') ||
          (trimmed.contains('|') && trimmed.endsWith('|'))) {
        if (lineIndex + 1 < lines.length) {
          final nextTrimmed = lines[lineIndex + 1].trim();
          final isSeparator = RegExp(
            r'^\|?(\s*:?-+:?\s*\|?)+\s*$',
          ).hasMatch(nextTrimmed);
          if (isSeparator) {
            flushParagraph();
            final startLine = lineIndex;
            final startOff = offset;
            final tableLines = <String>[];

            while (lineIndex < lines.length) {
              final tl = lines[lineIndex];
              final tlTrimmed = tl.trim();
              if (tlTrimmed.isEmpty ||
                  (!tlTrimmed.startsWith('|') &&
                      !tlTrimmed.endsWith('|') &&
                      !tlTrimmed.contains('|'))) {
                break;
              }
              tableLines.add(tlTrimmed);
              offset += tl.length + 1;
              lineIndex++;
            }

            blocks.add(
              ScannedBlock(
                type: ScannedBlockType.table,
                sourceRange: SourceRange(
                  startOffset: startOff,
                  endOffset: offset,
                  startLine: startLine,
                  endLine: lineIndex - 1,
                ),
                content: tableLines.join('\n'),
              ),
            );
            paraStartLine = lineIndex;
            paraStartOffset = offset;
            continue;
          }
        }
      }

      // List item
      // 1. Task list item: - [ ] or - [x]
      final taskMatch = RegExp(
        r'^[-*+]\s+\[([ xX])\]\s+(.*)$',
      ).firstMatch(trimmed);
      if (taskMatch != null) {
        flushParagraph();
        final checked = taskMatch.group(1)!.toLowerCase() == 'x';
        final itemContent = taskMatch.group(2)!;
        blocks.add(
          ScannedBlock(
            type: ScannedBlockType.listItem,
            sourceRange: SourceRange(
              startOffset: offset,
              endOffset: offset + line.length,
              startLine: lineIndex,
              endLine: lineIndex,
            ),
            content: itemContent,
            attributes: {
              'isTask': 'true',
              'isChecked': checked ? 'true' : 'false',
            },
          ),
        );
        offset += line.length + 1;
        lineIndex++;
        paraStartLine = lineIndex;
        paraStartOffset = offset;
        continue;
      }

      // 2. Ordered list item: 1. item
      final orderedMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
      if (orderedMatch != null) {
        flushParagraph();
        final num = orderedMatch.group(1)!;
        final itemContent = orderedMatch.group(2)!;
        blocks.add(
          ScannedBlock(
            type: ScannedBlockType.listItem,
            sourceRange: SourceRange(
              startOffset: offset,
              endOffset: offset + line.length,
              startLine: lineIndex,
              endLine: lineIndex,
            ),
            content: itemContent,
            attributes: {'listNumber': num},
          ),
        );
        offset += line.length + 1;
        lineIndex++;
        paraStartLine = lineIndex;
        paraStartOffset = offset;
        continue;
      }

      // 3. Bullet list item: - item or * item or + item
      final bulletMatch = RegExp(r'^[-*+]\s+(.*)$').firstMatch(trimmed);
      if (bulletMatch != null) {
        flushParagraph();
        final itemContent = bulletMatch.group(1)!;
        blocks.add(
          ScannedBlock(
            type: ScannedBlockType.listItem,
            sourceRange: SourceRange(
              startOffset: offset,
              endOffset: offset + line.length,
              startLine: lineIndex,
              endLine: lineIndex,
            ),
            content: itemContent,
          ),
        );
        offset += line.length + 1;
        lineIndex++;
        paraStartLine = lineIndex;
        paraStartOffset = offset;
        continue;
      }

      // Thematic break
      if (RegExp(r'^[-*_]{3,}$').hasMatch(trimmed)) {
        flushParagraph();
        blocks.add(
          ScannedBlock(
            type: ScannedBlockType.thematicBreak,
            sourceRange: SourceRange(
              startOffset: offset,
              endOffset: offset + line.length,
              startLine: lineIndex,
              endLine: lineIndex,
            ),
            content: '',
          ),
        );
        offset += line.length + 1;
        lineIndex++;
        paraStartLine = lineIndex;
        paraStartOffset = offset;
        continue;
      }

      // Otherwise, accumulate as paragraph
      if (paraLines.isEmpty) {
        paraStartLine = lineIndex;
        paraStartOffset = offset;
      }
      paraLines.add(line);
      offset += line.length + 1;
      lineIndex++;
    }

    flushParagraph();
    return blocks;
  }
}
