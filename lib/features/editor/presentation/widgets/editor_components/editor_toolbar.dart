import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'editor_auto_save_status.dart';
import 'editor_toolbar_buttons.dart';

/// Top bar for the parallel markdown editor containing formatting tools, title, word count, and auto-save status.
class EditorToolbar extends StatelessWidget {
  final String documentPath;
  final String? documentTitle;
  final int wordCount;
  final bool isSaving;
  final bool isDirty;
  final String? saveError;
  final String? syntaxWarning;
  final VoidCallback? onClose;
  final void Function(String prefix, [String suffix]) onWrapSelection;
  final void Function(String tagType) onApplyTagTemplate;
  final VoidCallback onInsertTable;
  final VoidCallback onInsertLink;
  final VoidCallback onInsertImage;
  final VoidCallback onInsertHorizontalRule;
  final VoidCallback onInsertDrawingDirective;
  final VoidCallback onInsertViewDirective;
  final Future<void> Function()? onAutoSave;

  const EditorToolbar({
    super.key,
    required this.documentPath,
    this.documentTitle,
    required this.wordCount,
    required this.isSaving,
    required this.isDirty,
    this.saveError,
    this.syntaxWarning,
    this.onClose,
    required this.onWrapSelection,
    required this.onApplyTagTemplate,
    required this.onInsertTable,
    required this.onInsertLink,
    required this.onInsertImage,
    required this.onInsertHorizontalRule,
    required this.onInsertDrawingDirective,
    required this.onInsertViewDirective,
    this.onAutoSave,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final fileName = documentPath.contains('/')
            ? documentPath.split('/').last
            : documentPath;

        return Material(
          color: AppColors.surfaceCard,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 16),
                    tooltip: 'Back to folder roll (Ctrl+1)',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    onPressed: () async {
                      if (isDirty) {
                        await onAutoSave?.call();
                      }
                      onClose?.call();
                    },
                  ),
                const SizedBox(width: 4),

                const Icon(Icons.edit_note, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Flexible(
                  flex: 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth < 650
                          ? 90
                          : (constraints.maxWidth < 850 ? 120 : 160),
                    ),
                    child: Text(
                      documentTitle ?? fileName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                if (constraints.maxWidth >= 850) ...[
                  const SizedBox(width: 8),
                  Text(
                    '$wordCount words',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],

                const SizedBox(width: 8),

                // Markdown Formatting & Insert Tools
                Expanded(
                  child: isCompact
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: _buildCompactToolsMenu(context),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Headings
                              FormatButton(
                                text: 'H1',
                                tooltip: 'Heading 1 (#)',
                                onTap: () => onWrapSelection('# '),
                              ),
                              FormatButton(
                                text: 'H2',
                                tooltip: 'Heading 2 (##)',
                                onTap: () => onWrapSelection('## '),
                              ),
                              FormatButton(
                                text: 'H3',
                                tooltip: 'Heading 3 (###)',
                                onTap: () => onWrapSelection('### '),
                              ),
                              const ToolbarDivider(),

                              // Typography
                              FormatButton(
                                icon: Icons.format_bold,
                                tooltip: 'Bold (Ctrl+B)',
                                onTap: () => onWrapSelection('**', '**'),
                              ),
                              FormatButton(
                                icon: Icons.format_italic,
                                tooltip: 'Italic (Ctrl+I)',
                                onTap: () => onWrapSelection('*', '*'),
                              ),
                              FormatButton(
                                icon: Icons.format_strikethrough,
                                tooltip: 'Strikethrough (~~)',
                                onTap: () => onWrapSelection('~~', '~~'),
                              ),
                              FormatButton(
                                icon: Icons.code,
                                tooltip: 'Inline Code (`)',
                                onTap: () => onWrapSelection('`', '`'),
                              ),
                              const ToolbarDivider(),

                              // Lists & Blocks
                              FormatButton(
                                icon: Icons.format_quote,
                                tooltip: 'Blockquote (>)',
                                onTap: () => onWrapSelection('> '),
                              ),
                              FormatButton(
                                icon: Icons.terminal,
                                tooltip: 'Code Block (```)',
                                onTap: () => onWrapSelection('```\n', '\n```'),
                              ),
                              FormatButton(
                                icon: Icons.format_list_bulleted,
                                tooltip: 'Bullet List (-)',
                                onTap: () => onWrapSelection('- '),
                              ),
                              FormatButton(
                                icon: Icons.format_list_numbered,
                                tooltip: 'Numbered List (1.)',
                                onTap: () => onWrapSelection('1. '),
                              ),
                              FormatButton(
                                icon: Icons.checklist,
                                tooltip: 'Task Checklist (- [ ])',
                                onTap: () => onWrapSelection('- [ ] '),
                              ),
                              FormatButton(
                                icon: Icons.table_chart_outlined,
                                tooltip: 'Insert Table',
                                onTap: onInsertTable,
                              ),
                              FormatButton(
                                icon: Icons.horizontal_rule,
                                tooltip: 'Horizontal Divider (---)',
                                onTap: onInsertHorizontalRule,
                              ),
                              const ToolbarDivider(),

                              // Inserts
                              FormatButton(
                                icon: Icons.link,
                                tooltip: 'Insert Link (Ctrl+K)',
                                onTap: onInsertLink,
                              ),
                              FormatButton(
                                icon: Icons.image_outlined,
                                tooltip: 'Insert Image',
                                onTap: onInsertImage,
                              ),
                              const ToolbarDivider(),

                              // Semantic Tags & Directives
                              FormatButton(
                                icon: Icons.star_rounded,
                                iconColor: AppColors.markImportant,
                                tooltip:
                                    'Important Block (@@imp) (Ctrl+Shift+H)',
                                onTap: () => onApplyTagTemplate('imp'),
                              ),
                              FormatButton(
                                icon: Icons.info_outline,
                                iconColor: AppColors.markInfo,
                                tooltip:
                                    'Info Reference (@@info) (Ctrl+Shift+I)',
                                onTap: () => onApplyTagTemplate('info'),
                              ),
                              FormatButton(
                                icon: Icons.check_circle_outline,
                                iconColor: AppColors.secondary,
                                tooltip: 'To-Do Task (@@todo) (Ctrl+Shift+T)',
                                onTap: () => onApplyTagTemplate('todo'),
                              ),
                              FormatButton(
                                icon: Icons.rate_review_outlined,
                                iconColor: AppColors.accent,
                                tooltip:
                                    'Review Block (@@review) (Ctrl+Shift+R)',
                                onTap: () => onApplyTagTemplate('review'),
                              ),
                              FormatButton(
                                icon: Icons.tag,
                                iconColor: AppColors.markTag,
                                tooltip: 'Tag Section (@@tag)',
                                onTap: () => onApplyTagTemplate('tag'),
                              ),
                              FormatButton(
                                icon: Icons.draw_outlined,
                                iconColor: AppColors.markDiagram,
                                tooltip:
                                    'Insert Drawing Diagram (@@drawing) (Ctrl+Shift+D)',
                                onTap: onInsertDrawingDirective,
                              ),
                              FormatButton(
                                icon: Icons.preview_outlined,
                                iconColor: AppColors.accentCyan,
                                tooltip: 'Preview Tagged Block (@@view)',
                                onTap: onInsertViewDirective,
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(width: 8),

                // Manual Save button when dirty
                if (isDirty) ...[
                  FilledButton.icon(
                    onPressed: onAutoSave,
                    icon: const Icon(Icons.save_rounded, size: 12),
                    label: Text(
                      constraints.maxWidth < 650 ? 'Save' : 'Save (Ctrl+S)',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      minimumSize: const Size(0, 26),
                      textStyle: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Auto-save & syntax status indicator
                EditorAutoSaveStatus(
                  saveError: saveError,
                  syntaxWarning: syntaxWarning,
                  isSaving: isSaving,
                  isDirty: isDirty,
                  isCompact: constraints.maxWidth < 800,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactToolsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Formatting & Insert Tools',
      icon: const Icon(
        Icons.add_box_outlined,
        size: 16,
        color: AppColors.primary,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
      onSelected: (val) {
        switch (val) {
          case 'h1':
            onWrapSelection('# ');
          case 'h2':
            onWrapSelection('## ');
          case 'h3':
            onWrapSelection('### ');
          case 'bold':
            onWrapSelection('**', '**');
          case 'italic':
            onWrapSelection('*', '*');
          case 'strikethrough':
            onWrapSelection('~~', '~~');
          case 'code_inline':
            onWrapSelection('`', '`');
          case 'quote':
            onWrapSelection('> ');
          case 'code_block':
            onWrapSelection('```\n', '\n```');
          case 'bullet':
            onWrapSelection('- ');
          case 'numbered':
            onWrapSelection('1. ');
          case 'checklist':
            onWrapSelection('- [ ] ');
          case 'table':
            onInsertTable();
          case 'divider':
            onInsertHorizontalRule();
          case 'link':
            onInsertLink();
          case 'image':
            onInsertImage();
          case 'tag_imp':
            onApplyTagTemplate('imp');
          case 'tag_info':
            onApplyTagTemplate('info');
          case 'tag_todo':
            onApplyTagTemplate('todo');
          case 'tag_review':
            onApplyTagTemplate('review');
          case 'tag_custom':
          case 'tag':
            onApplyTagTemplate('tag');
          case 'draw':
            onInsertDrawingDirective();
          case 'view':
            onInsertViewDirective();
        }
      },
      itemBuilder: (ctx) => const [
        PopupMenuItem(value: 'h1', child: Text('# Heading 1')),
        PopupMenuItem(value: 'h2', child: Text('## Heading 2')),
        PopupMenuItem(value: 'h3', child: Text('### Heading 3')),
        PopupMenuItem(value: 'bold', child: Text('**Bold** (Ctrl+B)')),
        PopupMenuItem(value: 'italic', child: Text('*Italic* (Ctrl+I)')),
        PopupMenuItem(value: 'strikethrough', child: Text('~~Strikethrough~~')),
        PopupMenuItem(value: 'code_inline', child: Text('`Inline Code`')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'quote', child: Text('> Blockquote')),
        PopupMenuItem(value: 'code_block', child: Text('```Code Block```')),
        PopupMenuItem(value: 'bullet', child: Text('• Bullet List')),
        PopupMenuItem(value: 'numbered', child: Text('1. Numbered List')),
        PopupMenuItem(value: 'checklist', child: Text('☑ Task Checklist')),
        PopupMenuItem(value: 'table', child: Text('⊞ Insert Table')),
        PopupMenuItem(value: 'divider', child: Text('― Horizontal Divider')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'link', child: Text('🔗 Insert Link (Ctrl+K)')),
        PopupMenuItem(value: 'image', child: Text('🖼️ Insert Image')),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'tag_imp',
          child: Text('⭐ Important (@@imp) (Ctrl+Shift+H)'),
        ),
        PopupMenuItem(
          value: 'tag_info',
          child: Text('ℹ️ Info Reference (@@info) (Ctrl+Shift+I)'),
        ),
        PopupMenuItem(
          value: 'tag_todo',
          child: Text('✅ To-Do Task (@@todo) (Ctrl+Shift+T)'),
        ),
        PopupMenuItem(
          value: 'tag_review',
          child: Text('🔍 Review (@@review) (Ctrl+Shift+R)'),
        ),
        PopupMenuItem(
          value: 'tag_custom',
          child: Text('🏷️ Tag Section (@@tag)'),
        ),
        PopupMenuItem(
          value: 'draw',
          child: Text('🎨 Drawing Diagram (@@drawing) (Ctrl+Shift+D)'),
        ),
        PopupMenuItem(value: 'view', child: Text('👁️ Preview Block (@@view)')),
      ],
    );
  }
}
