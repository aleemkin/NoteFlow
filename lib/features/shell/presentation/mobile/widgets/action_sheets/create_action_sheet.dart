import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/notifications/notifications.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/canvas/canvas.dart';
import 'package:noteflow/features/vault/presentation/dialogs/vault_dialogs.dart';

/// Modal bottom sheet for creating a Note, Diagram, or Folder in a parent directory.
class CreateActionSheet {
  CreateActionSheet._();

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required VaultUri parentDir,
    required void Function(String path)? onFileCreated,
  }) async {
    unawaited(HapticFeedback.lightImpact());

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final folderName = parentDir.path.isEmpty
            ? 'Vault Root'
            : p.basename(parentDir.path);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sheet drag handle
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Create in $folderName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // 1. New Markdown Note
                _buildCreateTile(
                  ctx: ctx,
                  icon: Icons.description_rounded,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primary.withValues(alpha: 0.12),
                  title: 'New Note (.md)',
                  subtitle: 'Create a rich Markdown note',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _handleCreateNote(
                      context,
                      ref,
                      parentDir,
                      onFileCreated,
                    );
                  },
                ),
                const SizedBox(height: 8),
                // 2. New Excalidraw Diagram
                _buildCreateTile(
                  ctx: ctx,
                  icon: Icons.brush_rounded,
                  iconColor: const Color(0xFFEC4899),
                  iconBg: const Color(0xFFEC4899).withValues(alpha: 0.12),
                  title: 'New Excalidraw Diagram',
                  subtitle: 'Vector drawing with official sketchy canvas',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _handleCreateDrawing(
                      context,
                      ref,
                      parentDir,
                      onFileCreated,
                    );
                  },
                ),
                const SizedBox(height: 8),
                // 3. New Folder
                _buildCreateTile(
                  ctx: ctx,
                  icon: Icons.create_new_folder_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  title: 'New Subfolder',
                  subtitle: 'Organize notes and diagrams in a folder',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _handleCreateFolder(context, ref, parentDir);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildCreateTile({
    required BuildContext ctx,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceNavbar,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _handleCreateNote(
    BuildContext context,
    WidgetRef ref,
    VaultUri parentDir,
    void Function(String path)? onFileCreated,
  ) async {
    final name = await VaultDialogs.showInputDialog(
      context,
      'New Markdown Note',
      'Note name',
      'note_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (name == null || name.trim().isEmpty) return;

    final cleanName = name.trim().endsWith('.md')
        ? name.trim()
        : '${name.trim()}.md';
    try {
      final ops = ref.read(vaultOperationsProvider);
      final createdUri = await ops.createNote(
        name: cleanName,
        parentDir: parentDir,
      );
      onFileCreated?.call(createdUri.path);
    } catch (e) {
      if (context.mounted) {
        AppNotification.showError(context, 'Failed to create note: $e');
      }
    }
  }

  static Future<void> _handleCreateDrawing(
    BuildContext context,
    WidgetRef ref,
    VaultUri parentDir,
    void Function(String path)? onFileCreated,
  ) async {
    final name = await VaultDialogs.showInputDialog(
      context,
      'New Excalidraw Diagram',
      'Diagram name',
      'diagram_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (name == null || name.trim().isEmpty) return;

    final cleanName = name.trim().endsWith('.excalidraw')
        ? name.trim()
        : '${name.trim()}.excalidraw';
    final targetUri = parentDir.isRoot
        ? VaultUri(path: cleanName)
        : VaultUri(path: '${parentDir.path}/$cleanName');
    try {
      final ops = ref.read(vaultOperationsProvider);
      await ops.saveFile(targetUri, ExcalidrawTemplate.emptyScene);
      onFileCreated?.call(targetUri.path);
    } catch (e) {
      if (context.mounted) {
        AppNotification.showError(context, 'Failed to create drawing: $e');
      }
    }
  }

  static Future<void> _handleCreateFolder(
    BuildContext context,
    WidgetRef ref,
    VaultUri parentDir,
  ) async {
    await VaultDialogs.createFolder(context, ref, parentDir);
  }
}
