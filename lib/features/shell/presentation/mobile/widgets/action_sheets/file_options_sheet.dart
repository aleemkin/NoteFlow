import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/notifications/notifications.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/vault/presentation/dialogs/vault_dialogs.dart';

/// Modal bottom sheet for file options (Open, Preview, Rename, Delete).
class FileOptionsSheet {
  FileOptionsSheet._();

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required String filePath,
    required bool isDirectory,
    required VoidCallback onOpen,
    VoidCallback? onPreviewInReading,
  }) async {
    unawaited(HapticFeedback.lightImpact());
    final fileName = p.basename(filePath);
    final isDrawing = filePath.endsWith('.excalidraw');
    final isMd = filePath.endsWith('.md');

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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      isDirectory
                          ? Icons.folder_rounded
                          : (isDrawing
                                ? Icons.brush_rounded
                                : Icons.description_rounded),
                      color: isDirectory
                          ? const Color(0xFFF59E0B)
                          : (isDrawing
                                ? const Color(0xFFEC4899)
                                : AppColors.primary),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // 1. Open action
                ListTile(
                  leading: const Icon(
                    Icons.open_in_new_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    isDirectory
                        ? 'Open Folder in Notes Roll'
                        : (isDrawing
                              ? 'Open in Excalidraw Canvas'
                              : 'Open in Editor'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onOpen();
                  },
                ),
                if (!isDirectory && isMd && onPreviewInReading != null) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.auto_stories_outlined,
                      color: AppColors.textSecondary,
                    ),
                    title: const Text(
                      'Jump to in Reading View',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      onPreviewInReading();
                    },
                  ),
                ],
                // 2. Rename
                ListTile(
                  leading: const Icon(
                    Icons.drive_file_rename_outline,
                    color: AppColors.textSecondary,
                  ),
                  title: const Text(
                    'Rename',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _handleRename(context, ref, filePath, isDirectory);
                  },
                ),
                // 3. Delete
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.markDanger,
                  ),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.markDanger),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _handleDelete(context, ref, filePath, isDirectory);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _handleRename(
    BuildContext context,
    WidgetRef ref,
    String path,
    bool isDirectory,
  ) async {
    final oldName = p.basename(path);
    final newName = await VaultDialogs.showInputDialog(
      context,
      isDirectory ? 'Rename Folder' : 'Rename File',
      'New name',
      oldName,
    );
    if (newName == null ||
        newName.trim().isEmpty ||
        newName.trim() == oldName) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    try {
      await VaultDialogs.renameEntry(
        context,
        ref,
        VaultUri(path: path),
        oldName,
      );
    } catch (e) {
      if (context.mounted) {
        AppNotification.showError(context, 'Rename failed: $e');
      }
    }
  }

  static Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    String path,
    bool isDirectory,
  ) async {
    final name = p.basename(path);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(isDirectory ? 'Delete Folder?' : 'Delete Note?'),
        content: Text(
          'Are you sure you want to delete "$name"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.markDanger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(vaultOperationsProvider).delete(VaultUri(path: path));
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(context, 'Delete failed: $e');
        }
      }
    }
  }
}
