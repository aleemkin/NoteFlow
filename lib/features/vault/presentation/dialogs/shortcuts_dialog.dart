import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';

/// Modal dialog detailing available keyboard shortcuts organized by category.
class ShortcutsDialog extends StatelessWidget {
  const ShortcutsDialog({super.key});

  /// Displays the shortcuts modal dialog.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const ShortcutsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.keyboard_outlined, color: AppColors.primary, size: 20),
          SizedBox(width: 10),
          Text(
            'Keyboard Shortcuts & Hotkeys',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategory(
                title: 'NAVIGATION & SEARCH',
                shortcuts: const [
                  ('Ctrl+K / Cmd+K', 'Open Spotlight Search / Command Palette'),
                  ('Ctrl+O / Cmd+O', 'Open Vault Folder Directory'),
                  (
                    'Ctrl+B / Cmd+B',
                    'Toggle Left Sidebar (Outline / File Tree)',
                  ),
                  ('Ctrl+J / Cmd+J', 'Toggle Right Inspector / Outline Panel'),
                  ('ESC', 'Dismiss Dialogs, Filter Banners, or Selections'),
                ],
              ),
              const SizedBox(height: 14),
              _buildCategory(
                title: 'VIEW MODES',
                shortcuts: const [
                  (
                    'Ctrl+1',
                    'Switch to Reading View (Continuous Folder Stream)',
                  ),
                  ('Ctrl+2', 'Switch to Editor View (Parallel Split Editor)'),
                ],
              ),
              const SizedBox(height: 14),
              _buildCategory(
                title: 'EDITOR & FORMATTING',
                shortcuts: const [
                  ('Ctrl+S / Cmd+S', 'Save Active Document to Disk'),
                  ('Ctrl+B / Cmd+B', 'Wrap selection in **Bold**'),
                  ('Ctrl+I / Cmd+I', 'Wrap selection in *Italic*'),
                  ('Ctrl+K / Cmd+K', 'Insert Markdown Link'),
                  ('Ctrl+Shift+H', 'Insert / Wrap in Important block (@@imp)'),
                  ('Ctrl+Shift+I', 'Insert / Wrap in Info block (@@info)'),
                  ('Ctrl+Shift+T', 'Insert / Wrap in To-Do block (@@todo)'),
                  ('Ctrl+Shift+R', 'Insert / Wrap in Review block (@@review)'),
                  ('Ctrl+Shift+D', 'Insert Drawing Diagram (@@drawing)'),
                ],
              ),
              const SizedBox(height: 14),
              _buildCategory(
                title: 'READING VIEW ACTIONS',
                shortcuts: const [
                  (
                    'Highlight Text',
                    'Reveals floating action toolbar to tag or add diagram',
                  ),
                  ('@@imp Directive', 'Marks section as Key Highlight'),
                  ('@@info Directive', 'Marks section as Reference Note'),
                  (
                    '@@drawing Directive',
                    'Embeds Excalidraw vector diagram inline',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    );
  }

  Widget _buildCategory({
    required String title,
    required List<(String, String)> shortcuts,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceSidebar,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: shortcuts
                .map((s) => _ShortcutRow(shortcut: s.$1, label: s.$2))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final String shortcut;
  final String label;

  const _ShortcutRow({required this.shortcut, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
