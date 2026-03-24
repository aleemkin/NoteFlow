import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/core/platform/app_platform.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/features/vault/presentation/dialogs/vault_dialogs.dart';
import 'package:noteflow/features/vault/vault.dart';
import 'inline_create_row.dart';
import 'inline_rename_row.dart';
import '../../../domain/vault_tree_types.dart';

class TreeNode extends StatelessWidget {
  final VaultTreeNode node;
  final int depth;
  final String? selectedPath;
  final VaultUri? selectedFolderUri;
  final Set<String> expandedPaths;
  final String filter;
  final InlineCreateState? inlineCreate;
  final String? renamingPath;
  final void Function(String path) onToggleExpand;
  final void Function(VaultUri folderUri)? onFolderSelected;
  final void Function(String path)? onFileSelected;
  final void Function(InlineCreateType type, [VaultUri? dir]) onStartCreate;
  final Future<void> Function(String rawName) onCreateCommit;
  final VoidCallback onCreateCancel;
  final void Function(String path) onStartRename;
  final Future<void> Function(VaultTreeNode node, String newName)
  onRenameCommit;
  final VoidCallback onRenameCancel;
  final Future<void> Function(VaultTreeNode source, VaultUri destinationDir)
  onMoveNode;
  final WidgetRef ref;

  const TreeNode({
    super.key,
    required this.node,
    required this.depth,
    this.selectedPath,
    this.selectedFolderUri,
    required this.expandedPaths,
    required this.filter,
    this.inlineCreate,
    this.renamingPath,
    required this.onToggleExpand,
    this.onFolderSelected,
    this.onFileSelected,
    required this.onStartCreate,
    required this.onCreateCommit,
    required this.onCreateCancel,
    required this.onStartRename,
    required this.onRenameCommit,
    required this.onRenameCancel,
    required this.onMoveNode,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    if (VaultTreeNode.isDrawingSnapshot(node.uri.path)) {
      return const SizedBox.shrink();
    }
    if (node.isDirectory) {
      return _buildDirectory(context, node);
    }
    return _buildFile(context, node);
  }

  Widget _buildFile(BuildContext context, VaultTreeNode node) {
    if (renamingPath == node.uri.path) {
      return InlineRenameRow(
        node: node,
        depth: depth,
        onCommit: (newName) => onRenameCommit(node, newName),
        onCancel: onRenameCancel,
      );
    }

    final isMobile = AppPlatform.isMobile;
    final isSelected = selectedPath == node.uri.path;
    final isDraw = node.uri.path.endsWith('.excalidraw');

    final fileContent = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 4,
        vertical: isMobile ? 2.5 : 1,
      ),
      child: Material(
        color: isSelected ? const Color(0xFF04395E) : Colors.transparent,
        borderRadius: BorderRadius.circular(isMobile ? 6 : 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(isMobile ? 6 : 4),
          hoverColor: const Color(0xFF2A2D32).withValues(alpha: 0.4),
          onTap: () => onFileSelected?.call(node.uri.path),
          onSecondaryTapDown: (details) {
            _showContextMenu(context, details.globalPosition, node);
          },
          onLongPress: () {
            final renderBox = context.findRenderObject() as RenderBox?;
            final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
            _showContextMenu(context, offset + const Offset(40, 20), node);
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: (depth * (isMobile ? 16.0 : 14.0)) + (isMobile ? 8.0 : 6.0),
              right: isMobile ? 8.0 : 6.0,
              top: isMobile ? 9.5 : 4.0,
              bottom: isMobile ? 9.5 : 4.0,
            ),
            child: Row(
              children: [
                Icon(
                  isDraw ? Icons.draw_outlined : Icons.description_outlined,
                  size: isMobile ? 18 : 14,
                  color: isDraw ? AppColors.secondary : AppColors.textMuted,
                ),
                SizedBox(width: isMobile ? 9 : 7),
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      fontSize: isMobile ? 13.5 : 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Draggable<VaultTreeNode>(
      data: node,
      feedback: _buildDragFeedback(node),
      childWhenDragging: Opacity(opacity: 0.35, child: fileContent),
      child: fileContent,
    );
  }

  Widget _buildDirectory(BuildContext context, VaultTreeNode node) {
    if (renamingPath == node.uri.path) {
      return InlineRenameRow(
        node: node,
        depth: depth,
        onCommit: (newName) => onRenameCommit(node, newName),
        onCancel: onRenameCancel,
      );
    }

    final isMobile = AppPlatform.isMobile;
    final isExpanded =
        filter.isNotEmpty || expandedPaths.contains(node.uri.path);
    final isFolderActive = selectedFolderUri?.path == node.uri.path;

    final dirHeader = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 4,
        vertical: isMobile ? 2.5 : 1,
      ),
      child: Material(
        color: isFolderActive
            ? const Color(0xFF04395E).withValues(alpha: 0.45)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(isMobile ? 6 : 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(isMobile ? 6 : 4),
          hoverColor: const Color(0xFF2A2D32).withValues(alpha: 0.4),
          onTap: () {
            onFolderSelected?.call(node.uri);
            onToggleExpand(node.uri.path);
          },
          onSecondaryTapDown: (details) {
            _showContextMenu(context, details.globalPosition, node);
          },
          onLongPress: () {
            final renderBox = context.findRenderObject() as RenderBox?;
            final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
            _showContextMenu(context, offset + const Offset(40, 20), node);
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: (depth * (isMobile ? 16.0 : 14.0)) + (isMobile ? 8.0 : 6.0),
              right: isMobile ? 8.0 : 4.0,
              top: isMobile ? 9.5 : 3.5,
              bottom: isMobile ? 9.5 : 3.5,
            ),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.folder_open : Icons.folder,
                  size: isMobile ? 18 : 15,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: isMobile ? 8 : 6),
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      fontSize: isMobile ? 13.5 : 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: isMobile ? 18 : 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Make folder both Draggable (can move to another folder) and DragTarget (can receive items)
    final folderTarget = DragTarget<VaultTreeNode>(
      onWillAcceptWithDetails: (details) {
        final dragged = details.data;
        if (dragged.uri == node.uri) return false;
        if (dragged.uri.directory == node.uri.path) return false;
        if (dragged.isDirectory && node.uri.path.startsWith(dragged.uri.path)) {
          return false;
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        onMoveNode(details.data, node.uri);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: isHovered
                ? Border.all(color: const Color(0xFF007ACC))
                : null,
            color: isHovered
                ? const Color(0xFF04395E).withValues(alpha: 0.4)
                : null,
          ),
          child: Draggable<VaultTreeNode>(
            data: node,
            feedback: _buildDragFeedback(node),
            childWhenDragging: Opacity(opacity: 0.35, child: dirHeader),
            child: dirHeader,
          ),
        );
      },
    );

    final showInlineCreateInside =
        inlineCreate != null &&
        inlineCreate!.parentDir.path == node.uri.path &&
        isExpanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        folderTarget,
        if (isExpanded) ...[
          if (showInlineCreateInside)
            InlineCreateRow(
              type: inlineCreate!.type,
              depth: depth + 1,
              onCommit: onCreateCommit,
              onCancel: onCreateCancel,
            ),
          ...node.sortedChildren
              .where((c) => _matches(c))
              .map(
                (child) => TreeNode(
                  node: child,
                  depth: depth + 1,
                  selectedPath: selectedPath,
                  selectedFolderUri: selectedFolderUri,
                  expandedPaths: expandedPaths,
                  filter: filter,
                  inlineCreate: inlineCreate,
                  renamingPath: renamingPath,
                  onToggleExpand: onToggleExpand,
                  onFolderSelected: onFolderSelected,
                  onFileSelected: onFileSelected,
                  onStartCreate: onStartCreate,
                  onCreateCommit: onCreateCommit,
                  onCreateCancel: onCreateCancel,
                  onStartRename: onStartRename,
                  onRenameCommit: onRenameCommit,
                  onRenameCancel: onRenameCancel,
                  onMoveNode: onMoveNode,
                  ref: ref,
                ),
              ),
        ],
      ],
    );
  }

  bool _matches(VaultTreeNode node) {
    if (VaultTreeNode.isDrawingSnapshot(node.uri.path)) return false;
    if (filter.isEmpty) return true;
    if (node.name.toLowerCase().contains(filter)) return true;
    if (node.isDirectory) {
      return node.children.any((c) => _matches(c));
    }
    return false;
  }

  Widget _buildDragFeedback(VaultTreeNode node) {
    final isDraw = node.uri.path.endsWith('.excalidraw');
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF252526),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFF007ACC)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              node.isDirectory
                  ? Icons.folder
                  : (isDraw ? Icons.draw_outlined : Icons.description_outlined),
              size: 14,
              color: isDraw ? AppColors.secondary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              node.name,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    VaultTreeNode node,
  ) {
    final folderLabel = node.uri.path.isEmpty ? 'root' : '/${node.uri.path}';
    final items = <PopupMenuEntry<String>>[
      if (node.isDirectory) ...[
        PopupMenuItem(
          value: 'new_note',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.note_add_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'New Note in $folderLabel',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'new_drawing',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.draw_outlined,
                size: 14,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'New Drawing in $folderLabel',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'new_folder',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.create_new_folder_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'New Subfolder in $folderLabel',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
      ],
      const PopupMenuItem(
        value: 'rename',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, size: 14, color: AppColors.textMuted),
            SizedBox(width: 8),
            Flexible(child: Text('Rename', style: TextStyle(fontSize: 12))),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, size: 14, color: AppColors.markDanger),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Delete',
                style: TextStyle(fontSize: 12, color: AppColors.markDanger),
              ),
            ),
          ],
        ),
      ),
    ];

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
    ).then((value) {
      if (value == null || !context.mounted) return;
      switch (value) {
        case 'new_note':
          onStartCreate(InlineCreateType.note, node.uri);
        case 'new_drawing':
          onStartCreate(InlineCreateType.drawing, node.uri);
        case 'new_folder':
          onStartCreate(InlineCreateType.folder, node.uri);
        case 'rename':
          onStartRename(node.uri.path);
        case 'delete':
          VaultDialogs.deleteEntry(context, ref, node.uri, node.name);
      }
    });
  }
}
