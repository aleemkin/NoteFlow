import 'package:equatable/equatable.dart';

/// A range within a document's source text.
final class SourceRange with Equatable {
  final int startOffset;
  final int endOffset;
  final int startLine;
  final int endLine;

  const SourceRange({
    required this.startOffset,
    required this.endOffset,
    required this.startLine,
    required this.endLine,
  });

  int get length => endOffset - startOffset;

  @override
  List<Object?> get props => [startOffset, endOffset, startLine, endLine];
}

/// A simple text range (not Flutter's TextRange, to keep this pure Dart).
final class TextRange with Equatable {
  final int start;
  final int end;

  const TextRange({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}
