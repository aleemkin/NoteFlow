import 'package:noteflow/core/utils/typedefs.dart';

/// Inline content nodes representing parsed Markdown inline elements.
sealed class InlineNode {
  const InlineNode();

  /// Recursively extracts all plain text from this node tree.
  String get plainText;
}

final class InlineText extends InlineNode {
  final String text;
  const InlineText(this.text);

  @override
  String get plainText => text;
}

final class InlineEmphasis extends InlineNode {
  final List<InlineNode> children;
  const InlineEmphasis(this.children);

  @override
  String get plainText => children.map((n) => n.plainText).join();
}

final class InlineStrong extends InlineNode {
  final List<InlineNode> children;
  const InlineStrong(this.children);

  @override
  String get plainText => children.map((n) => n.plainText).join();
}

final class InlineCode extends InlineNode {
  final String code;
  const InlineCode(this.code);

  @override
  String get plainText => code;
}

final class InlineLink extends InlineNode {
  final String destination;
  final String? title;
  final List<InlineNode> children;
  const InlineLink({
    required this.destination,
    this.title,
    required this.children,
  });

  @override
  String get plainText => children.map((n) => n.plainText).join();
}

final class InlineStrikethrough extends InlineNode {
  final List<InlineNode> children;
  const InlineStrikethrough(this.children);

  @override
  String get plainText => children.map((n) => n.plainText).join();
}

final class InlineUnderline extends InlineNode {
  final List<InlineNode> children;
  const InlineUnderline(this.children);

  @override
  String get plainText => children.map((n) => n.plainText).join();
}

final class InlineLineBreak extends InlineNode {
  const InlineLineBreak();

  @override
  String get plainText => '\n';
}

final class InlineImage extends InlineNode {
  final String destination;
  final String? alt;
  final String? title;
  const InlineImage({required this.destination, this.alt, this.title});

  @override
  String get plainText => alt ?? destination;
}

final class InlineMarkSpan extends InlineNode {
  final MarkId id;
  final String markType;
  final List<InlineNode> children;
  const InlineMarkSpan({
    required this.id,
    required this.markType,
    required this.children,
  });

  @override
  String get plainText => children.map((n) => n.plainText).join();
}

/// Convenience typedef and extension for inline content lists.
typedef InlineContent = List<InlineNode>;

extension InlineContentExt on InlineContent {
  String get plainText => map((n) => n.plainText).join();
}
