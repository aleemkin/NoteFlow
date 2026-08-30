import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/document.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/features/render/render.dart';
import 'package:noteflow/features/vault/presentation/dialogs/vault_dialogs.dart';
import 'package:noteflow/core/notifications/notifications.dart';
import 'package:noteflow/features/search/presentation/search_widget.dart';
import 'package:noteflow/features/vault/presentation/widgets/vault_tree_widget.dart';
import 'package:noteflow/features/vault/vault.dart';

import 'mobile_welcome_view.dart';
import 'widgets/widgets.dart';

/// Top-level Home Screen designed for Android mobile & tablet devices.
///
/// Features:
/// - Top AppBar leading button [FolderIcon] [Vault Name] [▾] opens the Left Drawer (desktop left panel)
/// - Top AppBar search button triggers SpotlightSearchDialog
/// - Top AppBar right button opens Right Drawer (desktop outline & inspector)
/// - Bottom navigation bar with 4 dedicated destinations:
///   1. **Reading**: Continuous document roll for the active folder
///   2. **Editor**: Markdown editor with horizontal PageView (Edit pane & Live Preview)
///   3. **Canvas**: Excalidraw editor or diagrams gallery
///   4. **Vault**: Current vault metrics & desktop landing features
/// - Responsive layout: NavigationBar on phones (<720dp), NavigationRail on tablets (>=720dp)
/// - Predictive Android back button handling via [PopScope]
class MobileHomeScreen extends ConsumerStatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  ConsumerState<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends ConsumerState<MobileHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _readingScrollController = ScrollController();
  final Map<String, GlobalKey> _blockKeys = {};

  int _currentTabIndex = 0;
  String? _openedNotePath;
  String? _openedDrawingPath;
  String? _lastSyncedSelectedFilePath;
  late final VaultTreeController _vaultTreeController;
  InlineCreateType? _pendingCreateType;
  bool _isLoadingVault = false;
  String _loadingMessage = 'Loading...';

  void _closeDrawing() {
    setState(() {
      _openedDrawingPath = null;
      _lastSyncedSelectedFilePath = null;
    });
    ref.read(editorSessionControllerProvider.notifier).selectFile(null);
  }

  void _closeNote() {
    setState(() {
      _openedNotePath = null;
      _lastSyncedSelectedFilePath = null;
    });
    ref.read(editorSessionControllerProvider.notifier).selectFile(null);
  }

  @override
  void initState() {
    super.initState();
    _vaultTreeController = VaultTreeController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStartup();
    });
  }

  @override
  void dispose() {
    _vaultTreeController.dispose();
    _readingScrollController.dispose();
    super.dispose();
  }

  Future<void> _initStartup() async {
    final currentVault =
        ref.read(currentVaultProvider) ??
        ref.read(vaultSessionControllerProvider).currentVault;
    if (currentVault != null) {
      final treeRepo = ref.read(vaultTreeRepositoryProvider);
      final activeFolderState = ref.read(activeFolderControllerProvider);
      if (treeRepo.root != null && activeFolderState.activeFolder == null) {
        await _loadFolderAndRegisterKeys(treeRepo.root!);
      }
      return;
    }

    final sessionNotifier = ref.read(vaultSessionControllerProvider.notifier);
    await sessionNotifier.initStartupVault();

    final treeRepo = ref.read(vaultTreeRepositoryProvider);
    final activeFolderState = ref.read(activeFolderControllerProvider);
    if (treeRepo.root != null && activeFolderState.activeFolder == null) {
      await _loadFolderAndRegisterKeys(treeRepo.root!);
    }
  }

  Future<void> _loadFolderAndRegisterKeys(VaultTreeNode folderNode) async {
    await ref
        .read(activeFolderControllerProvider.notifier)
        .loadFolder(folderNode);
    final activeState = ref.read(activeFolderControllerProvider);

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

  void _switchTab(int index) {
    if (index == _currentTabIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentTabIndex = index;
    });
  }

  void _openFile(String path) {
    HapticFeedback.selectionClick();
    _lastSyncedSelectedFilePath = path;
    if (path.endsWith('.excalidraw')) {
      setState(() {
        _openedDrawingPath = path;
        _currentTabIndex = 2; // Canvas tab
      });
      ref
          .read(editorSessionControllerProvider.notifier)
          .selectFile(path, switchToEdit: true);
    } else {
      setState(() {
        _openedNotePath = path;
        _currentTabIndex = 1; // Editor tab
      });
      ref
          .read(editorSessionControllerProvider.notifier)
          .selectFile(path, switchToEdit: true);
    }
  }

  void _onFileSelectedInNotes(String path) {
    if (path.endsWith('.excalidraw')) {
      _openFile(path);
      return;
    }

    HapticFeedback.selectionClick();
    _lastSyncedSelectedFilePath = path;
    _openedNotePath = path;
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

  Future<void> _openVault() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Vault Folder',
      );
      if (result != null && mounted) {
        setState(() {
          _isLoadingVault = true;
          _loadingMessage = 'Opening vault...';
        });
        await _doOpenVault(result);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(
          context,
          'Unable to open vault directory: $e',
          title: 'Vault Open Error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVault = false;
        });
      }
    }
  }

  Future<void> _createVault() async {
    try {
      final createdPath = await VaultDialogs.showCreateVaultDialog(context);
      if (createdPath != null && mounted) {
        setState(() {
          _isLoadingVault = true;
          _loadingMessage = 'Opening new vault...';
        });
        await _doOpenVault(createdPath);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(
          context,
          'Failed to create vault: $e',
          title: 'Vault Creation Error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVault = false;
        });
      }
    }
  }

  Future<void> _openSampleVault() async {
    try {
      setState(() {
        _isLoadingVault = true;
        _loadingMessage = 'Preparing sample vault...';
      });
      final manager = ref.read(vaultManagerProvider);
      await manager.openSampleVault();
      ref.read(currentVaultProvider.notifier).state = manager.currentVault;
      setState(() {
        _currentTabIndex = 0; // Open in Notes tab
        _openedNotePath = null;
        _openedDrawingPath = null;
        _lastSyncedSelectedFilePath = null;
      });
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
    } catch (e) {
      if (mounted) {
        AppNotification.showError(
          context,
          'Failed to open sample vault: $e',
          title: 'Sample Vault Error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVault = false;
        });
      }
    }
  }

  Future<void> _doOpenVault(String path) async {
    setState(() {
      _isLoadingVault = true;
      _loadingMessage = 'Opening vault...';
    });
    try {
      final manager = ref.read(vaultManagerProvider);
      await manager.openLocalVault(path);
      ref.read(currentVaultProvider.notifier).state = manager.currentVault;
      await VaultStateStorage.saveLastVaultPath(path);
      setState(() {
        _currentTabIndex = 0; // Open in Notes tab
        _openedNotePath = null;
        _openedDrawingPath = null;
        _lastSyncedSelectedFilePath = null;
      });

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
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVault = false;
        });
      }
    }
  }

  Future<void> _closeVault() async {
    setState(() {
      _openedNotePath = null;
      _openedDrawingPath = null;
      _lastSyncedSelectedFilePath = null;
    });
    await ref.read(vaultSessionControllerProvider.notifier).closeVault();
  }

  void _openLeftDrawerForNoteCreation() {
    HapticFeedback.lightImpact();
    setState(() {
      _pendingCreateType = InlineCreateType.note;
    });
    _scaffoldKey.currentState?.openDrawer();
    _vaultTreeController.startCreate(InlineCreateType.note);
  }

  void _openLeftDrawerForDrawingCreation() {
    HapticFeedback.lightImpact();
    setState(() {
      _pendingCreateType = InlineCreateType.drawing;
    });
    _scaffoldKey.currentState?.openDrawer();
    _vaultTreeController.startCreate(InlineCreateType.drawing);
  }

  void _onNotesFabPressed() => _openLeftDrawerForNoteCreation();

  Widget _buildLeftDrawer(BuildContext context) {
    return MobileLeftDrawer(
      controller: _vaultTreeController,
      initialCreateType: _pendingCreateType,
      onFileSelected: (path) {
        Navigator.pop(context);
        if (path.endsWith('.excalidraw')) {
          _openFile(path);
        } else if (_currentTabIndex == 1) {
          _openFile(path);
        } else {
          _switchTab(0);
          _onFileSelectedInNotes(path);
        }
      },
      onFolderSelected: (uri) {
        final treeRepo = ref.read(vaultTreeRepositoryProvider);
        final node = treeRepo.findNode(uri);
        if (node != null && node.isDirectory) {
          if (ref.read(activeFolderControllerProvider).filterMode !=
              ScrollFilterMode.all) {
            ref.read(activeFolderControllerProvider.notifier).clearFilter();
          }
          _loadFolderAndRegisterKeys(node);
          if (_currentTabIndex == 1) {
            final firstNote = node.children.firstWhere(
              (c) =>
                  !c.isDirectory &&
                  !VaultTreeNode.isDrawingSnapshot(c.uri.path),
              orElse: () => node.children.isEmpty ? node : node.children.first,
            );
            if (!firstNote.isDirectory) {
              _openFile(firstNote.uri.path);
            }
          } else {
            _switchTab(0);
          }
        }
      },
    );
  }

  Widget _buildRightDrawer(BuildContext context) {
    return MobileRightDrawer(
      currentTabIndex: _currentTabIndex,
      onScrollToUnit: _scrollToUnit,
      onSwitchToReadingTab: () => _switchTab(0),
    );
  }

  Widget _buildLoadingOverlay() {
    return MobileLoadingOverlay(message: _loadingMessage);
  }

  @override
  Widget build(BuildContext context) {
    final vault =
        ref.watch(currentVaultProvider) ??
        ref.watch(vaultSessionControllerProvider).currentVault;
    final isOpen = vault != null;
    final editorState = ref.watch(editorSessionControllerProvider);

    // Sync external file selection
    if (editorState.selectedFilePath != _lastSyncedSelectedFilePath) {
      _lastSyncedSelectedFilePath = editorState.selectedFilePath;
      if (editorState.selectedFilePath != null) {
        if (editorState.selectedFilePath!.endsWith('.excalidraw')) {
          _openedDrawingPath = editorState.selectedFilePath;
        } else {
          _openedNotePath = editorState.selectedFilePath;
        }
      }
    }

    if (!isOpen) {
      return Stack(
        children: [
          MobileWelcomeView(
            onOpenVault: _openVault,
            onCreateVault: _createVault,
            onOpenVaultPath: _doOpenVault,
            onOpenSampleVault: _openSampleVault,
          ),
          if (_isLoadingVault) _buildLoadingOverlay(),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTabletLandscape = constraints.maxWidth >= 720;

        return PopScope(
          canPop: _currentTabIndex == 0 && _openedDrawingPath == null,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            } else if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
              Navigator.pop(context);
            } else if (_currentTabIndex == 2 && _openedDrawingPath != null) {
              _closeDrawing();
            } else if (_currentTabIndex == 1 && _openedNotePath != null) {
              _closeNote();
            } else if (_currentTabIndex != 0) {
              _switchTab(0);
            }
          },
          child: Stack(
            children: [
              Scaffold(
                key: _scaffoldKey,
                onDrawerChanged: (isOpen) {
                  setState(() {
                    if (!isOpen) {
                      _pendingCreateType = null;
                    }
                  });
                },
                onEndDrawerChanged: (_) => setState(() {}),
                appBar: _currentTabIndex == 3
                    ? null
                    : MobileHomeAppBar(
                        currentTabIndex: _currentTabIndex,
                        openedNotePath: _openedNotePath,
                        openedDrawingPath: _openedDrawingPath,
                        onCloseNote: _closeNote,
                        onCloseDrawing: _closeDrawing,
                        onOpenDrawer: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                        onOpenEndDrawer: () =>
                            _scaffoldKey.currentState?.openEndDrawer(),
                        onCloseEndDrawer: () => Navigator.pop(context),
                        isEndDrawerOpen:
                            _scaffoldKey.currentState?.isEndDrawerOpen ?? false,
                        onSearchTap: () {
                          SpotlightSearchDialog.show(context, (path) {
                            if (path.endsWith('.excalidraw')) {
                              _openFile(path);
                            } else if (_currentTabIndex == 1) {
                              _openFile(path);
                            } else {
                              _switchTab(0);
                              _onFileSelectedInNotes(path);
                            }
                          });
                        },
                      ),
                drawer: _buildLeftDrawer(context),
                endDrawer: _buildRightDrawer(context),
                endDrawerEnableOpenDragGesture: _currentTabIndex != 2,
                floatingActionButton: _currentTabIndex == 0
                    ? FloatingActionButton.small(
                        onPressed: _onNotesFabPressed,
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        child: const Icon(Icons.add_rounded, size: 28),
                      )
                    : null,
                body: Row(
                  children: [
                    if (isTabletLandscape)
                      MobileNavigationRail(
                        currentIndex: _currentTabIndex,
                        onDestinationSelected: _switchTab,
                      ),
                    Expanded(
                      child: MobileTabViews(
                        currentTabIndex: _currentTabIndex,
                        openedNotePath: _openedNotePath,
                        openedDrawingPath: _openedDrawingPath,
                        readingScrollController: _readingScrollController,
                        blockKeys: _blockKeys,
                        onOpenFile: _openFile,
                        onOpenDrawer: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                        onCloseNote: _closeNote,
                        onCloseDrawing: _closeDrawing,
                        onCreateNote: _openLeftDrawerForNoteCreation,
                        onCreateDrawing: _openLeftDrawerForDrawingCreation,
                        onOpenVault: _openVault,
                        onCreateVault: _createVault,
                        onOpenSampleVault: _openSampleVault,
                        onOpenVaultPath: _doOpenVault,
                        onCloseVault: _closeVault,
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: isTabletLandscape
                    ? null
                    : MobileBottomNavBar(
                        currentIndex: _currentTabIndex,
                        onDestinationSelected: _switchTab,
                      ),
              ),
              if (_isLoadingVault) _buildLoadingOverlay(),
            ],
          ),
        );
      },
    );
  }
}
