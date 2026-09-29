import 'package:markdown/markdown.dart' as md;

import 'package:noteflow/features/document/domain/inline_content.dart';

class _HighlightSyntax extends md.DelimiterSyntax {
  _HighlightSyntax()
      : super(
          '=+',
          requiresDelimiterRun: true,
          allowIntraWord: true,
          startCharacter: 0x3d, // '='
          tags: [md.DelimiterTag('mark', 2)],
        );
}

class _UnderlineSyntax extends md.DelimiterSyntax {
  _UnderlineSyntax()
      : super(
          r'\++',
          requiresDelimiterRun: true,
          allowIntraWord: true,
          startCharacter: 0x2b, // '+'
          tags: [md.DelimiterTag('u', 2)],
        );
}

class _HtmlBreakSyntax extends md.InlineSyntax {
  _HtmlBreakSyntax()
      : super(r'<br\s*/?>', startCharacter: 0x3c, caseSensitive: false);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.empty('br'));
    return true;
  }
}

class _HtmlFormatTagSyntax extends md.InlineSyntax {
  _HtmlFormatTagSyntax()
      : super(
          r'<(b|strong|i|em|u|ins|mark|s|del|strike|code|kbd)(?:\s+[^>]*)?>([\s\S]*?)<\/\1>',
          startCharacter: 0x3c,
          caseSensitive: false,
        );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final tag = match.group(1)!.toLowerCase();
    final content = match.group(2)!;
    final children = parser.document.parseInline(content);
    parser.addNode(md.Element(tag, children));
    return true;
  }
}

/// Converts the `markdown` package AST into our [InlineNode] model.
class MarkdownAdapter {
  MarkdownAdapter._();

  static List<md.InlineSyntax> _createSyntaxes() => [
        _HtmlBreakSyntax(),
        _HtmlFormatTagSyntax(),
        _HighlightSyntax(),
        _UnderlineSyntax(),
      ];

  /// Parse inline Markdown content into [InlineNode] list.
  static List<InlineNode> parseInline(String text) {
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      inlineSyntaxes: _createSyntaxes(),
      encodeHtml: false,
    );
    final nodes = document.parseInline(text);
    return _convertNodes(nodes);
  }

  static List<InlineNode> _convertNodes(List<md.Node> nodes) {
    final result = <InlineNode>[];
    for (final node in nodes) {
      result.add(_convertNode(node));
    }
    return result;
  }

  static InlineNode _convertNode(md.Node node) {
    if (node is md.Text) {
      return InlineText(node.textContent);
    }
    if (node is md.Element) {
      return switch (node.tag) {
        'em' || 'i' => InlineEmphasis(_convertNodes(node.children ?? [])),
        'strong' || 'b' => InlineStrong(_convertNodes(node.children ?? [])),
        'del' || 's' || 'strike' =>
          InlineStrikethrough(_convertNodes(node.children ?? [])),
        'u' || 'ins' => InlineUnderline(_convertNodes(node.children ?? [])),
        'mark' => InlineMarkSpan(
            id: '',
            markType: 'highlight',
            children: _convertNodes(node.children ?? []),
          ),
        'br' => const InlineLineBreak(),
        'code' || 'kbd' => InlineCode(node.textContent),
        'a' => InlineLink(
            destination: node.attributes['href'] ?? '',
            title: node.attributes['title'],
            children: _convertNodes(node.children ?? []),
          ),
        'img' => InlineImage(
            destination: node.attributes['src'] ?? '',
            alt: node.attributes['alt'],
            title: node.attributes['title'],
          ),
        _ => InlineText(node.textContent),
      };
    }
    return InlineText(node.textContent);
  }
}
