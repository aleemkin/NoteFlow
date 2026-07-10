import 'package:flutter/material.dart';
import 'package:noteflow/features/document/document.dart';
import 'editor_preview_pane.dart';
import 'editor_raw_pane.dart';
import 'editor_split_divider.dart';

/// Layout coordinating the split view between raw editor and live preview with draggable divider.
class EditorSplitLayout extends StatelessWidget {
  final double splitRatio;
  final ValueChanged<double> onSplitRatioChanged;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final NotebookDocument? document;
  final String? syntaxWarning;
  final void Function(String path)? onEditDrawing;

  const EditorSplitLayout({
    super.key,
    required this.splitRatio,
    required this.onSplitRatioChanged,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.document,
    required this.syntaxWarning,
    this.onEditDrawing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const dividerWidth = 4.0;
        const minPaneWidth = 160.0;
        final maxLeft = (totalWidth - minPaneWidth - dividerWidth).clamp(
          minPaneWidth,
          double.infinity,
        );
        final leftWidth = (totalWidth * splitRatio).clamp(
          minPaneWidth,
          maxLeft,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Raw Markdown Editor
            SizedBox(
              width: leftWidth,
              child: EditorRawPane(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
              ),
            ),

            // Draggable Thin Split Divider
            EditorSplitDivider(
              width: dividerWidth,
              onDragUpdate: (dx) {
                if (totalWidth > 0) {
                  onSplitRatioChanged(
                    (splitRatio + (dx / totalWidth)).clamp(0.15, 0.85),
                  );
                }
              },
            ),

            // Right: Live Synced Preview
            Expanded(
              child: EditorPreviewPane(
                document: document,
                syntaxWarning: syntaxWarning,
                onEditDrawing: onEditDrawing,
              ),
            ),
          ],
        );
      },
    );
  }
}
