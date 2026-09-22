import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/features/document/document.dart';
import 'package:noteflow/core/platform/vault_uri.dart';

void main() {
  group('DocumentParser & MarkdownAdapter Tests', () {
    test(
      'DocumentParser resolves relative drawing path with subfolder directory',
      () {
        const mdContent = '''# Test Doc
Some notes.

@@drawing ./my_diagram.excalidraw #d1 {minHeight=300}
@@
''';
        final bytes = Uint8List.fromList(utf8.encode(mdContent));
        final doc = DocumentParser.parse(
          bytes: bytes,
          uri: const VaultUri(path: 'subfolder/chapter1.md'),
        );

        expect(doc.blocks.length, 3);
        final drawingBlock = doc.blocks[2] as DrawingBlock;
        expect(drawingBlock.drawingUri.path, 'subfolder/my_diagram.excalidraw');
        expect(drawingBlock.minHeight, 300.0);
      },
    );

    test('DocumentParser parses markdown tables with alignments and rows', () {
      const tableMd = '''| Feature | Status | Priority |
| :--- | :---: | ---: |
| Tables | Active | High |
| Task List | Done | Normal |
''';

      final doc = DocumentParser.parse(
        bytes: Uint8List.fromList(utf8.encode(tableMd)),
        uri: const VaultUri(path: 'table.md'),
      );

      expect(doc.blocks.length, 1);
      expect(doc.blocks.first, isA<TableBlock>());

      final table = doc.blocks.first as TableBlock;
      expect(table.headers, ['Feature', 'Status', 'Priority']);
      expect(table.alignments, [
        TableColumnAlign.left,
        TableColumnAlign.center,
        TableColumnAlign.right,
      ]);
      expect(table.rows.length, 2);
      expect(table.rows[0], ['Tables', 'Active', 'High']);
      expect(table.rows[1], ['Task List', 'Done', 'Normal']);
    });

    test(
      'DocumentParser parses ordered lists, task lists, and thematic breaks',
      () {
        const complexMd = '''
1. First ordered item
2. Second ordered item

- [ ] Unchecked task
- [x] Completed task

---
''';

        final doc = DocumentParser.parse(
          bytes: Uint8List.fromList(utf8.encode(complexMd)),
          uri: const VaultUri(path: 'complex.md'),
        );

        expect(doc.blocks.length, 5);

        // Ordered items
        final item1 = doc.blocks[0] as TextBlock;
        expect(item1.role, TextBlockRole.listItem);
        expect(item1.listNumber, '1');
        expect(item1.inlineContent.plainText, 'First ordered item');

        final item2 = doc.blocks[1] as TextBlock;
        expect(item2.role, TextBlockRole.listItem);
        expect(item2.listNumber, '2');
        expect(item2.inlineContent.plainText, 'Second ordered item');

        // Task items
        final task1 = doc.blocks[2] as TextBlock;
        expect(task1.role, TextBlockRole.listItem);
        expect(task1.isTask, isTrue);
        expect(task1.isChecked, isFalse);
        expect(task1.inlineContent.plainText, 'Unchecked task');

        final task2 = doc.blocks[3] as TextBlock;
        expect(task2.role, TextBlockRole.listItem);
        expect(task2.isTask, isTrue);
        expect(task2.isChecked, isTrue);
        expect(task2.inlineContent.plainText, 'Completed task');

        // Thematic break
        final breakBlock = doc.blocks[4];
        expect(breakBlock, isA<ThematicBreakBlock>());
      },
    );

    test(
      'MarkdownAdapter parses bold, italic, code, strikethrough, and links into InlineNode AST',
      () {
        const inlineText =
            'Text with **bold**, *italic*, `code`, ~~deleted~~ and [link](https://flutter.dev)';
        final nodes = MarkdownAdapter.parseInline(inlineText);

        expect(nodes.any((n) => n is InlineStrong), isTrue);
        expect(nodes.any((n) => n is InlineEmphasis), isTrue);
        expect(nodes.any((n) => n is InlineCode), isTrue);
        expect(nodes.any((n) => n is InlineStrikethrough), isTrue);
        expect(nodes.any((n) => n is InlineLink), isTrue);

        final codeNode = nodes.firstWhere((n) => n is InlineCode) as InlineCode;
        expect(codeNode.code, 'code');

        final linkNode = nodes.firstWhere((n) => n is InlineLink) as InlineLink;
        expect(linkNode.destination, 'https://flutter.dev');
      },
    );

    test(
      'DocumentParser preserves heading level and role when wrapped in @@imp directive',
      () {
        const source = '''@@imp #mark_h1
# Important Architecture Principle
@@
''';
        final doc = DocumentParser.parse(
          bytes: Uint8List.fromList(utf8.encode(source)),
          uri: const VaultUri(path: 'arch.md'),
        );

        expect(doc.blocks.length, 1);
        final block = doc.blocks.first as TextBlock;
        expect(block.role, TextBlockRole.heading1);
        expect(block.headingLevel, 1);
        expect(
          block.inlineContent.plainText,
          'Important Architecture Principle',
        );
        expect(block.marks.length, 1);
        expect(block.marks.first.type, 'imp');
      },
    );

    test(
      'DocumentParser correctly parses drawing directive wrapped inside semantic tag directive',
      () {
        const markdown = '''# Note
@@imp #mark_42
@@drawing ./sub/arch.excalidraw #draw_99 {minHeight=320}
@@
@@
''';
        final doc = DocumentParser.parse(
          bytes: Uint8List.fromList(utf8.encode(markdown)),
          uri: const VaultUri(path: 'note.md'),
        );

        final drawingBlocks = doc.blocks.whereType<DrawingBlock>().toList();
        expect(drawingBlocks.length, 1);
        final db = drawingBlocks.first;
        expect(db.drawingUri.path, 'sub/arch.excalidraw');
        expect(db.minHeight, 320.0);
        expect(db.marks.length, 1);
        expect(db.marks.first.type, 'imp');
        expect(db.marks.first.id, 'mark_42');
      },
    );
  });
}
