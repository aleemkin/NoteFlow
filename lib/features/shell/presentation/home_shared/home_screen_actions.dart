import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/features/document/document.dart';
import 'package:noteflow/features/canvas/canvas.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/render/render.dart';
import 'package:noteflow/core/notifications/notifications.dart';
import 'package:noteflow/features/vault/vault.dart';

/// Business operations and actions for the HomeScreen.
class HomeScreenActions {
  const HomeScreenActions._();

  /// Inserts a new Excalidraw diagram above or below the selected text in the document.
  static Future<void> insertDiagramAroundSelectedText({
    required BuildContext context,
    required WidgetRef ref,
    required List<NotebookDocument> folderDocuments,
    required VaultTreeNode? activeFolder,
    required String selectedText,
    required bool above,
    required Future<void> Function(VaultTreeNode) reloadFolder,
  }) async {
    if (selectedText.trim().isEmpty) return;
    final cleanSelected = selectedText.trim();
    final ops = ref.read(vaultOperationsProvider);
    final sequenceService = ref.read(folderSequenceServiceProvider);

    for (final doc in folderDocuments) {
      final span = MarkdownTagger.findSourceSpan(
        doc.source.text,
        cleanSelected,
      );
      if (span == null) continue;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final diagramFileName = 'diagram_$timestamp.excalidraw';
      final drawId = 'draw_$timestamp';

      // 1. Create diagram file in document folder
      final docUri = doc.uri;
      final drawUri = docUri.directory.isEmpty
          ? VaultUri(path: diagramFileName)
          : VaultUri(path: '${docUri.directory}/$diagramFileName');

      await ops.saveFile(drawUri, ExcalidrawTemplate.emptyScene);

      // 2. Append to folder sequence
      await sequenceService.appendToFileSequence(
        docUri.directory,
        drawUri.path,
      );

      // 3. Find insertion position strictly outside atomic block boundaries (tables, code blocks, directives)
      final atomicSpan = MarkdownTagger.expandToAtomicBlockBoundaries(
        doc.source.text,
        span.start,
        span.end,
      );
      final insertPos = above ? atomicSpan.start : atomicSpan.end;

      final before = doc.source.text.substring(0, insertPos).trimRight();
      final after = doc.source.text.substring(insertPos).trimLeft();

      final buffer = StringBuffer();
      if (before.isNotEmpty) {
        buffer.write(before);
        buffer.write('\n\n');
      }
      buffer.write(
        '@@drawing ./$diagramFileName #$drawId {minHeight=260}\n@@/drawing',
      );
      if (after.isNotEmpty) {
        buffer.write('\n\n');
        buffer.write(after);
      }

      final newText = buffer.toString();
      await ops.saveFile(doc.uri, newText);

      // 4. Refresh folder view in memory immediately
      if (activeFolder != null) {
        await reloadFolder(activeFolder);
      }

      if (context.mounted) {
        AppNotification.showSuccess(
          context,
          'Embedded "$diagramFileName" ${above ? "above" : "below"} selection in "${doc.title}".',
          title: 'Drawing Embedded',
        );
      }
      break;
    }
  }

  /// Tags the selected text with [tagType] in the matching document.
  static Future<void> tagSelectedText({
    required BuildContext context,
    required WidgetRef ref,
    required List<NotebookDocument> folderDocuments,
    required VaultTreeNode? activeFolder,
    required String selectedText,
    required String tagType,
    required Future<void> Function(VaultTreeNode) reloadFolder,
  }) async {
    if (selectedText.trim().isEmpty) return;
    final cleanSelected = selectedText.trim();
    final ops = ref.read(vaultOperationsProvider);

    for (final doc in folderDocuments) {
      final span = MarkdownTagger.findSourceSpan(
        doc.source.text,
        cleanSelected,
      );
      if (span != null) {
        final newText = MarkdownTagger.tagText(
          doc.source.text,
          cleanSelected,
          tagType,
        );
        if (newText != doc.source.text) {
          await ops.saveFile(doc.uri, newText);
          if (activeFolder != null) {
            await reloadFolder(activeFolder);
          }
          if (context.mounted) {
            AppNotification.showSuccess(
              context,
              'Marked selection with #${tagType.toUpperCase()} in "${doc.title}".',
              title: 'Tag Applied',
            );
          }
          break;
        }
      }
    }
  }

  /// Removes semantic tags from the selected text in the matching document.
  static Future<void> removeTagFromSelectedText({
    required BuildContext context,
    required WidgetRef ref,
    required List<NotebookDocument> folderDocuments,
    required VaultTreeNode? activeFolder,
    required ScrollFilterMode scrollFilter,
    required String? customTagFilter,
    required String selectedText,
    required Future<void> Function(VaultTreeNode) reloadFolder,
  }) async {
    if (selectedText.trim().isEmpty) return;
    final cleanSelected = selectedText.trim();
    final ops = ref.read(vaultOperationsProvider);

    final activeTag = switch (scrollFilter) {
      ScrollFilterMode.importantOnly => 'imp',
      ScrollFilterMode.infoOnly => 'info',
      ScrollFilterMode.customTag => customTagFilter,
      _ => null,
    };

    for (final doc in folderDocuments) {
      final span = MarkdownTagger.findSourceSpan(
        doc.source.text,
        cleanSelected,
      );
      if (span != null) {
        final newText = MarkdownTagger.removeTag(
          doc.source.text,
          cleanSelected,
          tagType: activeTag,
        );
        if (newText != doc.source.text) {
          await ops.saveFile(doc.uri, newText);
          if (activeFolder != null) {
            await reloadFolder(activeFolder);
          }
          if (context.mounted) {
            AppNotification.showInfo(
              context,
              'Removed tag from selection in "${doc.title}".',
              title: 'Tag Removed',
            );
          }
          break;
        }
      }
    }
  }

  /// Copies markdown representation of current tagged/filtered roll to system clipboard.
  static void copyTaggedRoll({
    required BuildContext context,
    required List<NotebookDocument> folderDocuments,
    required ScrollFilterMode scrollFilter,
    required String? customTagFilter,
    required VaultTreeNode? activeFolder,
  }) {
    final markdown = TagExtractor.generateRollMarkdown(
      docs: folderDocuments,
      filterMode: scrollFilter,
      activeTagFilter: customTagFilter,
      folderName: activeFolder?.name,
    );
    Clipboard.setData(ClipboardData(text: markdown));
    if (context.mounted) {
      AppNotification.showSuccess(
        context,
        'Roll markdown content copied to your clipboard.',
        title: 'Markdown Copied',
      );
    }
  }

  /// Exports current tagged/filtered roll to a new markdown note in the folder.
  static Future<void> exportTaggedRoll({
    required BuildContext context,
    required WidgetRef ref,
    required List<NotebookDocument> folderDocuments,
    required ScrollFilterMode scrollFilter,
    required String? customTagFilter,
    required VaultTreeNode? activeFolder,
    required Future<void> Function(VaultTreeNode) reloadFolder,
  }) async {
    if (activeFolder == null) return;
    try {
      final markdown = TagExtractor.generateRollMarkdown(
        docs: folderDocuments,
        filterMode: scrollFilter,
        activeTagFilter: customTagFilter,
        folderName: activeFolder.name,
      );

      final tagSlug = switch (scrollFilter) {
        ScrollFilterMode.importantOnly => 'imp',
        ScrollFilterMode.infoOnly => 'info',
        ScrollFilterMode.diagramsOnly => 'diagrams',
        ScrollFilterMode.customTag => customTagFilter ?? 'tag',
        ScrollFilterMode.all => 'all',
      };

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${tagSlug}_notes_$timestamp.md';
      final folderDir = activeFolder.uri.isRoot ? '' : activeFolder.uri.path;
      final noteUri = folderDir.isEmpty
          ? VaultUri(path: fileName)
          : VaultUri(path: '$folderDir/$fileName');

      final ops = ref.read(vaultOperationsProvider);
      final sequenceService = ref.read(folderSequenceServiceProvider);

      await ops.saveFile(noteUri, markdown);
      await sequenceService.appendToFileSequence(folderDir, noteUri.path);

      await reloadFolder(activeFolder);

      if (context.mounted) {
        AppNotification.showSuccess(
          context,
          'Successfully exported roll notes to "$fileName".',
          title: 'Notes Exported',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppNotification.showError(
          context,
          'Unable to export notes: $e',
          title: 'Export Failed',
        );
      }
    }
  }

  /// Handles section drag-and-drop reordering across physical notes on disk.
  static Future<void> onUnitsReordered({
    required BuildContext context,
    required WidgetRef ref,
    required List<VaultTreeNode> orderedFolderFiles,
    required List<NotebookDocument> folderDocuments,
    required VaultTreeNode? activeFolder,
    required List<AtomicUnit> newUnits,
    required Future<void> Function(VaultTreeNode) reloadFolder,
  }) async {
    if (activeFolder == null) return;
    try {
      final ops = ref.read(vaultOperationsProvider);
      final manager = ref.read(vaultManagerProvider);

      // 1. Gather original files in sequence and their frontmatters
      final originalFilePaths = orderedFolderFiles
          .where((f) => !f.isDirectory && f.uri.path.endsWith('.md'))
          .map((f) => f.uri.path)
          .toList();

      final originalFrontmatters = <String, String>{};
      for (final doc in folderDocuments) {
        originalFrontmatters[doc.uri.path] =
            AtomicUnitParser.extractFrontmatter(doc.source.text);
      }

      // 2. Redistribute units to file contents with priority boundary rules
      final fileContents = AtomicUnitParser.redistributeUnitsToFileContents(
        units: newUnits,
        originalFilePaths: originalFilePaths,
        originalFrontmatters: originalFrontmatters,
      );

      // 3. Save modified files and delete empty files on disk
      for (final entry in fileContents.entries) {
        final filePath = entry.key;
        final content = entry.value;
        final fileUri = VaultUri(path: filePath);

        if (content == null) {
          if (await manager.fileSystem?.exists(fileUri) == true) {
            await ops.delete(fileUri);
          }
        } else {
          await ops.saveFile(fileUri, content);
        }
      }

      // 4. Refresh vault tree repository
      final treeRepo = ref.read(vaultTreeRepositoryProvider);
      final scanner = VaultScanner(fileSystem: manager.fileSystem!);
      final entries = await scanner.scanVault(const VaultUri(path: ''));
      treeRepo.buildTree(
        entries,
        const VaultUri(path: ''),
        manager.currentVault?.displayName ?? 'Vault',
      );

      // 5. Reload active folder and refresh scroll view
      await reloadFolder(activeFolder);

      if (context.mounted) {
        AppNotification.showSuccess(
          context,
          'Document section sequence synchronized to disk.',
          title: 'Sections Reordered',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppNotification.showError(
          context,
          'Unable to apply section sequence: $e',
          title: 'Reorder Failed',
        );
      }
    }
  }
}
