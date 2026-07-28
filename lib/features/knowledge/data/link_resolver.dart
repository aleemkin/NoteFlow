import 'package:noteflow/features/document/domain/models.dart';

/// Resolves semantic mark references across documents.
class LinkResolver {
  LinkResolver._();

  /// Resolves a `@@view` mark reference across a list of documents.
  ///
  /// If [docPath] is provided, only searches the document at that path.
  /// Otherwise searches [currentDoc] first, then all [allDocs] in the folder.
  ///
  /// Returns null if the mark cannot be resolved.
  static MarkResolution? resolveMarkRef({
    required String markRef,
    String? docPath,
    NotebookDocument? currentDoc,
    required List<NotebookDocument> allDocs,
  }) {
    // Helper to search a single document for a mark ID
    MarkResolution? searchDoc(NotebookDocument doc) {
      for (final block in doc.blocks) {
        for (final mark in block.marks) {
          if (mark.id == markRef) {
            return MarkResolution(sourceDoc: doc, block: block, mark: mark);
          }
        }
      }
      return null;
    }

    // If a specific document path is given, search only that document
    if (docPath != null) {
      var normalizedPath = docPath;
      if (normalizedPath.startsWith('./')) {
        normalizedPath = normalizedPath.substring(2);
      }
      for (final doc in allDocs) {
        if (doc.uri.path == normalizedPath ||
            doc.uri.path.endsWith(normalizedPath)) {
          return searchDoc(doc);
        }
      }
      return null;
    }

    // Search current document first
    if (currentDoc != null) {
      final result = searchDoc(currentDoc);
      if (result != null) return result;
    }

    // Search all documents in the folder
    for (final doc in allDocs) {
      if (doc == currentDoc) continue;
      final result = searchDoc(doc);
      if (result != null) return result;
    }

    return null;
  }
}

/// The result of resolving a `@@view` mark reference.
final class MarkResolution {
  /// The document containing the referenced mark.
  final NotebookDocument sourceDoc;

  /// The block that carries the referenced mark.
  final DocumentBlock block;

  /// The resolved semantic mark.
  final SemanticMark mark;

  const MarkResolution({
    required this.sourceDoc,
    required this.block,
    required this.mark,
  });
}
