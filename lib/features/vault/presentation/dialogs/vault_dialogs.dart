import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/canvas/canvas.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/features/vault/presentation/dialogs/create_vault_dialog.dart';
import 'package:noteflow/core/notifications/notifications.dart';

export 'create_vault_dialog.dart';

/// Reusable modal dialogs for vault file and folder management.
class VaultDialogs {
  const VaultDialogs._();

  /// Prompts the user to enter a text string with an input dialog.
  static Future<String?> showInputDialog(
    BuildContext context,
    String title,
    String label, [
    String initialValue = '',
  ]) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(labelText: label, hintText: label),
          onSubmitted: (val) => Navigator.pop(ctx, val.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  /// Prompts for a note name and creates a new Markdown note inside [parentDir].
  static Future<void> createNote(
    BuildContext context,
    WidgetRef ref,
    VaultUri parentDir,
  ) async {
    final folderLabel = parentDir.path.isEmpty ? 'root' : '/${parentDir.path}';
    final name = await showInputDialog(
      context,
      'New Note in $folderLabel',
      'Note name (e.g. notes.md)',
    );
    if (name != null && name.trim().isNotEmpty) {
      final cleanName = name.trim().endsWith('.md')
          ? name.trim()
          : '${name.trim()}.md';
      try {
        final ops = ref.read(vaultOperationsProvider);
        await ops.createNote(name: cleanName, parentDir: parentDir);
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(
            context,
            'Unable to create note "$cleanName": $e',
            title: 'Note Creation Failed',
          );
        }
      }
    }
  }

  /// Prompts for a folder name and creates a new subfolder inside [parentDir].
  static Future<void> createFolder(
    BuildContext context,
    WidgetRef ref,
    VaultUri parentDir,
  ) async {
    final folderLabel = parentDir.path.isEmpty ? 'root' : '/${parentDir.path}';
    final name = await showInputDialog(
      context,
      'New Folder in $folderLabel',
      'Folder name',
    );
    if (name != null && name.trim().isNotEmpty) {
      try {
        final ops = ref.read(vaultOperationsProvider);
        await ops.createFolder(name: name.trim(), parentDir: parentDir);
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(
            context,
            'Unable to create folder "${name.trim()}": $e',
            title: 'Folder Creation Failed',
          );
        }
      }
    }
  }

  /// Prompts for a drawing name and creates a new `.excalidraw` diagram inside [parentDir].
  static Future<void> createDrawing(
    BuildContext context,
    WidgetRef ref,
    VaultUri parentDir,
  ) async {
    final folderLabel = parentDir.path.isEmpty ? 'root' : '/${parentDir.path}';
    final name = await showInputDialog(
      context,
      'New Drawing in $folderLabel',
      'Drawing name (e.g. diagram.excalidraw)',
    );
    if (name != null && name.trim().isNotEmpty) {
      final fileName = name.trim().endsWith('.excalidraw')
          ? name.trim()
          : '${name.trim()}.excalidraw';
      try {
        final ops = ref.read(vaultOperationsProvider);
        final uri = parentDir.isRoot
            ? VaultUri(path: fileName)
            : VaultUri(path: '${parentDir.path}/$fileName');
        await ops.saveFile(uri, ExcalidrawTemplate.emptyScene);

        final sequenceService = ref.read(folderSequenceServiceProvider);
        await sequenceService.appendToFileSequence(parentDir.path, uri.path);
        await ops.createFolder(name: '.', parentDir: parentDir);
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(
            context,
            'Unable to create drawing "$fileName": $e',
            title: 'Drawing Creation Failed',
          );
        }
      }
    }
  }

  /// Prompts the user with the current name and renames the specified [uri] entry.
  static Future<void> renameEntry(
    BuildContext context,
    WidgetRef ref,
    VaultUri uri,
    String currentName,
  ) async {
    final name = await showInputDialog(
      context,
      'Rename',
      'New name',
      currentName,
    );
    if (name != null && name.trim().isNotEmpty && name.trim() != currentName) {
      try {
        final ops = ref.read(vaultOperationsProvider);
        await ops.rename(uri: uri, newName: name.trim());
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(
            context,
            'Unable to rename "$currentName" to "${name.trim()}": $e',
            title: 'Rename Failed',
          );
        }
      }
    }
  }

  /// Prompts for deletion confirmation and removes the specified [uri] entry.
  static Future<void> deleteEntry(
    BuildContext context,
    WidgetRef ref,
    VaultUri uri,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text(
          'Delete "$name"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.markDanger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final ops = ref.read(vaultOperationsProvider);
        await ops.delete(uri);
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(
            context,
            'Unable to delete "$name": $e',
            title: 'Deletion Failed',
          );
        }
      }
    }
  }

  /// Prompts the user to configure and create a new vault on disk.
  /// Returns the path to the newly created vault folder, or null if canceled.
  static Future<String?> showCreateVaultDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => const CreateVaultDialog(),
    );
  }
}
