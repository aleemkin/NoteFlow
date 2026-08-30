import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noteflow/core/theme/app_theme.dart';

/// Modal bottom sheet for text selection actions in Reading View (tagging, drawings, copying).
class TextSelectionSheet {
  TextSelectionSheet._();

  static Future<void> show({
    required BuildContext context,
    required String selectedText,
    required void Function(String tag) onTag,
    required VoidCallback onInsertDiagram,
    required VoidCallback onCopy,
    required VoidCallback onRemoveTag,
  }) async {
    unawaited(HapticFeedback.lightImpact());

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderDefault,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceNavbar,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    '"$selectedText"',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.star_rounded,
                    color: AppColors.markImportant,
                  ),
                  title: const Text(
                    'Tag as Important (@@imp)',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onTag('imp');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.markInfo,
                  ),
                  title: const Text(
                    'Tag as Reference (@@info)',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onTag('info');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.brush_rounded,
                    color: Color(0xFFEC4899),
                  ),
                  title: const Text(
                    'Insert Excalidraw Diagram',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onInsertDiagram();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.copy_rounded,
                    color: AppColors.textSecondary,
                  ),
                  title: const Text(
                    'Copy Selected Text',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onCopy();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.label_off_outlined,
                    color: AppColors.textMuted,
                  ),
                  title: const Text(
                    'Remove Tag Directives',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onRemoveTag();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
