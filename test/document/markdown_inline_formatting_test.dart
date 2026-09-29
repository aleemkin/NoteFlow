import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/domain/models.dart';
import 'package:noteflow/features/document/parsing/markdown_adapter.dart';
import 'package:noteflow/features/render/blocks/blockquote_renderer.dart';
import 'package:noteflow/features/render/blocks/heading_block_renderer.dart';
import 'package:noteflow/features/render/blocks/inline_content_renderer.dart';
import 'package:noteflow/features/render/blocks/list_item_renderer.dart';
import 'package:noteflow/features/render/blocks/paragraph_block_renderer.dart';
import 'package:noteflow/features/render/blocks/table_block_renderer.dart';

void main() {
  group('MarkdownAdapter Inline Parsing', () {
    test('parses bold tokens (asterisks, underscores, b tags, strong tags)', () {
      final nodes1 = MarkdownAdapter.parseInline('**bold asterisk**');
      expect(nodes1.length, 1);
      expect(nodes1.first, isA<InlineStrong>());
      expect(nodes1.first.plainText, 'bold asterisk');

      final nodes2 = MarkdownAdapter.parseInline('__bold underscore__');
      expect(nodes2.length, 1);
      expect(nodes2.first, isA<InlineStrong>());
      expect(nodes2.first.plainText, 'bold underscore');

      final nodes3 = MarkdownAdapter.parseInline('<b>bold html</b>');
      expect(nodes3.length, 1);
      expect(nodes3.first, isA<InlineStrong>());
      expect(nodes3.first.plainText, 'bold html');

      final nodes4 = MarkdownAdapter.parseInline('<strong>strong html</strong>');
      expect(nodes4.length, 1);
      expect(nodes4.first, isA<InlineStrong>());
      expect(nodes4.first.plainText, 'strong html');
    });

    test('parses italic tokens (asterisks, underscores, i tags, em tags)', () {
      final nodes1 = MarkdownAdapter.parseInline('*italic asterisk*');
      expect(nodes1.length, 1);
      expect(nodes1.first, isA<InlineEmphasis>());
      expect(nodes1.first.plainText, 'italic asterisk');

      final nodes2 = MarkdownAdapter.parseInline('_italic underscore_');
      expect(nodes2.length, 1);
      expect(nodes2.first, isA<InlineEmphasis>());
      expect(nodes2.first.plainText, 'italic underscore');

      final nodes3 = MarkdownAdapter.parseInline('<i>italic html</i>');
      expect(nodes3.length, 1);
      expect(nodes3.first, isA<InlineEmphasis>());
      expect(nodes3.first.plainText, 'italic html');

      final nodes4 = MarkdownAdapter.parseInline('<em>em html</em>');
      expect(nodes4.length, 1);
      expect(nodes4.first, isA<InlineEmphasis>());
      expect(nodes4.first.plainText, 'em html');
    });

    test('parses bold italic combinations', () {
      final nodes1 = MarkdownAdapter.parseInline('***bold italic***');
      expect(nodes1.length, 1);
      expect(nodes1.first, isA<InlineEmphasis>());
      final emChild = (nodes1.first as InlineEmphasis).children.first;
      expect(emChild, isA<InlineStrong>());
      expect(emChild.plainText, 'bold italic');

      final nodes2 = MarkdownAdapter.parseInline('<b><i>html bold italic</i></b>');
      expect(nodes2.length, 1);
      expect(nodes2.first, isA<InlineStrong>());
      final strongChild = (nodes2.first as InlineStrong).children.first;
      expect(strongChild, isA<InlineEmphasis>());
      expect(strongChild.plainText, 'html bold italic');
    });

    test('parses strikethrough tokens (~~, ~, s, del, strike)', () {
      for (final text in [
        '~~double tilde~~',
        '~single tilde~',
        '<s>s tag</s>',
        '<del>del tag</del>',
        '<strike>strike tag</strike>',
      ]) {
        final nodes = MarkdownAdapter.parseInline(text);
        expect(
          nodes.any((n) => n is InlineStrikethrough),
          isTrue,
          reason: 'Failed for: $text',
        );
      }
    });

    test('parses underline tokens (++, u, ins)', () {
      for (final text in ['++plus underline++', '<u>u tag</u>', '<ins>ins tag</ins>']) {
        final nodes = MarkdownAdapter.parseInline(text);
        expect(
          nodes.any((n) => n is InlineUnderline),
          isTrue,
          reason: 'Failed for: $text',
        );
      }
    });

    test('parses highlight tokens (==, mark)', () {
      for (final text in ['==highlight==', '<mark>mark tag</mark>']) {
        final nodes = MarkdownAdapter.parseInline(text);
        expect(
          nodes.any((n) => n is InlineMarkSpan && n.markType == 'highlight'),
          isTrue,
          reason: 'Failed for: $text',
        );
      }
    });

    test('parses code and kbd tokens (`code`, <code>code</code>, <kbd>key</kbd>)', () {
      for (final text in ['`code tick`', '<code>code tag</code>', '<kbd>Enter</kbd>']) {
        final nodes = MarkdownAdapter.parseInline(text);
        expect(
          nodes.any((n) => n is InlineCode),
          isTrue,
          reason: 'Failed for: $text',
        );
      }
    });

    test('gracefully handles non-formatting HTML tags and comparisons without infinite loops', () {
      final samples = [
        '<kbd>Enter</kbd> commits, <kbd>Esc</kbd> cancels',
        '<div>div tag</div>',
        '<span>span tag</span>',
        '<unknown>unknown tag</unknown>',
        '<custom-elem attr="val">content</custom-elem>',
        '<p>paragraph</p>',
        '<script>alert(1)</script>',
        'unclosed <b tag without close',
        'math: a < b and c > d',
      ];
      for (final s in samples) {
        final nodes = MarkdownAdapter.parseInline(s);
        expect(nodes, isNotEmpty, reason: 'Failed for: $s');
      }
    });

    test('parses line breaks (<br>, <br/>, double space newline, backslash newline)', () {
      final br1 = MarkdownAdapter.parseInline('line 1<br>line 2');
      expect(br1.any((n) => n is InlineLineBreak), isTrue);

      final br2 = MarkdownAdapter.parseInline('line 1<br/>line 2');
      expect(br2.any((n) => n is InlineLineBreak), isTrue);

      final br3 = MarkdownAdapter.parseInline('line 1  \nline 2');
      expect(br3.any((n) => n is InlineLineBreak), isTrue);

      final br4 = MarkdownAdapter.parseInline('line 1\\\nline 2');
      expect(br4.any((n) => n is InlineLineBreak), isTrue);
    });

    test('parses nested tokens with complex combinations', () {
      final nodes = MarkdownAdapter.parseInline(
        'Start **bold with *italic* and ==highlight== and <u>underline</u>** end',
      );
      expect(nodes.first.plainText, 'Start ');
      final strong = nodes.whereType<InlineStrong>().first;
      expect(strong.children.any((c) => c is InlineEmphasis), isTrue);
      expect(strong.children.any((c) => c is InlineMarkSpan), isTrue);
      expect(strong.children.any((c) => c is InlineUnderline), isTrue);
    });
  });

  group('InlineContentRenderer Typography & Weight Calculations', () {
    test('strong bumps weight appropriately based on context', () {
      const baseNormal = TextStyle(fontWeight: FontWeight.w400, color: AppColors.textSecondary);
      final spanNormal = InlineContentRenderer.buildSpan(
        const InlineStrong([InlineText('bold')]),
        baseNormal,
      );
      expect(spanNormal.style?.fontWeight, FontWeight.w700);
      expect(spanNormal.style?.color, AppColors.textSecondary); // Preserves parent color

      const baseH1 = TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary);
      final spanH1 = InlineContentRenderer.buildSpan(
        const InlineStrong([InlineText('bold H1')]),
        baseH1,
      );
      expect(spanH1.style?.fontWeight, FontWeight.w900); // Stand out against w800

      const baseH2 = TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary);
      final spanH2 = InlineContentRenderer.buildSpan(
        const InlineStrong([InlineText('bold H2')]),
        baseH2,
      );
      expect(spanH2.style?.fontWeight, FontWeight.w900); // Stand out against w700
    });

    test('emphasis inverts fontStyle when already inside italic context', () {
      const baseItalic = TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary);
      final spanItalic = InlineContentRenderer.buildSpan(
        const InlineEmphasis([InlineText('reverse italic')]),
        baseItalic,
      );
      expect(spanItalic.style?.fontStyle, FontStyle.normal);
      expect(spanItalic.style?.fontWeight, FontWeight.w600);
      expect(spanItalic.style?.color, AppColors.textSecondary);
    });

    test('underline and strikethrough decorations combine', () {
      const base = TextStyle(color: AppColors.textPrimary);
      final underline = InlineContentRenderer.buildSpan(
        const InlineUnderline([
          InlineStrikethrough([InlineText('struck and underlined')]),
        ]),
        base,
      );
      expect(underline.style?.decoration, TextDecoration.underline);
      final inner = (underline as TextSpan).children?.first as TextSpan;
      expect(inner.style?.decoration?.contains(TextDecoration.underline), isTrue);
      expect(inner.style?.decoration?.contains(TextDecoration.lineThrough), isTrue);
    });

    test('highlight uses warm fluorescent amber/yellow tint', () {
      const base = TextStyle(color: AppColors.textPrimary);
      final span = InlineContentRenderer.buildSpan(
        const InlineMarkSpan(id: '', markType: 'highlight', children: [InlineText('hi')]),
        base,
      );
      expect(span.style?.backgroundColor, const Color(0xFFF9D423).withValues(alpha: 0.28));
    });

    test('line break produces newline TextSpan', () {
      const base = TextStyle(color: AppColors.textPrimary);
      final span = InlineContentRenderer.buildSpan(const InlineLineBreak(), base);
      expect(span, isA<TextSpan>());
      expect((span as TextSpan).text, '\n');
    });
  });

  group('Markdown Block Renderers Widget Tests', () {
    testWidgets('TableBlockRenderer renders rich inline markdown in headers and cells', (tester) async {
      final table = TableBlock(
        id: 'table_1',
        headers: ['**Bold Header**', '*Italic Header*'],
        alignments: [TableColumnAlign.left, TableColumnAlign.center],
        rows: [
          ['==Highlight== and ~~strike~~', '<u>Underline</u> and `Code`'],
          ['<b>HTML Bold</b>', '<i>HTML Italic</i>'],
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TableBlockRenderer(table: table),
          ),
        ),
      );

      expect(find.textContaining('Bold Header'), findsOneWidget);
      expect(find.textContaining('Italic Header'), findsOneWidget);
      expect(find.textContaining('Highlight'), findsOneWidget);
      expect(find.textContaining('Underline'), findsOneWidget);
      expect(find.textContaining('HTML Bold'), findsOneWidget);
      expect(find.textContaining('HTML Italic'), findsOneWidget);

      // Verify rich text spans exist in the widget tree
      final richTexts = tester.widgetList<RichText>(find.byType(RichText)).toList();
      expect(richTexts.isNotEmpty, isTrue);

      final hasStrong = richTexts.any(
        (rt) => rt.text.toPlainText().contains('Bold Header'),
      );
      expect(hasStrong, isTrue);
    });

    testWidgets('HeadingBlockRenderer renders inline markdown without pre-parsed AST', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeadingBlockRenderer(
              text: 'Title with **bold** and *italic*',
              level: 1,
            ),
          ),
        ),
      );

      expect(find.textContaining('Title with bold and italic'), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Title with bold and italic');
    });

    testWidgets('ParagraphBlockRenderer renders inline markdown without pre-parsed AST', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ParagraphBlockRenderer(
              text: 'Paragraph with ==highlight== and <u>underline</u> and ~~strike~~',
            ),
          ),
        ),
      );

      expect(find.textContaining('Paragraph with highlight and underline and strike'), findsOneWidget);
    });

    testWidgets('BlockquoteRenderer renders inline markdown without pre-parsed AST', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlockquoteRenderer(
              text: 'Quoted wisdom with **bold** and *emphasis*',
            ),
          ),
        ),
      );

      expect(find.textContaining('Quoted wisdom with bold and emphasis'), findsOneWidget);
    });

    testWidgets('ListItemRenderer renders inline markdown without pre-parsed AST', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListItemRenderer(
              text: 'Task with **bold** item',
              isTask: true,
            ),
          ),
        ),
      );

      expect(find.textContaining('Task with bold item'), findsOneWidget);
    });
  });
}
