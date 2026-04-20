import 'package:noteflow/features/document/domain/source_range.dart';

/// Types of blocks the scanner can identify.
enum ScannedBlockType {
  frontmatter,
  heading,
  paragraph,
  codeBlock,
  blockquote,
  listItem,
  table,
  drawingDirective,
  markDirective,
  infoReference,
  viewDirective,
  thematicBreak,
  blank,
}

/// A raw block identified by the scanner, with source location.
final class ScannedBlock {
  final ScannedBlockType type;
  final SourceRange sourceRange;
  final String content;
  final Map<String, String> attributes;

  const ScannedBlock({
    required this.type,
    required this.sourceRange,
    required this.content,
    this.attributes = const {},
  });
}
