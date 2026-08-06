import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/document.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/editor/presentation/outline/outline_inspector_panel.dart';
import 'package:noteflow/features/vault/vault.dart';

/// Right-hand panel for editor mode, showing outline or "no file selected" state.
class EditModeOutlinePanel extends StatelessWidget {
  final String? selectedFilePath;
  final VaultTreeNode? activeFolder;
  final List<AtomicUnit> editDocUnits;
  final void Function(AtomicUnit unit)? onUnitSelected;
  final Future<void> Function(List<AtomicUnit> newUnits)? onUnitsReordered;

  const EditModeOutlinePanel({
    super.key,
    required this.selectedFilePath,
    this.activeFolder,
    required this.editDocUnits,
    this.onUnitSelected,
    this.onUnitsReordered,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedFilePath == null) {
      return Container(
        decoration: const BoxDecoration(color: AppColors.surfaceSidebar),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.format_list_bulleted_rounded,
                  size: 28,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 10),
                Text(
                  'No file selected',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Select a note to inspect its outline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final parentDir = VaultUri(path: selectedFilePath!).directory;
    final fileName = VaultUri(path: selectedFilePath!).fileName;
    final folderNode =
        activeFolder ??
        VaultTreeNode(
          uri: VaultUri(path: parentDir),
          name: fileName,
          isDirectory: false,
          modifiedAt: DateTime.now(),
        );

    if (selectedFilePath!.endsWith('.excalidraw')) {
      final drawingUnit = AtomicUnit(
        id: 'draw_${selectedFilePath!}',
        docUri: VaultUri(path: selectedFilePath!),
        title: fileName,
        kind: AtomicUnitKind.drawing,
        rawMarkdown: '@@drawing ./$fileName',
        targetBlockId: 'draw_${selectedFilePath!}',
      );
      return OutlineInspectorPanel(
        folderNode: folderNode,
        units: [drawingUnit],
      );
    }

    return OutlineInspectorPanel(
      folderNode: folderNode,
      units: editDocUnits,
      onUnitSelected: onUnitSelected,
      onUnitsReordered: onUnitsReordered,
    );
  }
}
