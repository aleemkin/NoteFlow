import 'package:noteflow/core/utils/typedefs.dart';
import 'package:noteflow/core/platform/vault_uri.dart';

import 'document_block.dart';
import 'document_source.dart';

/// A parsed notebook document with its block structure and source representation.
final class NotebookDocument {
  /// Unique document identifier generated or stored in frontmatter.
  final DocumentId id;

  /// Vault-relative URI of this document.
  final VaultUri uri;

  /// Human-readable title of the document.
  final String title;

  /// The document kind (Markdown document or Drawing canvas).
  final DocumentKind kind;

  /// The list of structured document blocks parsed from source.
  final List<DocumentBlock> blocks;

  /// The raw source text and byte representation.
  final DocumentSource source;

  /// The monotonically increasing revision number for edit tracking.
  final int revision;

  /// Creates a [NotebookDocument] instance.
  const NotebookDocument({
    required this.id,
    required this.uri,
    required this.title,
    required this.kind,
    required this.blocks,
    required this.source,
    this.revision = 1,
  });

  /// Creates a copy of this [NotebookDocument] with specified properties replaced.
  NotebookDocument copyWith({
    DocumentId? id,
    VaultUri? uri,
    String? title,
    DocumentKind? kind,
    List<DocumentBlock>? blocks,
    DocumentSource? source,
    int? revision,
  }) {
    return NotebookDocument(
      id: id ?? this.id,
      uri: uri ?? this.uri,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      blocks: blocks ?? this.blocks,
      source: source ?? this.source,
      revision: revision ?? this.revision,
    );
  }
}
