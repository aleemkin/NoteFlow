import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/render/render.dart';
import 'package:noteflow/features/shell/presentation/home_shared/home.dart';

/// Center reading panel for desktop layout displaying the continuous folder stream.
class DesktopReadingPanel extends ConsumerWidget {
  final ScrollController scrollController;
  final Map<String, GlobalKey> blockKeys;
  final ValueChanged<String> onEditDocument;
  final ValueChanged<String> onEditDrawing;
  final VoidCallback onOpenFileManager;

  const DesktopReadingPanel({
    super.key,
    required this.scrollController,
    required this.blockKeys,
    required this.onEditDocument,
    required this.onEditDrawing,
    required this.onOpenFileManager,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeState = ref.watch(activeFolderControllerProvider);
    final activeNotifier = ref.read(activeFolderControllerProvider.notifier);

    if (activeState.isLoading && activeState.documents.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (activeState.isEmpty) {
      return ReadingModeEmptyState(onOpenFileManager: onOpenFileManager);
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ContinuousFolderSurface(
          documents: activeState.documents,
          scrollController: scrollController,
          blockKeys: blockKeys,
          filterMode: activeState.filterMode,
          activeTagFilter: activeState.customTagFilter,
          onEditDocument: (uri) => onEditDocument(uri.path),
          onEditDrawing: (path) => onEditDrawing(path),
          onTagText: (selectedText, tagType) {
            HomeScreenActions.tagSelectedText(
              context: context,
              ref: ref,
              folderDocuments: activeState.documents,
              activeFolder: activeState.activeFolder,
              selectedText: selectedText,
              tagType: tagType,
              reloadFolder: (folder) => activeNotifier.loadFolder(folder),
            );
          },
          onRemoveTag: (selectedText) {
            HomeScreenActions.removeTagFromSelectedText(
              context: context,
              ref: ref,
              folderDocuments: activeState.documents,
              activeFolder: activeState.activeFolder,
              scrollFilter: activeState.filterMode,
              customTagFilter: activeState.customTagFilter,
              selectedText: selectedText,
              reloadFolder: (folder) => activeNotifier.loadFolder(folder),
            );
          },
          onInsertDiagram: (selectedText, above) {
            HomeScreenActions.insertDiagramAroundSelectedText(
              context: context,
              ref: ref,
              folderDocuments: activeState.documents,
              activeFolder: activeState.activeFolder,
              selectedText: selectedText,
              above: above,
              reloadFolder: (folder) => activeNotifier.loadFolder(folder),
            );
          },
          onClearFilter: activeNotifier.clearFilter,
          onCopyTaggedRoll: () {
            HomeScreenActions.copyTaggedRoll(
              context: context,
              folderDocuments: activeState.documents,
              scrollFilter: activeState.filterMode,
              customTagFilter: activeState.customTagFilter,
              activeFolder: activeState.activeFolder,
            );
          },
          onExportTaggedRoll: () {
            HomeScreenActions.exportTaggedRoll(
              context: context,
              ref: ref,
              folderDocuments: activeState.documents,
              scrollFilter: activeState.filterMode,
              customTagFilter: activeState.customTagFilter,
              activeFolder: activeState.activeFolder,
              reloadFolder: (folder) => activeNotifier.loadFolder(folder),
            );
          },
        ),
      ),
    );
  }
}
