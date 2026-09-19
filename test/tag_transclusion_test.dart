import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noteflow/features/document/document.dart';
import 'package:noteflow/features/knowledge/data/link_resolver.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/features/render/blocks/block_renderer.dart';
import 'package:noteflow/features/render/surfaces/continuous_folder_surface.dart';
import 'package:noteflow/features/render/surfaces/document_surface.dart';

void main() {
  group('Tag Syntax Scanner & Parser Tests', () {
    test(
      'BlockScanner scans @@view with same-doc mark reference (#mark_1)',
      () {
        const text = '''# Main Note

Here is a transcluded block:
@@view #auth-decision
''';

        final blocks = BlockScanner.scan(text);
        final viewBlocks = blocks
            .where((b) => b.type == ScannedBlockType.viewDirective)
            .toList();

        expect(viewBlocks.length, 1);
        expect(viewBlocks.first.attributes['ref'], 'auth-decision');
        expect(viewBlocks.first.attributes['docPath'], isNull);
      },
    );

    test(
      'BlockScanner scans @@view with cross-doc path reference (notes/auth.md#decision)',
      () {
        const text = '''# Main Note

@@view notes/auth.md#decision
''';

        final blocks = BlockScanner.scan(text);
        final viewBlocks = blocks
            .where((b) => b.type == ScannedBlockType.viewDirective)
            .toList();

        expect(viewBlocks.length, 1);
        expect(viewBlocks.first.attributes['docPath'], 'notes/auth.md');
        expect(viewBlocks.first.attributes['ref'], 'decision');
      },
    );

    test('BlockScanner scans single-line shorthand @@imp> line content', () {
      const text = '''# Note Title

@@imp> This single line is critical information.
''';

      final blocks = BlockScanner.scan(text);
      final markBlocks = blocks
          .where((b) => b.type == ScannedBlockType.markDirective)
          .toList();

      expect(markBlocks.length, 1);
      expect(markBlocks.first.attributes['markType'], 'imp');
      expect(
        markBlocks.first.content,
        'This single line is critical information.',
      );
    });

    test('BlockScanner parses #id in @@tag #my_id', () {
      const text = '''@@review #code-review-42
Needs performance optimization before merging.
@@''';

      final blocks = BlockScanner.scan(text);
      expect(blocks.length, 1);
      expect(blocks.first.attributes['markType'], 'review');
      expect(blocks.first.attributes['id'], 'code-review-42');
      expect(
        blocks.first.content,
        'Needs performance optimization before merging.',
      );
    });

    test('DocumentParser parses @@view directive into ViewBlock AST', () {
      const md = '''# Notes

@@view notes/architecture.md#layer-arch
''';
      final bytes = utf8.encode(md);
      final doc = DocumentParser.parse(
        bytes: bytes,
        uri: const VaultUri(path: 'index.md'),
      );

      final viewBlocks = doc.blocks.whereType<ViewBlock>().toList();
      expect(viewBlocks.length, 1);
      expect(viewBlocks.first.markRef, 'layer-arch');
      expect(viewBlocks.first.docPath, 'notes/architecture.md');
    });
  });

  group('LinkResolver Cross-Vault Mark Resolution Tests', () {
    final doc1 = DocumentParser.parse(
      bytes: utf8.encode('''# Doc 1

@@imp #key-point-1
This is a critical takeaway in Doc 1.
@@
'''),
      uri: const VaultUri(path: 'folder/doc1.md'),
    );

    final doc2 = DocumentParser.parse(
      bytes: utf8.encode('''# Doc 2

@@info #reference-note
API documentation reference.
@@
'''),
      uri: const VaultUri(path: 'folder/doc2.md'),
    );

    test('LinkResolver resolves same-document mark', () {
      final res = LinkResolver.resolveMarkRef(
        markRef: 'key-point-1',
        currentDoc: doc1,
        allDocs: [doc1, doc2],
      );

      expect(res, isNotNull);
      expect(res!.sourceDoc.uri.path, 'folder/doc1.md');
      expect(res.mark.id, 'key-point-1');
      expect(res.mark.type, 'imp');
    });

    test('LinkResolver resolves cross-document mark by path and ID', () {
      final res = LinkResolver.resolveMarkRef(
        markRef: 'reference-note',
        docPath: 'folder/doc2.md',
        currentDoc: doc1,
        allDocs: [doc1, doc2],
      );

      expect(res, isNotNull);
      expect(res!.sourceDoc.uri.path, 'folder/doc2.md');
      expect(res.mark.id, 'reference-note');
      expect(res.mark.type, 'info');
    });

    test('LinkResolver returns null for non-existent mark', () {
      final res = LinkResolver.resolveMarkRef(
        markRef: 'non-existent-mark',
        currentDoc: doc1,
        allDocs: [doc1, doc2],
      );

      expect(res, isNull);
    });
  });

  group('Viewer Transclusion Preview Rendering Tests', () {
    testWidgets(
      'ViewBlockRenderer renders provenance header, badge, and content',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ViewBlockRenderer(
                markRef: 'perf-fix',
                docPath: 'notes/perf.md',
                markType: 'imp',
                resolvedContent: const Text('Cached results in memory.'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('notes/perf.md#perf-fix'), findsOneWidget);
        expect(find.text('IMP'), findsOneWidget);
        expect(find.text('Cached results in memory.'), findsOneWidget);
      },
    );

    testWidgets('ViewBlockRenderer renders not-found message when unresolved', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ViewBlockRenderer(markRef: 'missing-id')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('#missing-id'), findsOneWidget);
      expect(
        find.text('Referenced mark #missing-id not found'),
        findsOneWidget,
      );
    });

    testWidgets(
      'ContinuousFolderSurface previews transcluded block from another note',
      (tester) async {
        final docA = DocumentParser.parse(
          bytes: utf8.encode('''# Architecture

@@imp #core-rule
Never bypass the repository layer.
@@
'''),
          uri: const VaultUri(path: 'folder/arch.md'),
        );

        final docB = DocumentParser.parse(
          bytes: utf8.encode('''# Implementation Guide

As established in architecture:
@@view folder/arch.md#core-rule
'''),
          uri: const VaultUri(path: 'folder/guide.md'),
        );

        final controller = ScrollController();
        final blockKeys = <String, GlobalKey>{
          for (final b in docA.blocks) b.id: GlobalKey(),
          for (final b in docB.blocks) b.id: GlobalKey(),
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ContinuousFolderSurface(
                documents: [docA, docB],
                scrollController: controller,
                blockKeys: blockKeys,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify the transcluded block previews the content from arch.md inside guide.md!
        expect(
          find.text('Never bypass the repository layer.'),
          findsNWidgets(2),
        ); // Once in arch.md, once previewed in guide.md
        expect(find.text('folder/arch.md#core-rule'), findsOneWidget);
        expect(
          find.text('IMP'),
          findsNWidgets(1),
        ); // The badge in the transclusion container
      },
    );
  });

  group('Gutter Strips & Tag Nesting Tests', () {
    testWidgets(
      'GutterBlockWrapper renders colored vertical strips with 20-30% opacity',
      (tester) async {
        final doc = DocumentParser.parse(
          bytes: utf8.encode('@@imp #m1\nBlock Content\n@@'),
          uri: const VaultUri(path: 'test.md'),
        );
        final block = doc.blocks.first;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GutterBlockWrapper(
                block: block,
                child: const Text('Block Content'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Tag: @@imp'), findsOneWidget);
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byTooltip('Tag: @@imp'),
            matching: find.byType(Container),
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, isNotNull);
        // Verify 20-30% opacity
        expect(decoration.color!.a, inInclusiveRange(0.20, 0.30));
      },
    );

    testWidgets(
      'GutterBlockWrapper suppresses strip matching activeFilterTag in tagged views',
      (tester) async {
        final doc = DocumentParser.parse(
          bytes: utf8.encode('@@imp #m1\nBlock Content\n@@'),
          uri: const VaultUri(path: 'test.md'),
        );
        final block = doc.blocks.first;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GutterBlockWrapper(
                block: block,
                activeFilterTag: 'imp',
                child: const Text('Block Content'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // In imp tagged view, the imp strip is suppressed to avoid a line across the whole screen
        expect(find.byTooltip('Tag: @@imp'), findsNothing);
      },
    );

    testWidgets(
      'GutterBlockWrapper renders side-by-side strips for blocks with multiple marks',
      (tester) async {
        final doc = DocumentParser.parse(
          bytes: utf8.encode(
            '@@imp #m1\n@@info #m2\nMulti-marked Block Content\n@@\n@@',
          ),
          uri: const VaultUri(path: 'test.md'),
        );
        final block = doc.blocks.first;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GutterBlockWrapper(
                block: block,
                child: const Text('Multi-marked Block Content'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Tag: @@imp'), findsOneWidget);
        expect(find.byTooltip('Tag: @@info'), findsOneWidget);
      },
    );

    test(
      'Nested directives parse correctly with both outer and inner marks attached',
      () {
        const source = '''# Title
@@imp #outer_imp
Outer text

@@info #inner_info
Nested info text
@@

More outer text
@@
''';

        final doc = DocumentParser.parse(
          bytes: utf8.encode(source),
          uri: const VaultUri(path: 'test.md'),
        );

        final blocks = doc.blocks.whereType<TextBlock>().toList();
        expect(blocks.length, greaterThanOrEqualTo(3));

        // Heading and outer text have only imp mark
        final outerPara = blocks.firstWhere(
          (b) => b.inlineContent.plainText.contains('Outer text'),
        );
        expect(outerPara.marks.map((m) => m.type), contains('imp'));
        expect(outerPara.marks.map((m) => m.type), isNot(contains('info')));

        // Nested info text has BOTH info and imp marks attached!
        final nestedPara = blocks.firstWhere(
          (b) => b.inlineContent.plainText.contains('Nested info text'),
        );
        expect(
          nestedPara.marks.map((m) => m.type),
          containsAll(['info', 'imp']),
        );
      },
    );

    test(
      'MarkdownTagger.tagText wraps other tags as atomic units without destroying them',
      () {
        const source = '''# Architecture
@@info #arch_note
Repository layer is strictly decoupled.
@@
More architecture details.''';

        // User tags the whole source with imp
        final tagged = MarkdownTagger.tagText(source, source, 'imp');

        expect(tagged, contains('@@imp'));
        // The @@info directive must remain intact inside @@imp as an atomic unit
        expect(tagged, contains('@@info #arch_note'));
        expect(tagged, contains('Repository layer is strictly decoupled.'));
        expect(tagged, contains('More architecture details.'));
      },
    );

    test(
      'MarkdownTagger.removeTag removes only the targeted tag and preserves nested tags',
      () {
        const source = '''@@imp #imp_1
# Architecture
@@info #arch_note
Repository layer is strictly decoupled.
@@
More architecture details.
@@''';

        // Remove the outer imp tag
        final result = MarkdownTagger.removeTag(
          source,
          'Architecture',
          tagType: 'imp',
        );

        expect(result, isNot(contains('@@imp')));
        expect(result, contains('# Architecture'));
        // @@info must remain intact!
        expect(result, contains('@@info #arch_note'));
        expect(result, contains('Repository layer is strictly decoupled.'));
        expect(result, contains('More architecture details.'));
      },
    );

    testWidgets(
      'GutterBlockWrapper connects strips continuously across contiguous blocks under same tag',
      (tester) async {
        const mark = SemanticMark(
          id: 'm1',
          type: 'imp',
          sourceRange: SourceRange(
            startOffset: 0,
            endOffset: 0,
            startLine: 0,
            endLine: 0,
          ),
        );
        final block1 = TextBlock(
          id: 'b1',
          role: TextBlockRole.paragraph,
          inlineContent: const [],
          marks: [mark],
        );
        final block2 = TextBlock(
          id: 'b2',
          role: TextBlockRole.paragraph,
          inlineContent: const [],
          marks: [mark],
        );
        final block3 = TextBlock(
          id: 'b3',
          role: TextBlockRole.paragraph,
          inlineContent: const [],
          marks: [mark],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  GutterBlockWrapper(
                    block: block1,
                    nextBlock: block2,
                    child: const Text('P1'),
                  ),
                  GutterBlockWrapper(
                    block: block2,
                    prevBlock: block1,
                    nextBlock: block3,
                    child: const Text('P2'),
                  ),
                  GutterBlockWrapper(
                    block: block3,
                    prevBlock: block2,
                    child: const Text('P3'),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final containers = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(GutterBlockWrapper),
                matching: find.byType(Container),
              ),
            )
            .where(
              (c) =>
                  c.decoration is BoxDecoration &&
                  (c.decoration as BoxDecoration).color != null,
            )
            .toList();

        expect(containers.length, 3);
        // Block 1 (top of tag): rounded top, flat bottom, bottom margin 0
        final dec1 = containers[0].decoration as BoxDecoration;
        expect(
          dec1.borderRadius,
          const BorderRadius.only(
            topLeft: Radius.circular(1.5),
            topRight: Radius.circular(1.5),
          ),
        );
        expect((containers[0].margin as EdgeInsets).bottom, 0.0);

        // Block 2 (middle of tag): flat top, flat bottom, top margin 0, bottom margin 0
        final dec2 = containers[1].decoration as BoxDecoration;
        expect(dec2.borderRadius, const BorderRadius.only());
        expect((containers[1].margin as EdgeInsets).top, 0.0);
        expect((containers[1].margin as EdgeInsets).bottom, 0.0);

        // Block 3 (bottom of tag): flat top, rounded bottom, top margin 0
        final dec3 = containers[2].decoration as BoxDecoration;
        expect(
          dec3.borderRadius,
          const BorderRadius.only(
            bottomLeft: Radius.circular(1.5),
            bottomRight: Radius.circular(1.5),
          ),
        );
        expect((containers[2].margin as EdgeInsets).top, 0.0);
      },
    );

    testWidgets(
      'GutterBlockWrapper renders tagged DrawingBlockRenderer without layout errors',
      (tester) async {
        final doc = DocumentParser.parse(
          bytes: utf8.encode('''# Doc
@@imp #mark_draw
@@drawing ./diagram.excalidraw #d1 {minHeight=260}
@@
@@
'''),
          uri: const VaultUri(path: 'doc.md'),
        );

        final drawBlock = doc.blocks.whereType<DrawingBlock>().first;
        expect(drawBlock.marks, isNotEmpty);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GutterBlockWrapper(
                block: drawBlock,
                child: DrawingBlockRenderer(
                  drawingPath: drawBlock.drawingUri.path,
                  height: drawBlock.minHeight ?? 260,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DrawingBlockRenderer), findsOneWidget);
        expect(find.byTooltip('Tag: @@imp'), findsOneWidget);
        // Ensure no Flutter layout exceptions were thrown
        expect(tester.takeException(), isNull);
      },
    );

    test(
      'MarkdownTagger tags and untags a drawing directive preserving the drawing intact',
      () {
        const source = '''# Title

@@drawing ./my_diagram.excalidraw #draw_1 {minHeight=260}
@@

Some notes.''';

        // Tag drawing with imp
        final tagged = MarkdownTagger.tagText(
          source,
          'my_diagram.excalidraw',
          'imp',
        );
        expect(tagged, contains('@@imp'));
        expect(
          tagged,
          contains('@@drawing ./my_diagram.excalidraw #draw_1 {minHeight=260}'),
        );
        expect(tagged, contains('Some notes.'));

        // Remove tag from drawing
        final untagged = MarkdownTagger.removeTag(
          tagged,
          'my_diagram.excalidraw',
          tagType: 'imp',
        );
        expect(untagged, isNot(contains('@@imp')));
        expect(
          untagged,
          contains('@@drawing ./my_diagram.excalidraw #draw_1 {minHeight=260}'),
        );
        expect(untagged, contains('Some notes.'));
      },
    );

    test('DocumentParser parses directives closed with @@/imp and @/imp', () {
      final doc1 = DocumentParser.parse(
        bytes: utf8.encode('''@@imp #m1
Paragraph one
@@/imp
'''),
        uri: const VaultUri(path: 'doc1.md'),
      );
      expect(doc1.blocks.first.marks.map((m) => m.type), contains('imp'));

      final doc2 = DocumentParser.parse(
        bytes: utf8.encode('''@@info #m2
Paragraph two
@/info
'''),
        uri: const VaultUri(path: 'doc2.md'),
      );
      expect(doc2.blocks.first.marks.map((m) => m.type), contains('info'));
    });

    test(
      'DocumentParser parses nested directives with explicit HTML-style closers',
      () {
        final doc = DocumentParser.parse(
          bytes: utf8.encode('''@@imp #outer
# Outer Header
@@info #inner
Inner info block
@@/info
Outer trailer block
@@/imp
'''),
          uri: const VaultUri(path: 'doc.md'),
        );

        expect(doc.blocks.length, 3);
        // Block 1: Outer Header -> imp mark
        expect(doc.blocks[0].marks.map((m) => m.type), ['imp']);
        // Block 2: Inner info block -> both imp and info marks
        expect(
          doc.blocks[1].marks.map((m) => m.type),
          containsAll(['imp', 'info']),
        );
        // Block 3: Outer trailer block -> only imp mark
        expect(doc.blocks[2].marks.map((m) => m.type), ['imp']);
      },
    );

    test(
      'Auto-closing recovery: outer @@/imp auto-closes unclosed inner directive',
      () {
        final doc = DocumentParser.parse(
          bytes: utf8.encode('''@@imp #outer
Outer start
@@info #inner
Inner unclosed block
@@/imp
After outer text
'''),
          uri: const VaultUri(path: 'doc.md'),
        );

        expect(doc.blocks.length, 3);
        expect(doc.blocks[0].marks.map((m) => m.type), ['imp']);
        expect(
          doc.blocks[1].marks.map((m) => m.type),
          containsAll(['imp', 'info']),
        );
        // After outer text must NOT have imp or info
        expect(doc.blocks[2].marks, isEmpty);
      },
    );

    test('MarkdownTagger.tagText generates @@/tagType closer', () {
      const source = '''# Title

Important text to mark.

More text.''';

      final tagged = MarkdownTagger.tagText(
        source,
        'Important text to mark.',
        'imp',
      );
      expect(tagged, contains('@@imp'));
      expect(tagged, contains('@@/imp'));
    });

    test('MarkdownTagger.removeTag cleanly removes @@/tag and @/tag', () {
      const source1 = '''# Title

@@imp #m1
Paragraph inside imp
@@/imp

Footer.''';

      final cleaned1 = MarkdownTagger.removeTag(
        source1,
        'Paragraph inside imp',
        tagType: 'imp',
      );
      expect(cleaned1, isNot(contains('@@imp')));
      expect(cleaned1, isNot(contains('@@/imp')));
      expect(cleaned1, contains('Paragraph inside imp'));

      const source2 = '''# Title

@@info #m2
Paragraph inside info
@/info

Footer.''';

      final cleaned2 = MarkdownTagger.removeTag(
        source2,
        'Paragraph inside info',
        tagType: 'info',
      );
      expect(cleaned2, isNot(contains('@@info')));
      expect(cleaned2, isNot(contains('@/info')));
      expect(cleaned2, contains('Paragraph inside info'));
    });

    test(
      'DrawingBlock with @@/drawing and stray closers ignored in BlockScanner',
      () {
        final doc = DocumentParser.parse(
          bytes: utf8.encode('''@@drawing ./arch.excalidraw #d1 {minHeight=260}
@@/drawing

@@/stray
@/stray_info

Regular paragraph text.
'''),
          uri: const VaultUri(path: 'doc.md'),
        );

        expect(doc.blocks.any((b) => b is DrawingBlock), isTrue);
        final paraTexts = doc.blocks
            .whereType<TextBlock>()
            .map((b) => b.inlineContent.plainText)
            .toList();
        expect(paraTexts, contains('Regular paragraph text.'));
        expect(paraTexts.any((t) => t.contains('stray')), isFalse);
      },
    );

    test(
      'GutterLaneAllocator allocates stable Lane 0 to continuing parent tag and Lane 1 to nested tag',
      () {
        final doc = DocumentParser.parse(
          bytes: utf8.encode('''@@imp #outer
# Heading

@@info #inner
Nested paragraph
@@/info

Trailer paragraph
@@/imp
'''),
          uri: const VaultUri(path: 'doc.md'),
        );

        final lanes = GutterLaneAllocator.computeLanes(doc.blocks);

        // Block 0: Heading -> marks: [imp]
        expect(lanes[doc.blocks[0].id]!['outer'], 0);

        // Block 1: Nested paragraph -> marks: [imp, info]
        // imp MUST remain at Lane 0! info MUST be allocated Lane 1!
        expect(lanes[doc.blocks[1].id]!['outer'], 0);
        expect(lanes[doc.blocks[1].id]!['inner'], 1);

        // Block 2: Trailer paragraph -> marks: [imp]
        expect(lanes[doc.blocks[2].id]!['outer'], 0);
        expect(lanes[doc.blocks[2].id]!.containsKey('inner'), isFalse);
      },
    );

    testWidgets(
      'GutterBlockWrapper preserves horizontal alignment of outer tag when nested tag appears',
      (tester) async {
        final doc = DocumentParser.parse(
          bytes: utf8.encode('''@@imp #outer
# Heading

@@drawing ./diagram.excalidraw #d1 {minHeight=260}
@@/drawing

@@info #inner
Nested paragraph
@@/info
@@/imp
'''),
          uri: const VaultUri(path: 'doc.md'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DocumentSurface(document: doc)),
          ),
        );
        await tester.pumpAndSettle();

        // Find all tooltips for imp tag
        final impStrips = find.byTooltip('Tag: @@imp');
        expect(impStrips, findsNWidgets(3));

        // Get the RenderBox offsets for the 3 imp strips
        final offset1 = tester.getTopLeft(impStrips.at(0));
        final offset2 = tester.getTopLeft(impStrips.at(1));
        final offset3 = tester.getTopLeft(impStrips.at(2));

        // The x coordinate of all 3 imp strips must be EXACTLY IDENTICAL!
        expect(offset1.dx, offset2.dx);
        expect(offset2.dx, offset3.dx);

        // The info strip on the 3rd block must be to the right of the imp strip
        final infoStrip = find.byTooltip('Tag: @@info');
        expect(infoStrip, findsOneWidget);
        final infoOffset = tester.getTopLeft(infoStrip);
        expect(infoOffset.dx, greaterThan(offset3.dx));
      },
    );
  });
}
