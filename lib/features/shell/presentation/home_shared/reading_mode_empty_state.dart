import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';

/// Empty state widget shown when an active folder contains no markdown notes or diagrams.
class ReadingModeEmptyState extends StatelessWidget {
  final VoidCallback onOpenFileManager;

  const ReadingModeEmptyState({super.key, required this.onOpenFileManager});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceCard,
              shape: BoxShape.circle,
            ),
            child: const AppSvgIcon.folder(
              color: AppColors.textMuted,
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notes found in this folder.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first markdown note or drawing diagram.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onOpenFileManager,
            icon: const Icon(Icons.note_add_outlined, size: 16),
            label: const Text('Open File Manager to Create Notes'),
          ),
        ],
      ),
    );
  }
}
