import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/render/render.dart';
import 'package:noteflow/features/shell/presentation/home_shared/home.dart';

/// Full-width continuous reading stream screen tailored specifically for Android mobile devices.
///
/// Features:
/// - Active folder banner with note count and quick outline access
/// - Pull-to-refresh
/// - Responsive card margins and continuous dark reading stream
/// - Tag filter status pill with one-tap clear
class MobileReadingScreen extends ConsumerWidget {
  final ValueChanged<String> onEditDocument;
  final ValueChanged<String> onEditDrawing;
  final VoidCallback onOpenFiles;
  final ScrollController scrollController;
  final Map<String, GlobalKey> blockKeys;

  const MobileReadingScreen({
    super.key,
    required this.onEditDocument,
    required this.onEditDrawing,
    required this.onOpenFiles,
    required this.scrollController,
    required this.blockKeys,
  });

  // void _showOutline(BuildContext context, WidgetRef ref) {

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
      return ReadingModeEmptyState(onOpenFileManager: onOpenFiles);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Main continuous roll wrapped in RefreshIndicator
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceCard,
              onRefresh: () async {
                await HapticFeedback.lightImpact();
                await activeNotifier.refresh();
              },
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
          ),
        ],
      ),
    );
  }
}
