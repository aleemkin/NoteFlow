import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/features/document/document.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/render/render.dart';
import 'package:noteflow/features/vault/vault.dart';

void main() {
  group('ContinuousFolderSurface & DocumentSurface Tests', () {
    testWidgets(
      'ContinuousFolderSurface displays edit icon in left gutter without bulky file name header',
      (WidgetTester tester) async {
        const mdContent = '''# Chapter One
This is the note content in the continuous roll.
''';
        final doc = DocumentParser.parse(
          bytes: Uint8List.fromList(utf8.encode(mdContent)),
          uri: const VaultUri(path: 'chapter1.md'),
        );

        VaultUri? editedUri;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ContinuousFolderSurface(
                  documents: [doc],
                  scrollController: ScrollController(),
                  blockKeys: const {},
                  onEditDocument: (uri) {
                    editedUri = uri;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should render the document's content
        expect(find.text('Chapter One'), findsOneWidget);
        expect(
          find.text('This is the note content in the continuous roll.'),
          findsOneWidget,
        );

        // Should NOT render bulky raw fileName "chapter1.md" or wide button with text
        expect(find.text('chapter1.md'), findsNothing);

        // Should render edit icon in left gutter
        expect(find.byIcon(Icons.edit_note), findsOneWidget);

        // Tapping the edit icon calls onEditDocument
        await tester.tap(find.byIcon(Icons.edit_note));
        await tester.pumpAndSettle();

        expect(editedUri, isNotNull);
        expect(editedUri!.path, 'chapter1.md');
      },
    );

    testWidgets(
      'ContinuousFolderSurface renders TableBlock, Task List, and Thematic Breaks correctly',
      (WidgetTester tester) async {
        const fullMd = '''# Project Overview

| Header A | Header B |
| :--- | :--- |
| Cell 1 | Cell 2 |

- [ ] Task 1
- [x] Task 2

1. Step One
2. Step Two

---
''';

        final doc = DocumentParser.parse(
          bytes: Uint8List.fromList(utf8.encode(fullMd)),
          uri: const VaultUri(path: 'overview.md'),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ContinuousFolderSurface(
                  documents: [doc],
                  scrollController: ScrollController(),
                  blockKeys: const {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Heading
        expect(find.text('Project Overview'), findsOneWidget);

        // Table cells
        expect(find.text('Header A'), findsOneWidget);
        expect(find.text('Header B'), findsOneWidget);
        expect(find.text('Cell 1'), findsOneWidget);
        expect(find.text('Cell 2'), findsOneWidget);

        // Task checkboxes
        expect(
          find.byIcon(Icons.check_box_outline_blank_rounded),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.check_box_rounded), findsOneWidget);
        expect(find.text('Task 1'), findsOneWidget);
        expect(find.text('Task 2'), findsOneWidget);

        // Ordered list numbers & text
        expect(find.text('1.'), findsOneWidget);
        expect(find.text('2.'), findsOneWidget);
        expect(find.text('Step One'), findsOneWidget);
        expect(find.text('Step Two'), findsOneWidget);

        // Thematic break divider
        expect(find.byType(ThematicBreakRenderer), findsOneWidget);
      },
    );

    testWidgets(
      'ContinuousFolderSurface floating action toolbar buttons invoke callbacks on tap',
      (WidgetTester tester) async {
        String? taggedText;
        String? taggedType;
        String? untaggedText;
        bool? diagramAbove;
        String? diagramText;

        const md = '''# Sample Doc

This is sample paragraph for selection.
''';

        final doc = DocumentParser.parse(
          bytes: Uint8List.fromList(utf8.encode(md)),
          uri: const VaultUri(path: 'sample.md'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ContinuousFolderSurface(
                documents: [doc],
                scrollController: ScrollController(),
                blockKeys: const {},
                onTagText: (text, type) {
                  taggedText = text;
                  taggedType = type;
                },
                onRemoveTag: (text) {
                  untaggedText = text;
                },
                onInsertDiagram: (text, above) {
                  diagramText = text;
                  diagramAbove = above;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger selection by finding SelectionArea and calling onSelectionChanged
        final selectionAreaFinder = find.byType(SelectionArea);
        expect(selectionAreaFinder, findsOneWidget);
        final selectionArea = tester.widget<SelectionArea>(selectionAreaFinder);
        selectionArea.onSelectionChanged?.call(
          const SelectedContent(plainText: 'sample paragraph'),
        );
        await tester.pumpAndSettle();

        // Floating toolbar should be visible with action buttons
        expect(find.text('IMP'), findsOneWidget);
        expect(find.text('INFO'), findsOneWidget);
        expect(find.text('Draw'), findsOneWidget);
        expect(find.text('Above'), findsOneWidget);
        expect(find.text('Untag'), findsOneWidget);

        // Tap 'IMP'
        await tester.tap(find.text('IMP'));
        await tester.pumpAndSettle();

        expect(taggedText, 'sample paragraph');
        expect(taggedType, 'imp');
        // Toolbar should dismiss after action
        expect(find.text('IMP'), findsNothing);

        // Re-trigger selection and tap 'Above'
        selectionArea.onSelectionChanged?.call(
          const SelectedContent(plainText: 'sample paragraph'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Above'), findsOneWidget);
        await tester.tap(find.text('Above'));
        await tester.pumpAndSettle();

        expect(diagramAbove, isTrue);
        expect(diagramText, 'sample paragraph');
        expect(find.text('Above'), findsNothing);

        // Re-trigger selection and tap 'Untag'
        selectionArea.onSelectionChanged?.call(
          const SelectedContent(plainText: 'sample paragraph'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Untag'), findsOneWidget);
        await tester.tap(find.text('Untag'));
        await tester.pumpAndSettle();

        expect(untaggedText, 'sample paragraph');
      },
    );

    testWidgets(
      'DocumentParser parses TableBlock inside @@imp and renders TableBlockRenderer with mark',
      (WidgetTester tester) async {
        const mdWithMarkedTable = '''# doc
this one is a bit awk

@@imp #mark_1789658474858
| Header 1 | Header 2 | Header 3 |
| -------- | -------- | -------- |
| Row 1 A  | Row 1 B  | Row 1 C  |
| Row 2 A  | Row 2 B  | Row 2 C  |
@@
''';

        final doc = DocumentParser.parse(
          bytes: Uint8List.fromList(utf8.encode(mdWithMarkedTable)),
          uri: const VaultUri(path: 'two.md'),
        );

        // Verify blocks: Heading, Paragraph, TableBlock
        expect(doc.blocks.length, 3);
        expect(doc.blocks[0], isA<TextBlock>());
        expect((doc.blocks[0] as TextBlock).role, TextBlockRole.heading1);

        expect(doc.blocks[1], isA<TextBlock>());
        expect((doc.blocks[1] as TextBlock).role, TextBlockRole.paragraph);

        expect(doc.blocks[2], isA<TableBlock>());
        final tableBlock = doc.blocks[2] as TableBlock;
        expect(tableBlock.headers, ['Header 1', 'Header 2', 'Header 3']);
        expect(tableBlock.rows.length, 2);
        expect(tableBlock.rows[0], ['Row 1 A', 'Row 1 B', 'Row 1 C']);
        expect(tableBlock.marks.length, 1);
        expect(tableBlock.marks.first.type, 'imp');

        // Test rendering in DocumentSurface
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DocumentSurface(document: doc)),
          ),
        );
        await tester.pumpAndSettle();

        // TableBlockRenderer must be present and table cells visible
        expect(find.byType(TableBlockRenderer), findsOneWidget);
        expect(find.text('Header 1'), findsOneWidget);
        expect(find.text('Row 1 A'), findsOneWidget);
        expect(find.text('Row 2 C'), findsOneWidget);
      },
    );

    testWidgets(
      'DocumentSurface renders DrawingBlockRenderer with mark icon in gutter when wrapped in tag',
      (WidgetTester tester) async {
        final fs = MemoryVaultFileSystem();
        fs.seed(
          'diagram.excalidraw',
          '{"type":"excalidraw","version":2,"elements":[]}',
        );
        final treeRepo = VaultTreeRepository();
        final manager = VaultManager(treeRepository: treeRepo);
        await manager.openCustomFileSystem(fs, 'Test Vault');

        const markdown = '''# Note
@@imp #mark_1
@@drawing ./diagram.excalidraw #draw_1 {minHeight=260}
@@
@@''';

        final doc = DocumentParser.parse(
          bytes: utf8.encode(markdown),
          uri: const VaultUri(path: 'note.md'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              vaultTreeRepositoryProvider.overrideWith((ref) => treeRepo),
              vaultManagerProvider.overrideWith((ref) => manager),
            ],
            child: MaterialApp(
              home: Scaffold(body: DocumentSurface(document: doc)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // DrawingBlockRenderer must be present
        expect(find.byType(DrawingBlockRenderer), findsOneWidget);
        // Gutter must display the mark strip tooltip
        expect(find.byTooltip('Tag: @@imp'), findsOneWidget);
      },
    );
  });
}
