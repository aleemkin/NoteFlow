import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/features/document/document.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/features/render/render.dart';
import 'package:noteflow/features/vault/presentation/dialogs/shortcuts_dialog.dart';
import 'package:noteflow/features/vault/presentation/dialogs/vault_dialogs.dart';
import 'package:noteflow/core/notifications/notifications.dart';
import 'package:noteflow/features/shell/presentation/home_shared/home.dart';
import 'package:noteflow/features/editor/presentation/widgets/dual_pane_editor.dart';
import 'package:noteflow/features/editor/presentation/outline/outline_inspector_panel.dart';
import 'package:noteflow/core/widgets/resizable_panel_layout.dart';
import 'package:noteflow/features/search/presentation/search_widget.dart';
import 'package:noteflow/features/vault/presentation/widgets/vault_tree_widget.dart';
import 'package:noteflow/features/shell/presentation/welcome/welcome_view.dart';
import 'package:noteflow/features/vault/vault.dart';
import 'package:noteflow/features/shell/presentation/window_chrome/window_chrome.dart';

import 'desktop_editor_panel.dart';
import 'desktop_reading_panel.dart';

/// Desktop home screen featuring 3-panel resizable layout and custom window chrome.
class DesktopHomeScreen extends ConsumerStatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  ConsumerState<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends ConsumerState<DesktopHomeScreen> {
  final GlobalKey<DualPaneEditorState> _editorKey =
      GlobalKey<DualPaneEditorState>();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _blockKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStartupVault();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initStartupVault() async {
    final currentVault =
        ref.read(currentVaultProvider) ??
        ref.read(vaultSessionControllerProvider).currentVault;
    if (currentVault != null) {
      final treeRepo = ref.read(vaultTreeRepositoryProvider);
      final activeState = ref.read(activeFolderControllerProvider);
      if (treeRepo.root != null && activeState.activeFolder == null) {
        await _loadFolderAndRegisterKeys(treeRepo.root!);
      }
      return;
    }

    final pastPath = await VaultStateStorage.getLastVaultPath();
    if (pastPath != null) {
      try {
        await _doOpenVault(pastPath);
        return;
      } catch (_) {
        // Fallback to welcome screen if opening past vault failed
      }
    }
  }

  Future<void> _loadFolderAndRegisterKeys(VaultTreeNode folderNode) async {
    await ref
        .read(activeFolderControllerProvider.notifier)
        .loadFolder(folderNode);
    final activeState = ref.read(activeFolderControllerProvider);

    // Register stable keys for smooth scroll-to-block navigation
    for (final doc in activeState.documents) {
      _blockKeys['doc_${doc.uri.path}'] ??= GlobalKey();
      _blockKeys['doc_header_${doc.uri.path}'] ??= GlobalKey();
      _blockKeys['doc_${doc.id}'] ??= GlobalKey();
      for (final block in doc.blocks) {
        _blockKeys[block.id] ??= GlobalKey();
      }
    }
    for (final unit in activeState.atomicUnits) {
      _blockKeys[unit.id] ??= GlobalKey();
      _blockKeys[unit.targetBlockId] ??= GlobalKey();
    }
    if (mounted) setState(() {});
  }

  void _scrollToUnit(AtomicUnit unit) {
    ref
        .read(editorSessionControllerProvider.notifier)
        .selectFile(unit.docUri.path);
    final key =
        _blockKeys[unit.targetBlockId] ??
        _blockKeys[unit.id] ??
        _blockKeys['doc_${unit.docUri.path}'] ??
        _blockKeys['doc_header_${unit.docUri.path}'];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onFileSelectedInReading(String path) {
    if (path.endsWith('.excalidraw')) {
      final parentDir = VaultUri(path: path).directory;
      final treeRepo = ref.read(vaultTreeRepositoryProvider);
      final folderNode = treeRepo.findNode(VaultUri(path: parentDir));
      if (folderNode != null &&
          ref.read(activeFolderControllerProvider).activeFolder == null) {
        ref
            .read(activeFolderControllerProvider.notifier)
            .loadFolder(folderNode);
      }
      ref
          .read(editorSessionControllerProvider.notifier)
          .switchToEditMode(filePath: path);
      return;
    }

    ref.read(editorSessionControllerProvider.notifier).selectFile(path);

    // If viewing tagged content, clear the filter so the selected note is visible in the viewer stream.
    final activeNotifier = ref.read(activeFolderControllerProvider.notifier);
    if (ref.read(activeFolderControllerProvider).filterMode !=
        ScrollFilterMode.all) {
      activeNotifier.clearFilter();
    }

    final parentDir = VaultUri(path: path).directory;
    final activeFolder = ref.read(activeFolderControllerProvider).activeFolder;
    final isSameFolder =
        activeFolder != null && activeFolder.uri.path == parentDir;

    if (isSameFolder) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _blockKeys['doc_$path'] ?? _blockKeys['doc_header_$path'];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      });
      return;
    }

    final treeRepo = ref.read(vaultTreeRepositoryProvider);
    final folderNode = treeRepo.findNode(VaultUri(path: parentDir));
    if (folderNode != null) {
      _loadFolderAndRegisterKeys(folderNode).then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final delayedKey =
              _blockKeys['doc_$path'] ?? _blockKeys['doc_header_$path'];
          if (delayedKey?.currentContext != null) {
            Scrollable.ensureVisible(
              delayedKey!.currentContext!,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
          }
        });
      });
    }
  }

  Future<void> _openVault(BuildContext context) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Vault Folder',
      );
      if (result != null) {
        await _doOpenVault(result);
      }
    } catch (e) {
      if (context.mounted) {
        AppNotification.showError(
          context,
          'Unable to open vault directory: $e',
          title: 'Vault Open Error',
        );
      }
    }
  }

  Future<void> _createVault(BuildContext context) async {
    try {
      final createdPath = await VaultDialogs.showCreateVaultDialog(context);
      if (createdPath != null && mounted) {
        await _doOpenVault(createdPath);
        if (context.mounted) {
          AppNotification.showSuccess(
            context,
            'Vault "${p.basename(createdPath)}" created successfully',
            title: 'Vault Created',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppNotification.showError(
          context,
          'Failed to create vault: $e',
          title: 'Vault Creation Error',
        );
      }
    }
  }

  Future<void> _openSampleVault() async {
    final manager = ref.read(vaultManagerProvider);
    await manager.openSampleVault();
    ref.read(currentVaultProvider.notifier).state = manager.currentVault;
    ref.read(editorSessionControllerProvider.notifier).switchToReadingMode();

    final treeRepo = ref.read(vaultTreeRepositoryProvider);
    if (treeRepo.root != null) {
      await _loadFolderAndRegisterKeys(treeRepo.root!);
      final activeState = ref.read(activeFolderControllerProvider);
      if (activeState.documents.isNotEmpty) {
        ref
            .read(editorSessionControllerProvider.notifier)
            .selectFile(activeState.documents.first.uri.path);
      }
    }
  }

  Future<void> _doOpenVault(String path) async {
    final manager = ref.read(vaultManagerProvider);
    await manager.openLocalVault(path);
    ref.read(currentVaultProvider.notifier).state = manager.currentVault;
    await VaultStateStorage.saveLastVaultPath(path);
    ref.read(editorSessionControllerProvider.notifier).switchToReadingMode();

    final treeRepo = ref.read(vaultTreeRepositoryProvider);
    if (treeRepo.root != null) {
      await _loadFolderAndRegisterKeys(treeRepo.root!);
      final activeState = ref.read(activeFolderControllerProvider);
      if (activeState.documents.isNotEmpty) {
        ref
            .read(editorSessionControllerProvider.notifier)
            .selectFile(activeState.documents.first.uri.path);
      }
    }
  }

  Future<void> _closeVault() async {
    await ref.read(vaultSessionControllerProvider.notifier).closeVault();
  }

  @override
  Widget build(BuildContext context) {
    final vault =
        ref.watch(currentVaultProvider) ??
        ref.watch(vaultSessionControllerProvider).currentVault;
    final isOpen = vault != null;
    final editorState = ref.watch(editorSessionControllerProvider);
    final activeFolderState = ref.watch(activeFolderControllerProvider);
    final editorNotifier = ref.read(editorSessionControllerProvider.notifier);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          SpotlightSearchDialog.show(
            context,
            (path) => editorNotifier.switchToEditMode(filePath: path),
          );
        },
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          SpotlightSearchDialog.show(
            context,
            (path) => editorNotifier.switchToEditMode(filePath: path),
          );
        },
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
            _openVault(context),
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true): () =>
            _openVault(context),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            _createVault(context),
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
            _createVault(context),
        const SingleActivator(LogicalKeyboardKey.digit1, control: true):
            editorNotifier.switchToReadMode,
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
            editorNotifier.switchToEditMode(),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true):
            editorNotifier.toggleLeftPanel,
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true):
            editorNotifier.toggleLeftPanel,
        const SingleActivator(LogicalKeyboardKey.keyJ, control: true):
            editorNotifier.toggleRightPanel,
        const SingleActivator(LogicalKeyboardKey.keyJ, meta: true):
            editorNotifier.toggleRightPanel,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              if (!isOpen)
                const WelcomeWindowChrome()
              else
                WindowChrome(
                  viewMode: editorState.viewMode,
                  onViewModeChanged: editorNotifier.setViewMode,
                  vaultName: vault.displayName,
                  onVaultTap: () => _openVault(context),
                  onSearchTapped: () => SpotlightSearchDialog.show(
                    context,
                    (path) => editorNotifier.switchToEditMode(filePath: path),
                  ),
                  isLeftSidebarOpen: editorState.isLeftPanelOpen,
                  isRightSidebarOpen: editorState.isRightPanelOpen,
                  isFullscreen: editorState.isFullscreen,
                  onToggleLeftSidebar: editorNotifier.toggleLeftPanel,
                  onToggleRightSidebar: editorNotifier.toggleRightPanel,
                  onToggleFullscreen: editorNotifier.toggleFullscreen,
                  onOpenVault: () => _openVault(context),
                  onCreateVault: () => _createVault(context),
                  onOpenSampleVault: _openSampleVault,
                  onRefreshFolder: () => ref
                      .read(activeFolderControllerProvider.notifier)
                      .refresh(),
                  onCopyTaggedRoll: () {
                    HomeScreenActions.copyTaggedRoll(
                      context: context,
                      folderDocuments: activeFolderState.documents,
                      scrollFilter: activeFolderState.filterMode,
                      customTagFilter: activeFolderState.customTagFilter,
                      activeFolder: activeFolderState.activeFolder,
                    );
                  },
                  onExportTaggedRoll: () {
                    HomeScreenActions.exportTaggedRoll(
                      context: context,
                      ref: ref,
                      folderDocuments: activeFolderState.documents,
                      scrollFilter: activeFolderState.filterMode,
                      customTagFilter: activeFolderState.customTagFilter,
                      activeFolder: activeFolderState.activeFolder,
                      reloadFolder: (folder) => ref
                          .read(activeFolderControllerProvider.notifier)
                          .loadFolder(folder),
                    );
                  },
                  onShowShortcuts: () => ShortcutsDialog.show(context),
                  onCloseVault: _closeVault,
                  isEditMode: editorState.isEditMode,
                ),
              Expanded(
                child: !isOpen
                    ? WelcomeView(
                        onOpenVault: () => _openVault(context),
                        onCreateVault: () => _createVault(context),
                        onOpenVaultPath: _doOpenVault,
                        onOpenSampleVault: _openSampleVault,
                      )
                    : ResizablePanelLayout(
                        leftPanel: editorState.isLeftPanelOpen
                            ? VaultTreeWidget(
                                selectedPath: editorState.selectedFilePath,
                                onFileSelected: editorState.isEditMode
                                    ? (path) => editorNotifier.selectFile(path)
                                    : _onFileSelectedInReading,
                                onFolderSelected: (uri) {
                                  final treeRepo = ref.read(
                                    vaultTreeRepositoryProvider,
                                  );
                                  final node = treeRepo.findNode(uri);
                                  if (node != null && node.isDirectory) {
                                    if (ref
                                            .read(
                                              activeFolderControllerProvider,
                                            )
                                            .filterMode !=
                                        ScrollFilterMode.all) {
                                      ref
                                          .read(
                                            activeFolderControllerProvider
                                                .notifier,
                                          )
                                          .clearFilter();
                                    }
                                    _loadFolderAndRegisterKeys(node);
                                    if (editorState.isEditMode) {
                                      final firstNote = node.children.firstWhere(
                                        (c) =>
                                            !c.isDirectory &&
                                            !VaultTreeNode.isDrawingSnapshot(
                                              c.uri.path,
                                            ),
                                        orElse: () => node.children.isEmpty
                                            ? node
                                            : node.children.first,
                                      );
                                      if (!firstNote.isDirectory) {
                                        editorNotifier.selectFile(
                                          firstNote.uri.path,
                                        );
                                      }
                                    }
                                  }
                                },
                                tagSummaries: activeFolderState.tagSummaries,
                                filterMode: activeFolderState.filterMode,
                                activeTagFilter:
                                    activeFolderState.customTagFilter,
                                onFilterChanged: (mode, tag) {
                                  ref
                                      .read(
                                        activeFolderControllerProvider.notifier,
                                      )
                                      .setFilter(mode, tag);
                                },
                              )
                            : null,
                        initialLeftWidth: 250,
                        minLeftWidth: 160,
                        maxLeftWidth: 400,
                        centerPanel: editorState.isEditMode
                            ? DesktopEditorPanel(
                                editorKey: _editorKey,
                                onClose: editorNotifier.switchToReadMode,
                                onOpenDrawing: (path) => editorNotifier
                                    .switchToEditMode(filePath: path),
                                onUnitsChanged: (units) =>
                                    editorNotifier.updateEditDocUnits(units),
                              )
                            : DesktopReadingPanel(
                                scrollController: _scrollController,
                                blockKeys: _blockKeys,
                                onEditDocument: (path) => editorNotifier
                                    .switchToEditMode(filePath: path),
                                onEditDrawing: (path) => editorNotifier
                                    .switchToEditMode(filePath: path),
                                onOpenFileManager: () =>
                                    editorNotifier.switchToEditMode(),
                              ),
                        rightPanel: editorState.isRightPanelOpen
                            ? (editorState.isEditMode
                                  ? EditModeOutlinePanel(
                                      selectedFilePath:
                                          editorState.selectedFilePath,
                                      activeFolder:
                                          activeFolderState.activeFolder,
                                      editDocUnits: editorState.editDocUnits,
                                      onUnitSelected: (unit) => _editorKey
                                          .currentState
                                          ?.jumpToUnit(unit),
                                      onUnitsReordered: (newUnits) async {
                                        _editorKey.currentState
                                            ?.applyReorderedUnits(newUnits);
                                      },
                                    )
                                  : (activeFolderState.activeFolder != null
                                        ? OutlineInspectorPanel(
                                            folderNode:
                                                activeFolderState.activeFolder!,
                                            units:
                                                activeFolderState.atomicUnits,
                                            onUnitsReordered: (newUnits) async {
                                              await HomeScreenActions.onUnitsReordered(
                                                context: context,
                                                ref: ref,
                                                orderedFolderFiles:
                                                    activeFolderState
                                                        .orderedFiles,
                                                folderDocuments:
                                                    activeFolderState.documents,
                                                activeFolder: activeFolderState
                                                    .activeFolder,
                                                newUnits: newUnits,
                                                reloadFolder: (folder) => ref
                                                    .read(
                                                      activeFolderControllerProvider
                                                          .notifier,
                                                    )
                                                    .loadFolder(folder),
                                              );
                                            },
                                            onUnitSelected: _scrollToUnit,
                                          )
                                        : null))
                            : null,
                        initialRightWidth: 260,
                        minRightWidth: 180,
                        maxRightWidth: 400,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
