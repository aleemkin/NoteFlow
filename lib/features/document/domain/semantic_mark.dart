import 'package:equatable/equatable.dart';

import 'package:noteflow/core/utils/typedefs.dart';

import 'source_range.dart';

/// A semantic annotation attached to document content.
///
/// Marks are first-class semantic concepts (not just formatting).
/// Built-in types: 'imp' (important), 'info' (contextual reference).
/// Users can create custom mark types as well.
final class SemanticMark with Equatable {
  /// Unique identifier of this mark.
  final MarkId id;

  /// The mark identifier/slug (e.g. 'imp', 'info', or custom slug).
  final String type;

  /// The block-level source range covered by this mark.
  final SourceRange sourceRange;

  /// The sub-range within the block text if this is an inline mark.
  final TextRange? inlineRange;

  /// Arbitrary structured attributes associated with this mark.
  final Map<String, Object?> attrs;

  /// Creates a [SemanticMark] instance.
  const SemanticMark({
    required this.id,
    required this.type,
    required this.sourceRange,
    this.inlineRange,
    this.attrs = const {},
  });

  @override
  List<Object?> get props => [id, type, sourceRange, inlineRange, attrs];
}
