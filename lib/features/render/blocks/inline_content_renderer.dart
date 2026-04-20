import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/domain/models.dart';

/// Utility for converting [InlineContent] AST nodes into Flutter [InlineSpan]s with rich styling.
class InlineContentRenderer {
  const InlineContentRenderer._();

  static InlineSpan buildSpan(InlineNode node, TextStyle baseStyle) {
    if (node is InlineText) {
      return TextSpan(text: node.text, style: baseStyle);
    }
    if (node is InlineStrong) {
      final strongStyle = baseStyle.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );
      return TextSpan(
        style: strongStyle,
        children: node.children.map((c) => buildSpan(c, strongStyle)).toList(),
      );
    }
    if (node is InlineEmphasis) {
      final emStyle = baseStyle.copyWith(
        fontStyle: FontStyle.italic,
        color: AppColors.textPrimary,
      );
      return TextSpan(
        style: emStyle,
        children: node.children.map((c) => buildSpan(c, emStyle)).toList(),
      );
    }
    if (node is InlineCode) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Text(
            node.code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    if (node is InlineLink) {
      final linkStyle = baseStyle.copyWith(
        color: AppColors.primary,
        decoration: TextDecoration.underline,
      );
      return TextSpan(
        style: linkStyle,
        children: node.children.map((c) => buildSpan(c, linkStyle)).toList(),
      );
    }
    if (node is InlineStrikethrough) {
      final strikeStyle = baseStyle.copyWith(
        decoration: TextDecoration.lineThrough,
        color: AppColors.textMuted,
      );
      return TextSpan(
        style: strikeStyle,
        children: node.children.map((c) => buildSpan(c, strikeStyle)).toList(),
      );
    }
    if (node is InlineImage) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.image_outlined,
                size: 13,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                node.alt?.isNotEmpty == true ? node.alt! : 'image',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (node is InlineMarkSpan) {
      final markStyle = baseStyle.copyWith(
        backgroundColor: AppColors.primary.withValues(alpha: 0.18),
      );
      return TextSpan(
        style: markStyle,
        children: node.children.map((c) => buildSpan(c, markStyle)).toList(),
      );
    }
    return TextSpan(text: node.plainText, style: baseStyle);
  }

  static List<InlineSpan> buildSpans(
    InlineContent content,
    TextStyle baseStyle,
  ) {
    return content.map((node) => buildSpan(node, baseStyle)).toList();
  }
}
