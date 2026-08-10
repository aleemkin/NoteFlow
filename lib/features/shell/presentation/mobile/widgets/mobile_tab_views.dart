import 'package:flutter/material.dart';
import 'package:noteflow/features/canvas/presentation/screens/drawing_editor_screen.dart';
import '../mobile_drawings_gallery.dart';
import '../mobile_editor_screen.dart';
import '../mobile_reading_screen.dart';
import '../mobile_vault_details_tab.dart';

/// Hosts the [IndexedStack] coordinating the 4 core mobile tabs:
/// - Tab 0: Continuous Reading Stream
/// - Tab 1: Markdown Editor with horizontal PageView
/// - Tab 2: Canvas (Excalidraw Workspace or Gallery)
/// - Tab 3: Vault Details & Management
class MobileTabViews extends StatelessWidget {
  final int currentTabIndex;
  final String? openedNotePath;
  final String? openedDrawingPath;
  final ScrollController readingScrollController;
  final Map<String, GlobalKey> blockKeys;
  final ValueChanged<String> onOpenFile;
  final VoidCallback onOpenDrawer;
  final VoidCallback onCloseNote;
  final VoidCallback onCloseDrawing;
  final VoidCallback onCreateNote;
  final VoidCallback onCreateDrawing;
  final VoidCallback onOpenVault;
  final VoidCallback onCreateVault;
  final VoidCallback onOpenSampleVault;
  final ValueChanged<String> onOpenVaultPath;
  final VoidCallback onCloseVault;

  const MobileTabViews({
    super.key,
    required this.currentTabIndex,
    required this.openedNotePath,
    required this.openedDrawingPath,
    required this.readingScrollController,
    required this.blockKeys,
    required this.onOpenFile,
    required this.onOpenDrawer,
    required this.onCloseNote,
    required this.onCloseDrawing,
    required this.onCreateNote,
    required this.onCreateDrawing,
    required this.onOpenVault,
    required this.onCreateVault,
    required this.onOpenSampleVault,
    required this.onOpenVaultPath,
    required this.onCloseVault,
  });

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: currentTabIndex,
      children: [
        // Tab 0: Continuous Reading Stream
        MobileReadingScreen(
          onEditDocument: onOpenFile,
          onEditDrawing: onOpenFile,
          onOpenFiles: onOpenDrawer,
          scrollController: readingScrollController,
          blockKeys: blockKeys,
        ),

        // Tab 1: Markdown Editor with horizontal PageView
        MobileEditorScreen(
          documentPath: openedNotePath,
          onClose: onCloseNote,
          onOpenDrawing: onOpenFile,
          onOpenFiles: onOpenDrawer,
          onCreateNote: onCreateNote,
        ),

        // Tab 2: Canvas (Excalidraw Workspace)
        openedDrawingPath != null
            ? DrawingEditorScreen(
                drawingPath: openedDrawingPath!,
                showAppBar: false,
                onClose: onCloseDrawing,
              )
            : MobileDrawingsGallery(
                onOpenDrawing: onOpenFile,
                onCreateDrawing: onCreateDrawing,
              ),

        // Tab 3: Vault Details & Management
        MobileVaultDetailsTab(
          onOpenVault: onOpenVault,
          onCreateVault: onCreateVault,
          onOpenSampleVault: onOpenSampleVault,
          onOpenVaultPath: onOpenVaultPath,
          onCloseVault: onCloseVault,
        ),
      ],
    );
  }
}
