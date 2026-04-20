import 'dart:convert';
import 'dart:typed_data';

/// Holds a document's raw source with computed line information.
///
/// Enables efficient source-range lookups and byte-for-byte
/// preservation of unchanged content during edits.
final class DocumentSource {
  final Uint8List utf8Bytes;
  final List<int> lineStarts;
  final String text;

  const DocumentSource._({
    required this.utf8Bytes,
    required this.lineStarts,
    required this.text,
  });

  factory DocumentSource.fromBytes(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    return DocumentSource._(
      utf8Bytes: bytes,
      lineStarts: _computeLineStarts(text),
      text: text,
    );
  }

  factory DocumentSource.fromText(String text) {
    return DocumentSource._(
      utf8Bytes: Uint8List.fromList(utf8.encode(text)),
      lineStarts: _computeLineStarts(text),
      text: text,
    );
  }

  static List<int> _computeLineStarts(String text) {
    final starts = <int>[0];
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x0A) {
        starts.add(i + 1);
      }
    }
    return starts;
  }

  int get lineCount => lineStarts.length;
}
