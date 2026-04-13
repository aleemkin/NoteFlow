import 'package:flutter/material.dart';

/// Definition for semantic mark types (built-in and user-custom).
class MarkDefinition {
  final String slug;
  final String label;
  final Color color;

  const MarkDefinition({
    required this.slug,
    required this.label,
    required this.color,
  });

  Map<String, Object?> toJson() => {
    'slug': slug,
    'label': label,
    'color': color.toARGB32().toRadixString(16),
  };

  factory MarkDefinition.fromJson(Map<String, Object?> json) {
    return MarkDefinition(
      slug: json['slug'] as String? ?? '',
      label: json['label'] as String? ?? '',
      color: Color(
        int.tryParse(json['color'] as String? ?? 'FF9E9E9E', radix: 16) ??
            0xFF9E9E9E,
      ),
    );
  }
}
