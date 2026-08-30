import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/document.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/features/shell/presentation/home_shared/edit_mode_outline_panel.dart';
import 'package:noteflow/features/shell/presentation/home_shared/home_screen_actions.dart';
import 'package:noteflow/features/editor/presentation/outline/outline_inspector_panel.dart';
import 'package:noteflow/features/vault/presentation/widgets/vault_tree_widget.dart';

/// Left drawer displaying the vault tree hierarchy and folder filter tags.
class MobileLeftDrawer extends ConsumerWidget {
  const MobileLeftDrawer({
    super.key,
    required this.controller,
    required this.initialCreateType,
    required this.onFileSelected,
    required this.onFolderSelected,
  });

  final VaultTreeController controller;
  final InlineCreateType? initialCreateType;
  final ValueChanged<String> onFileSelected;
  final void Function(VaultUri uri) onFolderSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFolderState = ref.watch(activeFolderControllerProvider);
    final editorState = ref.watch(editorSessionControllerProvider);

    return Drawer(
      backgroundColor: AppColors.surfaceSidebar,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: VaultTreeWidget(
                controller: controller,
                initialCreateType: initialCreateType,
                selectedPath: editorState.selectedFilePath,
                onFileSelected: onFileSelected,
                onFolderSelected: onFolderSelected,
                tagSummaries: activeFolderState.tagSummaries,
                filterMode: activeFolderState.filterMode,
                activeTagFilter: activeFolderState.customTagFilter,
                onFilterChanged: (mode, tag) {
                  ref
                      .read(activeFolderControllerProvider.notifier)
                      .setFilter(mode, tag);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Right drawer displaying note or folder outline inspector.
class MobileRightDrawer extends ConsumerWidget {
  const MobileRightDrawer({
    super.key,
    required this.currentTabIndex,
    required this.onScrollToUnit,
    required this.onSwitchToReadingTab,
  });

  final int currentTabIndex;
  final ValueChanged<AtomicUnit> onScrollToUnit;
  final VoidCallback onSwitchToReadingTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFolderState = ref.watch(activeFolderControllerProvider);
    final editorState = ref.watch(editorSessionControllerProvider);

    return Drawer(
      backgroundColor: AppColors.surfaceSidebar,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceNavbar,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.format_list_bulleted_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Outline & Structure',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close outline',
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildContent(
                context,
                ref,
                activeFolderState,
                editorState,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ActiveFolderState activeFolderState,
    EditorSessionState editorState,
  ) {
    if (currentTabIndex == 1 && editorState.selectedFilePath != null) {
      return EditModeOutlinePanel(
        selectedFilePath: editorState.selectedFilePath,
        activeFolder: activeFolderState.activeFolder,
        editDocUnits: editorState.editDocUnits,
        onUnitSelected: (unit) {
          Navigator.pop(context);
        },
        onUnitsReordered: (newUnits) async {
          ref
              .read(editorSessionControllerProvider.notifier)
              .updateEditDocUnits(newUnits);
        },
      );
    }

    if (activeFolderState.activeFolder != null) {
      return OutlineInspectorPanel(
        folderNode: activeFolderState.activeFolder!,
        units: activeFolderState.atomicUnits,
        onUnitsReordered: (newUnits) async {
          await HomeScreenActions.onUnitsReordered(
            context: context,
            ref: ref,
            orderedFolderFiles: activeFolderState.orderedFiles,
            folderDocuments: activeFolderState.documents,
            activeFolder: activeFolderState.activeFolder,
            newUnits: newUnits,
            reloadFolder: (folder) => ref
                .read(activeFolderControllerProvider.notifier)
                .loadFolder(folder),
          );
        },
        onUnitSelected: (unit) {
          Navigator.pop(context);
          onScrollToUnit(unit);
          onSwitchToReadingTab();
        },
      );
    }

    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'No folder or document selected to display outline.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ),
    );
  }
}
