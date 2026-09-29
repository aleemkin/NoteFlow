import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/domain/models.dart';
import 'package:noteflow/features/document/parsing/markdown_adapter.dart';
import 'inline_content_renderer.dart';

/// Renders a blockquote with subtle accent border and rich inline styling.
class BlockquoteRenderer extends StatelessWidget {
  final InlineContent? inlineContent;
  final String text;

  const BlockquoteRenderer({super.key, this.inlineContent, required this.text});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 14.5,
      height: 1.6,
      fontStyle: FontStyle.italic,
      color: AppColors.textSecondary,
    );

    final nodes = (inlineContent != null && inlineContent!.isNotEmpty)
        ? inlineContent!
        : MarkdownAdapter.parseInline(text);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.only(left: 14, top: 6, bottom: 6, right: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3.0),
        ),
      ),
      child: Text.rich(
        TextSpan(
          style: style,
          children: InlineContentRenderer.buildSpans(
            nodes,
            style,
          ),
        ),
      ),
    );
  }
}
