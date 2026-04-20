import 'package:noteflow/core/utils/typedefs.dart';
import 'package:noteflow/core/platform/vault_uri.dart';

import 'inline_content.dart';
import 'semantic_mark.dart';
import 'source_range.dart';

/// The kind of a notebook document.
enum DocumentKind {
  /// Standard Markdown note.
  markdown,

  /// Excalidraw drawing canvas.
  drawing,
}

/// The semantic role of a text block.
enum TextBlockRole {
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  paragraph,
  blockquote,
  listItem,
  code,
}

/// Base class for all document blocks in a [NotebookDocument].
sealed class DocumentBlock {
  /// Unique identifier of this block within the document.
  BlockId get id;

  /// The range within the source text corresponding to this block.
  SourceRange? get sourceRange;

  /// Semantic marks and tags associated with this block.
  List<SemanticMark> get marks;
}

/// A text-based block (heading, paragraph, code, blockquote, list item).
final class TextBlock extends DocumentBlock {
  @override
  final BlockId id;

  /// The syntactic and semantic role of this text block.
  final TextBlockRole role;

  /// Parsed inline content (text, bold, italic, inline marks).
  final InlineContent inlineContent;

  @override
  final SourceRange? sourceRange;

  @override
  final List<SemanticMark> marks;

  /// The heading depth (1 to 6) if this is a heading block.
  final int? headingLevel;

  /// The code block programming language, if applicable.
  final String? language;

  /// Ordered list number prefix (e.g. '1', '2'), if this is an ordered list item.
  final String? listNumber;

  /// Whether this is a task checkbox list item (`- [ ]` / `- [x]`).
  final bool isTask;

  /// Whether this task list item is checked/completed.
  final bool isChecked;

  /// Creates a [TextBlock] instance.
  TextBlock({
    required this.id,
    required this.role,
    required this.inlineContent,
    this.sourceRange,
    this.marks = const [],
    this.headingLevel,
    this.language,
    this.listNumber,
    this.isTask = false,
    this.isChecked = false,
  });
}

/// Alignment of a table column.
enum TableColumnAlign { left, center, right }

/// A structured Markdown table block.
final class TableBlock extends DocumentBlock {
  @override
  final BlockId id;

  /// Table column headers.
  final List<String> headers;

  /// Alignment per column.
  final List<TableColumnAlign> alignments;

  /// Table body rows containing cell string values.
  final List<List<String>> rows;

  @override
  final SourceRange? sourceRange;

  @override
  final List<SemanticMark> marks;

  TableBlock({
    required this.id,
    required this.headers,
    this.alignments = const [],
    required this.rows,
    this.sourceRange,
    this.marks = const [],
  });
}

/// A horizontal divider line / thematic break (`---`, `***`, `___`).
final class ThematicBreakBlock extends DocumentBlock {
  @override
  final BlockId id;

  @override
  final SourceRange? sourceRange;

  @override
  final List<SemanticMark> marks;

  ThematicBreakBlock({
    required this.id,
    this.sourceRange,
    this.marks = const [],
  });
}

/// A drawing block referencing an external drawing file.
final class DrawingBlock extends DocumentBlock {
  @override
  final BlockId id;

  /// The relative URI pointing to the `.excalidraw` file.
  final VaultUri drawingUri;

  /// The minimum rendering height in logical pixels.
  final double? minHeight;

  @override
  final SourceRange? sourceRange;

  @override
  final List<SemanticMark> marks;

  /// Creates a [DrawingBlock] instance.
  DrawingBlock({
    required this.id,
    required this.drawingUri,
    this.minHeight,
    this.sourceRange,
    this.marks = const [],
  });
}

/// A transclusion block that references a tagged block from elsewhere in the vault.
///
/// Rendered inline as a preview of the referenced content. Created by `@@view` directives:
/// - `@@view #mark-id` — searches current document, then active folder.
/// - `@@view path/to/note.md#mark-id` — resolves a specific document.
final class ViewBlock extends DocumentBlock {
  @override
  final BlockId id;

  /// The mark ID being referenced (e.g. 'fix-auth', 'mark_1726720000').
  final String markRef;

  /// Optional vault-relative document path for cross-document references.
  /// If null, the mark is searched in the current document first, then the active folder.
  final String? docPath;

  @override
  final SourceRange? sourceRange;

  @override
  final List<SemanticMark> marks;

  /// Creates a [ViewBlock] instance.
  ViewBlock({
    required this.id,
    required this.markRef,
    this.docPath,
    this.sourceRange,
    this.marks = const [],
  });
}
