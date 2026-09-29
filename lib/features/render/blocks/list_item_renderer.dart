import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/domain/models.dart';
import 'package:noteflow/features/document/parsing/markdown_adapter.dart';
import 'inline_content_renderer.dart';

/// Renders a list item (bullet, ordered number, or interactive/styled task checkbox) with rich inline styling.
class ListItemRenderer extends StatelessWidget {
  final InlineContent? inlineContent;
  final String text;
  final String? listNumber;
  final bool isTask;
  final bool isChecked;

  const ListItemRenderer({
    super.key,
    this.inlineContent,
    required this.text,
    this.listNumber,
    this.isTask = false,
    this.isChecked = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: 15.0,
      height: 1.6,
      color: isChecked ? AppColors.textMuted : AppColors.textPrimary,
      decoration: isChecked ? TextDecoration.lineThrough : null,
      letterSpacing: 0.1,
    );

    Widget leading;
    if (isTask) {
      leading = Padding(
        padding: const EdgeInsets.only(top: 2.0, right: 8.0),
        child: Icon(
          isChecked
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          size: 18,
          color: isChecked ? AppColors.secondary : AppColors.textTertiary,
        ),
      );
    } else if (listNumber != null) {
      leading = Padding(
        padding: const EdgeInsets.only(top: 1.0, right: 8.0),
        child: SizedBox(
          width: 22,
          child: Text(
            '$listNumber.',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.6,
            ),
          ),
        ),
      );
    } else {
      leading = const Padding(
        padding: EdgeInsets.only(top: 9, right: 10),
        child: Icon(Icons.circle, size: 5, color: AppColors.primary),
      );
    }

    final nodes = (inlineContent != null && inlineContent!.isNotEmpty)
        ? inlineContent!
        : MarkdownAdapter.parseInline(text);

    final contentWidget = Text.rich(
      TextSpan(
        style: baseStyle,
        children: InlineContentRenderer.buildSpans(
          nodes,
          baseStyle,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          Expanded(child: contentWidget),
        ],
      ),
    );
  }
}
