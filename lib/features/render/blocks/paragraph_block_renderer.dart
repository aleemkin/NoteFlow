import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/domain/models.dart';
import 'package:noteflow/features/document/parsing/markdown_adapter.dart';
import 'inline_content_renderer.dart';

/// Renders a paragraph block in readable high-contrast typography with rich inline styling.
class ParagraphBlockRenderer extends StatelessWidget {
  final InlineContent? inlineContent;
  final String text;
  final bool isMarked;
  final String? markType;
  final bool highlightMark;

  const ParagraphBlockRenderer({
    super.key,
    this.inlineContent,
    required this.text,
    this.isMarked = false,
    this.markType,
    this.highlightMark = false,
  });

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 15.0,
      height: 1.65,
      color: AppColors.textPrimary,
      letterSpacing: 0.1,
    );

    final nodes = (inlineContent != null && inlineContent!.isNotEmpty)
        ? inlineContent!
        : MarkdownAdapter.parseInline(text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children: InlineContentRenderer.buildSpans(
            nodes,
            baseStyle,
          ),
        ),
      ),
    );
  }
}
