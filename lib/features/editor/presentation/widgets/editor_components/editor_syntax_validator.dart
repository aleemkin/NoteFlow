/// Lightweight syntax validation to detect incomplete or malformed directives and blocks.
class EditorSyntaxValidator {
  const EditorSyntaxValidator._();

  /// Validates markdown and custom directives syntax, returning a warning message if invalid.
  static String? validate(String text) {
    if (text.isEmpty) return null;
    final lines = text.split('\n');
    final openDirectives = <String>[];
    int codeFenceCount = 0;
    var inFrontmatter = false;

    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();

      // Frontmatter handling
      if (i == 0 &&
          (trimmed == '---' ||
              text.startsWith('---\n') ||
              text.startsWith('---\r\n'))) {
        inFrontmatter = true;
        continue;
      }
      if (inFrontmatter) {
        if (trimmed == '---') {
          inFrontmatter = false;
        }
        continue;
      }

      // Code block fence toggle
      if (trimmed.startsWith('```')) {
        codeFenceCount++;
        continue;
      }
      if (codeFenceCount % 2 != 0) {
        continue; // Inside code block, skip directive checks
      }

      // Single-line directive shorthand: @@tag> text
      if (RegExp(r'^@@([a-zA-Z][\w-]*)>\s*(.+)$').hasMatch(trimmed)) {
        continue;
      }

      // View directive
      if (trimmed.startsWith('@@view')) {
        final parts = trimmed.substring(6).trim().split(RegExp(r'\s+'));
        if (parts.isEmpty || parts.first.isEmpty) {
          return 'Line ${i + 1}: @@view requires target #id';
        }
        continue;
      }

      // Multi-line directive opener: @@tag
      if (trimmed.startsWith('@@') &&
          trimmed.length > 2 &&
          RegExp(r'^@@[a-zA-Z][\w-]*').hasMatch(trimmed)) {
        final raw = trimmed.substring(2).trim();
        final tag = raw.split(RegExp(r'\s+')).first.toLowerCase();

        if (tag == 'drawing') {
          final parts = raw.split(RegExp(r'\s+'));
          final hasTokenPath =
              parts.length > 1 &&
              !parts[1].startsWith('{') &&
              !parts[1].startsWith('#');
          final hasBracePath = RegExp(
            r'\{[^}]*(?:path="?[^"\s}]+"?)',
          ).hasMatch(raw);
          if (!hasTokenPath && !hasBracePath) {
            return 'Line ${i + 1}: @@drawing missing diagram file path';
          }
        }

        openDirectives.add(tag);
        continue;
      }

      // Directive closer: @@/tag, @/tag, @@/, @/, @@
      final closerMatch = RegExp(
        r'^(?:@@/|@/)([a-zA-Z][\w-]*)(?:\s+.*)?$',
      ).firstMatch(trimmed);
      final isCloser =
          closerMatch != null ||
          trimmed == '@@' ||
          trimmed == '@@/' ||
          trimmed == '@/';
      if (isCloser) {
        final closerTag = closerMatch?.group(1)?.toLowerCase();
        if (closerTag == null) {
          if (openDirectives.isNotEmpty) {
            openDirectives.removeLast();
          }
        } else if (openDirectives.contains(closerTag)) {
          while (openDirectives.isNotEmpty) {
            final popped = openDirectives.removeLast();
            if (popped == closerTag) break;
          }
        } else {
          return 'Line ${i + 1}: Unexpected closer @@/$closerTag';
        }
      }
    }

    if (codeFenceCount % 2 != 0) {
      return 'Unclosed code block (```)';
    }

    if (openDirectives.isNotEmpty) {
      return 'Incomplete directive: @@${openDirectives.last} (expecting @@/${openDirectives.last})';
    }

    return null;
  }
}
