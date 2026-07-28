import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/document.dart';
import 'package:noteflow/features/render/surfaces/document_surface.dart';

/// Right-hand pane in dual pane editor showing the live rendered preview and syntax warnings.
class EditorPreviewPane extends StatelessWidget {
  final NotebookDocument? document;
  final String? syntaxWarning;
  final void Function(String path)? onEditDrawing;

  const EditorPreviewPane({
    super.key,
    this.document,
    this.syntaxWarning,
    this.onEditDrawing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppColors.surfaceCard,
            child: const Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: 6),
                Text(
                  'LIVE SYNCHRONIZED PREVIEW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (syntaxWarning != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: const BoxDecoration(
                color: Color(0x22F59E0B),
                border: Border(bottom: BorderSide(color: Color(0x44F59E0B))),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: AppColors.markImportant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      syntaxWarning!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.markImportant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: document != null
                ? DocumentSurface(
                    document: document!,
                    onEditDrawing: onEditDrawing,
                  )
                : const Center(
                    child: Text(
                      'Preview loading...',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
