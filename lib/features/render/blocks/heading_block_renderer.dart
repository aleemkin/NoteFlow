import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/domain/models.dart';
import 'package:noteflow/features/document/parsing/markdown_adapter.dart';
import 'inline_content_renderer.dart';

/// Renders a heading block (H1-H6) with crisp typography hierarchy and inline styling.
class HeadingBlockRenderer extends StatelessWidget {
  final InlineContent? inlineContent;
  final String text;
  final int level;

  const HeadingBlockRenderer({
    super.key,
    this.inlineContent,
    required this.text,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    const sizes = [26.0, 21.0, 17.5, 15.5, 14.0, 13.0];
    const weights = [
      FontWeight.w800,
      FontWeight.w700,
      FontWeight.w700,
      FontWeight.w600,
      FontWeight.w600,
      FontWeight.w600,
    ];
    final idx = (level - 1).clamp(0, 5);

    final style = TextStyle(
      fontSize: sizes[idx],
      fontWeight: weights[idx],
      height: 1.3,
      color: AppColors.textPrimary,
      letterSpacing: level == 1 ? -0.5 : -0.2,
    );

    final nodes = (inlineContent != null && inlineContent!.isNotEmpty)
        ? inlineContent!
        : MarkdownAdapter.parseInline(text);

    return Padding(
      padding: EdgeInsets.only(top: level <= 2 ? 24.0 : 16.0, bottom: 8.0),
      child: Text.rich(
        TextSpan(
          style: style,
          children: InlineContentRenderer.buildSpans(nodes, style),
        ),
      ),
    );
  }
}
