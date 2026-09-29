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
      final baseWeight = baseStyle.fontWeight ?? FontWeight.normal;
      final strongWeight = switch (baseWeight) {
        FontWeight.w800 || FontWeight.w900 => FontWeight.w900,
        FontWeight.w700 => FontWeight.w900,
        FontWeight.w600 => FontWeight.w800,
        _ => FontWeight.w700,
      };
      final strongStyle = baseStyle.copyWith(fontWeight: strongWeight);
      return TextSpan(
        style: strongStyle,
        children: node.children.map((c) => buildSpan(c, strongStyle)).toList(),
      );
    }
    if (node is InlineEmphasis) {
      final isItalic = baseStyle.fontStyle == FontStyle.italic;
      final emStyle = baseStyle.copyWith(
        fontStyle: isItalic ? FontStyle.normal : FontStyle.italic,
        fontWeight: isItalic &&
                (baseStyle.fontWeight == null ||
                    baseStyle.fontWeight == FontWeight.normal)
            ? FontWeight.w600
            : null,
      );
      return TextSpan(
        style: emStyle,
        children: node.children.map((c) => buildSpan(c, emStyle)).toList(),
      );
    }
    if (node is InlineUnderline) {
      final decoration = baseStyle.decoration != null
          ? TextDecoration.combine([baseStyle.decoration!, TextDecoration.underline])
          : TextDecoration.underline;
      final underlineStyle = baseStyle.copyWith(decoration: decoration);
      return TextSpan(
        style: underlineStyle,
        children: node.children.map((c) => buildSpan(c, underlineStyle)).toList(),
      );
    }
    if (node is InlineLineBreak) {
      return const TextSpan(text: '\n');
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
      final decoration = baseStyle.decoration != null
          ? TextDecoration.combine(
              [baseStyle.decoration!, TextDecoration.lineThrough])
          : TextDecoration.lineThrough;
      final strikeStyle = baseStyle.copyWith(
        decoration: decoration,
        color: baseStyle.color?.withValues(alpha: 0.7) ?? AppColors.textMuted,
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
      final Color bg;
      if (node.markType == 'highlight' || node.markType == 'mark') {
        bg = const Color(0xFFF9D423).withValues(alpha: 0.28);
      } else {
        bg = AppColors.primary.withValues(alpha: 0.18);
      }
      final markStyle = baseStyle.copyWith(
        backgroundColor: bg,
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
