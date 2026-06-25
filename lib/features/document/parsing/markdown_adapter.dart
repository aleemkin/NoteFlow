import 'package:markdown/markdown.dart' as md;

import 'package:noteflow/features/document/domain/inline_content.dart';

/// Converts the `markdown` package AST into our [InlineNode] model.
class MarkdownAdapter {
  MarkdownAdapter._();

  /// Parse inline Markdown content into [InlineNode] list.
  static List<InlineNode> parseInline(String text) {
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
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
        'em' => InlineEmphasis(_convertNodes(node.children ?? [])),
        'strong' => InlineStrong(_convertNodes(node.children ?? [])),
        'del' || 's' => InlineStrikethrough(_convertNodes(node.children ?? [])),
        'code' => InlineCode(node.textContent),
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
