/// Utility for parsing notebook-specific directive headers and bracketed attributes.
///
/// Handles syntax like:
/// - `drawing ./diagram.excalidraw #draw_1 {minHeight=300}`
/// - `imp #imp_1`
/// - `info #info_1 {title="Reference Notes"}`
class DirectiveHeaderParser {
  DirectiveHeaderParser._();

  /// Parse a directive header line, populating [attrs] with extracted key-values and IDs.
  /// Returns the directive type slug (e.g. 'drawing', 'imp', 'info').
  static String parseDirectiveHeader(String header, Map<String, String> attrs) {
    final parts = header.split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';

    final directiveType = parts[0];

    // Parse #id outside braces
    final idMatch = RegExp(r'#(\S+)').firstMatch(header);
    if (idMatch != null) {
      attrs['id'] = idMatch.group(1)!;
    }

    // Check for a path (second token not starting with { and not starting with #)
    if (parts.length > 1 &&
        !parts[1].startsWith('{') &&
        !parts[1].startsWith('#')) {
      attrs['path'] = parts[1];
    }

    // Parse {key=value key="value"} block
    parseBraceAttributes(header, attrs);

    return directiveType;
  }

  /// Parses curly-brace delimited attributes such as `{minHeight=420 title="My Title" #id}`.
  static void parseBraceAttributes(String text, Map<String, String> attrs) {
    final braceMatch = RegExp(r'\{([^}]+)\}').firstMatch(text);
    if (braceMatch != null) {
      final inner = braceMatch.group(1)!;
      // Extract #id
      final idMatch = RegExp(r'#(\S+)').firstMatch(inner);
      if (idMatch != null) {
        attrs['id'] = idMatch.group(1)!;
      }
      // Extract key=value pairs
      final kvMatches = RegExp(
        r'(\w+)=(?:"([^"]*)"|([\w.]+))',
      ).allMatches(inner);
      for (final kv in kvMatches) {
        attrs[kv.group(1)!] = kv.group(2) ?? kv.group(3)!;
      }
      // Extract title="..." specifically
      final titleMatch = RegExp(r'title="([^"]*)"').firstMatch(inner);
      if (titleMatch != null) {
        attrs['title'] = titleMatch.group(1)!;
      }
    }
  }
}
