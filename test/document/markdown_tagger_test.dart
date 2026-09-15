import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/features/document/document.dart';

void main() {
  group('MarkdownTagger Tests', () {
    test(
      'tagText expands word selection in heading to atomic heading block without breaking markdown syntax',
      () {
        const source = '# second one\nsecond one is this';
        final tagged = MarkdownTagger.tagText(source, 'second', 'imp');

        expect(tagged, contains('@@imp'));
        expect(tagged, contains('# second one'));
        expect(tagged, contains('second one is this'));
        // Must not split `# ` from `second`
        expect(tagged, isNot(contains('# \n')));
      },
    );

    test(
      'tagText preserves nested inner tags as atomic units when surrounding text is tagged',
      () {
        const source = '''@@imp #inner_tag_99
this
@@
and more text''';

        // User selects all and marks info
        final tagged = MarkdownTagger.tagText(source, source, 'info');

        expect(tagged, contains('@@info'));
        // Inner tag should be preserved as an atomic unit
        expect(tagged, contains('inner_tag_99'));
        expect(tagged, contains('@@imp'));
        expect(tagged, contains('and more text'));
      },
    );

    test(
      'tagText expands overlapping selections across existing tags into a single unified tag',
      () {
        const source = '''# Title
@@imp #m1
First part
@@
Middle text
@@imp #m2
Last part
@@''';

        // User selects from "First part" through "Middle text" and "Last part"
        final tagged = MarkdownTagger.tagText(
          source,
          'First part\n@@\nMiddle text\n@@imp #m2\nLast part',
          'imp',
        );

        expect(tagged, contains('@@imp'));
        expect(tagged, contains('First part\nMiddle text\nLast part'));
        // Should have only 1 @@imp block instead of multiple
        expect('@@imp'.allMatches(tagged).length, 1);
      },
    );

    test(
      'tagText merges consecutive same-tag directives into a single tag block',
      () {
        const source = '''@@todo #t1
Task Alpha
@@

Task Beta''';

        // User tags "Task Beta" with "todo"
        final tagged = MarkdownTagger.tagText(source, 'Task Beta', 'todo');

        expect(tagged, contains('@@todo'));
        expect(tagged, contains('Task Alpha\n\nTask Beta'));
        // Only 1 @@todo block
        expect('@@todo'.allMatches(tagged).length, 1);
      },
    );

    test(
      'mergeConsecutiveDirectives preserves drawing blocks and never merges them',
      () {
        const source = '''@@drawing ./diagram1.excalidraw #d1 {minHeight=260}
@@

@@drawing ./diagram2.excalidraw #d2 {minHeight=260}
@@''';

        final result = MarkdownTagger.mergeConsecutiveDirectives(source);
        expect(result, contains('./diagram1.excalidraw'));
        expect(result, contains('./diagram2.excalidraw'));
        expect('@@drawing'.allMatches(result).length, 2);
      },
    );

    test(
      'findDirectives and stripDirectives handle drawing directives with paths',
      () {
        const source =
            '''@@drawing ./sub/my_drawing.excalidraw #draw_1 {minHeight=300}
@@''';

        final dirs = MarkdownTagger.findDirectives(source);
        expect(dirs.length, 1);
        expect(dirs.first.tagType, 'drawing');

        final stripped = MarkdownTagger.stripDirectives(source);
        expect(stripped, isEmpty);
      },
    );

    test('removeTag removes all overlapping directives across selection', () {
      const source = '''@@review #r1
Part One
@@
Interlude
@@review #r2
Part Two
@@''';

      final untagged = MarkdownTagger.removeTag(
        source,
        'Part One\n@@\nInterlude\n@@review #r2\nPart Two',
      );

      expect(untagged, isNot(contains('@@review')));
      expect(untagged, isNot(contains('@@')));
      expect(untagged, contains('Part One'));
      expect(untagged, contains('Interlude'));
      expect(untagged, contains('Part Two'));
    });

    test(
      'MarkdownTagger.findSourceSpan accurately finds spans across inline formatting and directives',
      () {
        const source = '''# Title

This is **important** note with [link](https://example.com) and `code`.

@@imp #mark_1
second
@@
 one
second one is 
@@imp #mark_2
@@imp #mark_3
this
@@
@@
''';

        // 1. Match across bold and link inline formatting
        final span1 = MarkdownTagger.findSourceSpan(
          source,
          'is important note with link',
        );
        expect(span1, isNotNull);
        final matched1 = source.substring(span1!.start, span1.end);
        expect(matched1.contains('**important**'), isTrue);
        expect(matched1.contains('[link'), isTrue);

        // 2. Match across existing directive boundary: "second one"
        final span2 = MarkdownTagger.findSourceSpan(source, 'second\n one');
        expect(span2, isNotNull);
        final matched2 = source.substring(span2!.start, span2.end);
        expect(matched2.contains('second'), isTrue);
        expect(matched2.contains(' one'), isTrue);

        // 3. Tagging across "second one" merges directive cleanly
        final tagged = MarkdownTagger.tagText(source, 'second\n one', 'imp');
        expect(tagged.contains('@@imp'), isTrue);
        expect(tagged.contains('second\n one'), isTrue);
        // No corrupted nested directives inside the new block
        expect(tagged.contains('@@imp\n@@imp'), isFalse);
      },
    );

    test(
      'MarkdownTagger preserves entire Table as atomic unit and prevents splitting tables',
      () {
        const docWithTable = '''---
kn:
  id: doc_01a0afb6-a8c8-79d4-8afb-cbef3e985806
  schema: 1
---

# two.md

this one is a bit awk

| Header 1 | Header 2 | Header 3 |
| -------- | -------- | -------- |
| Row 1 A  | Row 1 B  | Row 1 C  |
| Row 2 A  | Row 2 B  | Row 2 C  |
''';

        // 1. User selects paragraph + table header only
        final tagged = MarkdownTagger.tagText(
          docWithTable,
          'this one is a bit awk\n\n| Header 1 | Header 2 | Header 3 |',
          'imp',
        );

        // The entire table must be contained within @@imp without being sliced in half
        expect(tagged.contains('@@imp'), isTrue);
        expect(tagged.contains('this one is a bit awk'), isTrue);
        expect(tagged.contains('| Header 1 | Header 2 | Header 3 |'), isTrue);
        expect(tagged.contains('| Row 2 A  | Row 2 B  | Row 2 C  |'), isTrue);
        // Frontmatter must remain untouched at the beginning
        expect(tagged.startsWith('---\nkn:'), isTrue);

        // Check that closing @@ comes AFTER Row 2 C, not after Header 1
        final closeIndex = tagged.indexOf('@@');
        final secondCloseIndex = tagged.indexOf('@@', closeIndex + 3);
        final row2Index = tagged.indexOf('| Row 2 A  | Row 2 B  | Row 2 C  |');
        expect(row2Index, lessThan(secondCloseIndex));
      },
    );

    test(
      'MarkdownTagger expands code blocks and preserves frontmatter during atomic operations',
      () {
        const docWithCode = '''---
kn:
  id: doc_test_123
---

# Code Sample

```dart
void main() {
  print('hello atomic');
}
```

Paragraph after code.
''';

        // 1. Select text inside code block: print('hello atomic')
        final tagged = MarkdownTagger.tagText(
          docWithCode,
          "print('hello atomic')",
          'info',
        );
        expect(tagged.contains('@@info'), isTrue);
        expect(tagged.contains('```dart'), isTrue);
        expect(tagged.contains('Paragraph after code.'), isTrue);
        // The opening ```dart and closing ``` must both be inside @@info
        final infoStart = tagged.indexOf('@@info');
        final infoEnd = tagged.indexOf('@@', infoStart + 7);
        final dartStart = tagged.indexOf('```dart');
        final dartEnd = tagged.indexOf('```\n@@', dartStart);
        expect(dartStart, greaterThan(infoStart));
        expect(dartEnd, lessThanOrEqualTo(infoEnd));

        // 2. Expand boundaries for diagram above heading
        final span = MarkdownTagger.findSourceSpan(docWithCode, 'Code Sample');
        expect(span, isNotNull);
        final atomicSpan = MarkdownTagger.expandToAtomicBlockBoundaries(
          docWithCode,
          span!.start,
          span.end,
        );
        // Start must be after frontmatter
        expect(
          atomicSpan.start,
          greaterThanOrEqualTo(docWithCode.indexOf('# Code Sample')),
        );
      },
    );

    test(
      'MarkdownTagger.tagText wraps drawing directive without deleting the drawing',
      () {
        const source = '''# Title

@@drawing ./diagram_1.excalidraw #draw_101 {minHeight=260}
@@
''';
        final tagged = MarkdownTagger.tagText(
          source,
          '@@drawing ./diagram_1.excalidraw\n#draw_101 {minHeight=260}\n@@',
          'imp',
        );
        expect(tagged, contains('@@imp'));
        expect(tagged, contains('@@drawing ./diagram_1.excalidraw'));
        expect(tagged, contains('minHeight=260'));
      },
    );

    test(
      'MarkdownTagger.removeTag removes tag from wrapped drawing without deleting drawing',
      () {
        const source = '''@@imp #mark_1
@@drawing ./diagram_1.excalidraw #draw_101 {minHeight=260}
@@
@@''';
        final cleaned = MarkdownTagger.removeTag(
          source,
          '@@drawing ./diagram_1.excalidraw\n#draw_101 {minHeight=260}\n@@',
        );
        expect(cleaned, isNot(contains('@@imp')));
        expect(cleaned, contains('@@drawing ./diagram_1.excalidraw'));
        expect(cleaned, contains('minHeight=260'));
      },
    );
  });
}
