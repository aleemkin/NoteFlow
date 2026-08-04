import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/document.dart';
import 'package:noteflow/features/canvas/presentation/screens/drawing_editor_screen.dart';
import 'package:noteflow/features/editor/presentation/widgets/dual_pane_editor.dart';

/// Center editor panel for desktop layout displaying DualPaneEditor or DrawingEditorScreen.
class DesktopEditorPanel extends ConsumerWidget {
  final GlobalKey<DualPaneEditorState> editorKey;
  final VoidCallback onClose;
  final ValueChanged<String> onOpenDrawing;
  final ValueChanged<List<AtomicUnit>> onUnitsChanged;

  const DesktopEditorPanel({
    super.key,
    required this.editorKey,
    required this.onClose,
    required this.onOpenDrawing,
    required this.onUnitsChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorSessionControllerProvider);
    final selectedFilePath = editorState.selectedFilePath;

    if (selectedFilePath == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select a file from the sidebar to edit',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Markdown files open in side-by-side Raw Editor and Live Preview.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (selectedFilePath.endsWith('.excalidraw')) {
      return DrawingEditorScreen(
        drawingPath: selectedFilePath,
        onClose: onClose,
      );
    }

    return DualPaneEditor(
      key: editorKey,
      documentPath: selectedFilePath,
      onClose: onClose,
      onOpenDrawing: onOpenDrawing,
      onUnitsChanged: onUnitsChanged,
      onSaved: () {
        ref.read(activeFolderControllerProvider.notifier).refresh();
      },
    );
  }
}
