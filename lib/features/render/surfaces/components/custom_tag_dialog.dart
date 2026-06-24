import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';

/// Dialog allowing user to apply a custom tag slug or common preset tags to selected text.
class CustomTagDialog {
  CustomTagDialog._();

  static Future<String?> show(BuildContext context, String selectedText) async {
    final controller = TextEditingController();
    final slug = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tag Selection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected: "$selectedText"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tag Name / Slug (e.g. review, todo, question)',
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) Navigator.pop(ctx, val.trim());
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Common Tags:',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  [
                    'review',
                    'todo',
                    'question',
                    'summary',
                    'key_concept',
                    'action',
                  ].map((tag) {
                    return ActionChip(
                      label: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      backgroundColor: AppColors.surfaceCard,
                      side: const BorderSide(color: AppColors.borderSubtle),
                      onPressed: () => Navigator.pop(ctx, tag),
                    );
                  }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Apply Tag'),
          ),
        ],
      ),
    );

    if (slug != null && slug.isNotEmpty) {
      return slug.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    }
    return null;
  }
}
