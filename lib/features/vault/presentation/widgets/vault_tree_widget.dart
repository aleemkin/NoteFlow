import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/parsing/tag_extractor.dart';
import 'package:noteflow/features/canvas/canvas.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/features/render/surfaces/continuous_folder_surface.dart';
import 'package:noteflow/features/vault/presentation/dialogs/vault_dialogs.dart';
import 'package:noteflow/core/notifications/notifications.dart';
import 'package:noteflow/features/vault/vault.dart';
export 'tree_components/vault_tree.dart';

import 'tree_components/vault_tree.dart';

/// Vault tree sidebar with VS Code-style inline file/folder creation, inline renaming,
/// drag-and-drop movement, and clean, consistent styling.
class VaultTreeWidget extends ConsumerStatefulWidget {
  final String? selectedPath;
  final void Function(String path)? onFileSelected;
  final void Function(VaultUri folderUri)? onFolderSelected;
  final List<TagSummary> tagSummaries;
  final ScrollFilterMode filterMode;
  final String? activeTagFilter;
  final void Function(ScrollFilterMode mode, String? tagFilter)?
  onFilterChanged;

  final VaultTreeController? controller;
  final InlineCreateType? initialCreateType;

  const VaultTreeWidget({
    super.key,
    this.selectedPath,
    this.onFileSelected,
    this.onFolderSelected,
    this.tagSummaries = const [],
    this.filterMode = ScrollFilterMode.all,
    this.activeTagFilter,
    this.onFilterChanged,
    this.controller,
    this.initialCreateType,
  });

  @override
  ConsumerState<VaultTreeWidget> createState() => _VaultTreeWidgetState();

  static Future<void> createNote(
    BuildContext context,
    WidgetRef ref,
    VaultUri parentDir,
  ) => VaultDialogs.createNote(context, ref, parentDir);

  static Future<void> createFolder(
    BuildContext context,
    WidgetRef ref,
    VaultUri parentDir,
  ) => VaultDialogs.createFolder(context, ref, parentDir);

  static Future<void> createDrawing(
    BuildContext context,
    WidgetRef ref,
    VaultUri parentDir,
  ) => VaultDialogs.createDrawing(context, ref, parentDir);

  static Future<void> renameEntry(
    BuildContext context,
    WidgetRef ref,
    VaultUri uri,
    String currentName,
  ) => VaultDialogs.renameEntry(context, ref, uri, currentName);

  static Future<void> deleteEntry(
    BuildContext context,
    WidgetRef ref,
    VaultUri uri,
    String name,
  ) => VaultDialogs.deleteEntry(context, ref, uri, name);

  static Future<String?> showInputDialog(
    BuildContext context,
    String title,
    String label, [
    String initialValue = '',
  ]) => VaultDialogs.showInputDialog(context, title, label, initialValue);
}

class _VaultTreeWidgetState extends ConsumerState<VaultTreeWidget> {
  VaultUri? _selectedFolderUri;
  final Set<String> _expandedPaths = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = '';

  InlineCreateState? _inlineCreate;
  String? _renamingPath;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _expandedPaths.addAll(widget.controller!.expandedPaths);
      if (widget.controller!.selectedFolderUri != null) {
        _selectedFolderUri = widget.controller!.selectedFolderUri;
      }
    }
    if (widget.selectedPath != null) {
      var dir = VaultUri(path: widget.selectedPath!).directory;
      _selectedFolderUri ??= VaultUri(path: dir);
      while (dir.isNotEmpty) {
        _expandedPaths.add(dir);
        dir = VaultUri(path: dir).directory;
      }
    }
    widget.controller?.expandedPaths.addAll(_expandedPaths);
    widget.controller?.selectedFolderUri = _selectedFolderUri;

    widget.controller?.attach(onStartCreate: _startCreate);
    if (widget.initialCreateType != null) {
      final parent = _activeDirectory;
      _inlineCreate = InlineCreateState(
        type: widget.initialCreateType!,
        parentDir: parent,
      );
      if (parent.path.isNotEmpty) {
        _expandedPaths.add(parent.path);
        widget.controller?.expandedPaths.add(parent.path);
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(VaultTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(onStartCreate: _startCreate);
    }
    if (widget.selectedPath != null &&
        widget.selectedPath != oldWidget.selectedPath) {
      var dir = VaultUri(path: widget.selectedPath!).directory;
      _selectedFolderUri = VaultUri(path: dir);
      while (dir.isNotEmpty) {
        _expandedPaths.add(dir);
        dir = VaultUri(path: dir).directory;
      }
      widget.controller?.expandedPaths.addAll(_expandedPaths);
      widget.controller?.selectedFolderUri = _selectedFolderUri;
    }
    if (widget.initialCreateType != null &&
        widget.initialCreateType != oldWidget.initialCreateType) {
      _startCreate(widget.initialCreateType!);
    }
  }

  VaultUri get _activeDirectory {
    if (_selectedFolderUri != null) return _selectedFolderUri!;
    if (widget.selectedPath != null) {
      final dir = VaultUri(path: widget.selectedPath!).directory;
      return VaultUri(path: dir);
    }
    return const VaultUri(path: '');
  }

  void _selectRoot() {
    FocusScope.of(context).unfocus();
    setState(() {
      _inlineCreate = null;
      _renamingPath = null;
      _selectedFolderUri = const VaultUri(path: '');
      widget.controller?.selectedFolderUri = const VaultUri(path: '');
    });
    widget.onFolderSelected?.call(const VaultUri(path: ''));
  }

  void _startCreate(InlineCreateType type, [VaultUri? targetDir]) {
    final parent = targetDir ?? _activeDirectory;
    setState(() {
      _renamingPath = null;
      _inlineCreate = InlineCreateState(type: type, parentDir: parent);
      if (parent.path.isNotEmpty) {
        _expandedPaths.add(parent.path);
        widget.controller?.expandedPaths.add(parent.path);
      }
    });
  }

  Future<void> _submitInlineCreate(String rawName) async {
    final create = _inlineCreate;
    if (create == null) return;
    final name = rawName.trim();
    if (name.isEmpty) {
      setState(() => _inlineCreate = null);
      return;
    }

    final ops = ref.read(vaultOperationsProvider);
    try {
      VaultUri createdUri;
      switch (create.type) {
        case InlineCreateType.note:
          final fileName = name.endsWith('.md') ? name : '$name.md';
          createdUri = await ops.createNote(
            name: fileName,
            parentDir: create.parentDir,
          );
          widget.onFileSelected?.call(createdUri.path);
        case InlineCreateType.drawing:
          final fileName = name.endsWith('.excalidraw')
              ? name
              : '$name.excalidraw';
          final uri = create.parentDir.isRoot
              ? VaultUri(path: fileName)
              : VaultUri(path: '${create.parentDir.path}/$fileName');
          await ops.saveFile(uri, ExcalidrawTemplate.emptyScene);
          final sequenceService = ref.read(folderSequenceServiceProvider);
          await sequenceService.appendToFileSequence(
            create.parentDir.path,
            uri.path,
          );
          createdUri = uri;
          widget.onFileSelected?.call(createdUri.path);
        case InlineCreateType.folder:
          createdUri = await ops.createFolder(
            name: name,
            parentDir: create.parentDir,
          );
          setState(() {
            _selectedFolderUri = createdUri;
            _expandedPaths.add(createdUri.path);
            widget.controller?.selectedFolderUri = createdUri;
            widget.controller?.expandedPaths.add(createdUri.path);
          });
          widget.onFolderSelected?.call(createdUri);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(
          context,
          'Unable to create item "$name": $e',
          title: 'Creation Failed',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _inlineCreate = null);
      }
    }
  }

  void _cancelInlineCreate() {
    setState(() => _inlineCreate = null);
  }

  void _startRename(String path) {
    setState(() {
      _inlineCreate = null;
      _renamingPath = path;
    });
  }

  Future<void> _submitInlineRename(VaultTreeNode node, String newName) async {
    final name = newName.trim();
    setState(() => _renamingPath = null);
    if (name.isEmpty || name == node.name) return;

    final ops = ref.read(vaultOperationsProvider);
    try {
      final newUri = await ops.rename(uri: node.uri, newName: name);
      if (!node.isDirectory) {
        widget.onFileSelected?.call(newUri.path);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(
          context,
          'Unable to rename "${node.name}" to "$name": $e',
          title: 'Rename Failed',
        );
      }
    }
  }

  void _cancelInlineRename() {
    setState(() => _renamingPath = null);
  }

  Future<void> _moveNode(VaultTreeNode source, VaultUri destinationDir) async {
    if (source.uri.directory == destinationDir.path) return;
    if (source.isDirectory && destinationDir.path.startsWith(source.uri.path)) {
      return;
    }

    final ops = ref.read(vaultOperationsProvider);
    try {
      final newUri = await ops.move(
        uri: source.uri,
        newParentDir: destinationDir,
      );
      if (destinationDir.path.isNotEmpty) {
        setState(() {
          _expandedPaths.add(destinationDir.path);
          widget.controller?.expandedPaths.add(destinationDir.path);
        });
      }
      if (!source.isDirectory) {
        widget.onFileSelected?.call(newUri.path);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(
          context,
          'Unable to move "${source.name}": $e',
          title: 'Move Failed',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final treeRepo = ref.watch(vaultTreeRepositoryProvider);
    final root = treeRepo.root;

    if (root == null) {
      return const Center(
        child: Text(
          'No vault loaded',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final activeDir = _activeDirectory;
    final activeLabel = activeDir.isRoot
        ? (root.name.isEmpty ? 'Vault Files' : root.name)
        : '${root.name.isEmpty ? "Vault" : root.name}/${activeDir.path}';

    return Material(
      color: AppColors.surfaceSidebar,
      child: Column(
        children: [
          // 1. Vault Header with active directory indicator & action buttons
          VaultTreeHeader(
            activeDir: activeDir,
            activeLabel: activeLabel,
            onSelectRoot: _selectRoot,
            onNewNote: () => _startCreate(InlineCreateType.note),
            onNewDrawing: () => _startCreate(InlineCreateType.drawing),
            onNewFolder: () => _startCreate(InlineCreateType.folder),
          ),

          // 2. File Filter Search Bar
          VaultTreeSearchBar(
            controller: _searchController,
            searchFilter: _searchFilter,
            onChanged: (val) {
              setState(() => _searchFilter = val.trim().toLowerCase());
            },
            onClear: () {
              _searchController.clear();
              setState(() => _searchFilter = '');
            },
          ),

          // 3. Tree Listing with Drag & Drop and Empty Space Root Target
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _selectRoot,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Inline creation input at root level
                        if (_inlineCreate != null &&
                            _inlineCreate!.parentDir.isRoot)
                          InlineCreateRow(
                            type: _inlineCreate!.type,
                            depth: 0,
                            onCommit: _submitInlineCreate,
                            onCancel: _cancelInlineCreate,
                          ),
                        ...root.sortedChildren
                            .where((node) => _matchesFilter(node))
                            .map(
                              (node) => TreeNode(
                                node: node,
                                depth: 0,
                                selectedPath: widget.selectedPath,
                                selectedFolderUri: _selectedFolderUri,
                                expandedPaths: _expandedPaths,
                                filter: _searchFilter,
                                inlineCreate: _inlineCreate,
                                renamingPath: _renamingPath,
                                onToggleExpand: (path) {
                                  setState(() {
                                    if (_expandedPaths.contains(path)) {
                                      _expandedPaths.remove(path);
                                    } else {
                                      _expandedPaths.add(path);
                                    }
                                    if (widget.controller != null) {
                                      widget.controller!.expandedPaths.clear();
                                      widget.controller!.expandedPaths.addAll(
                                        _expandedPaths,
                                      );
                                    }
                                  });
                                },
                                onFolderSelected: (folderUri) {
                                  setState(() {
                                    _inlineCreate = null;
                                    _renamingPath = null;
                                    _selectedFolderUri = folderUri;
                                    widget.controller?.selectedFolderUri =
                                        folderUri;
                                  });
                                  widget.onFolderSelected?.call(folderUri);
                                },
                                onFileSelected: (filePath) {
                                  final dir = VaultUri(
                                    path: filePath,
                                  ).directory;
                                  setState(() {
                                    _inlineCreate = null;
                                    _renamingPath = null;
                                    _selectedFolderUri = VaultUri(path: dir);
                                    widget.controller?.selectedFolderUri =
                                        VaultUri(path: dir);
                                  });
                                  widget.onFileSelected?.call(filePath);
                                },
                                onStartCreate: _startCreate,
                                onCreateCommit: _submitInlineCreate,
                                onCreateCancel: _cancelInlineCreate,
                                onStartRename: _startRename,
                                onRenameCommit: _submitInlineRename,
                                onRenameCancel: _cancelInlineRename,
                                onMoveNode: _moveNode,
                                ref: ref,
                              ),
                            ),
                      ]),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: DragTarget<VaultTreeNode>(
                      onWillAcceptWithDetails: (details) {
                        return details.data.uri.directory.isNotEmpty;
                      },
                      onAcceptWithDetails: (details) {
                        _moveNode(details.data, const VaultUri(path: ''));
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovered = candidateData.isNotEmpty;
                        return GestureDetector(
                          key: const Key('vault_tree_empty_space'),
                          behavior: HitTestBehavior.opaque,
                          onTap: _selectRoot,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isHovered
                                  ? const Color(
                                      0xFF04395E,
                                    ).withValues(alpha: 0.3)
                                  : Colors.transparent,
                              border: isHovered
                                  ? Border.all(
                                      color: const Color(
                                        0xFF007ACC,
                                      ).withValues(alpha: 0.6),
                                    )
                                  : null,
                            ),
                            constraints: const BoxConstraints(minHeight: 96),
                            child: isHovered
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Move to Vault Root',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFCCCCCC),
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.tagSummaries.isNotEmpty)
            VaultTreeTopicsSection(
              tagSummaries: widget.tagSummaries,
              filterMode: widget.filterMode,
              activeTagFilter: widget.activeTagFilter,
              onFilterChanged: widget.onFilterChanged,
            ),
        ],
      ),
    );
  }

  bool _matchesFilter(VaultTreeNode node) {
    if (VaultTreeNode.isDrawingSnapshot(node.uri.path)) return false;
    if (_searchFilter.isEmpty) return true;
    if (node.name.toLowerCase().contains(_searchFilter)) return true;
    if (node.isDirectory) {
      return node.children.any((c) => _matchesFilter(c));
    }
    return false;
  }
}
