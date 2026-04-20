import 'package:noteflow/core/platform/vault_uri.dart';

/// The kind of atomic unit (document header, heading section, drawing diagram, or content section).
enum AtomicUnitKind {
  /// The parent document itself or root file header.
  document,

  /// A heading block and all following subordinate content.
  heading,

  /// An embedded drawing or standalone diagram file.
  drawing,

  /// An independent content section or paragraph chunk.
  section,
}

/// Represents an atomic, reorderable unit of content in a notebook document.
///
/// Atomic units allow seamless drag-and-drop structural reorganization across
/// documents while preserving byte-level accuracy and Markdown semantics.
final class AtomicUnit {
  /// Unique identifier for this atomic unit.
  final String id;

  /// The URI of the document containing this unit.
  final VaultUri docUri;

  /// Display title or summary for this atomic unit.
  final String title;

  /// The structural kind of this unit.
  final AtomicUnitKind kind;

  /// The heading depth (1 for H1, 2 for H2, etc.), or 0 if not a heading.
  final int headingLevel;

  /// Raw Markdown content encapsulated by this unit.
  final String rawMarkdown;

  /// File path to the referenced drawing, if this unit represents a drawing.
  final String? drawingPath;

  /// Identifier of the target block rendered on screen.
  final String targetBlockId;

  /// Creates an immutable [AtomicUnit].
  const AtomicUnit({
    required this.id,
    required this.docUri,
    required this.title,
    required this.kind,
    this.headingLevel = 0,
    required this.rawMarkdown,
    this.drawingPath,
    required this.targetBlockId,
  });

  /// Creates a copy of this [AtomicUnit] with specified fields replaced.
  AtomicUnit copyWith({
    String? id,
    VaultUri? docUri,
    String? title,
    AtomicUnitKind? kind,
    int? headingLevel,
    String? rawMarkdown,
    String? drawingPath,
    String? targetBlockId,
  }) {
    return AtomicUnit(
      id: id ?? this.id,
      docUri: docUri ?? this.docUri,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      headingLevel: headingLevel ?? this.headingLevel,
      rawMarkdown: rawMarkdown ?? this.rawMarkdown,
      drawingPath: drawingPath ?? this.drawingPath,
      targetBlockId: targetBlockId ?? this.targetBlockId,
    );
  }
}
