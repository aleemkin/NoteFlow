import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/editor/presentation/widgets/editor_components/editor_formatting_actions.dart';

/// Keyboard-docked Markdown accessory toolbar designed specifically for mobile touch typing.
///
/// Docks above the Android soft keyboard, providing instant thumb access to Markdown
/// formatting, lists, tables, and Excalidraw / tag directives.
class MobileEditorAccessoryBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onInsertDrawing;

  const MobileEditorAccessoryBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onTextChanged,
    required this.onInsertDrawing,
  });

  void _wrap(String prefix, [String suffix = '']) {
    HapticFeedback.lightImpact();
    EditorFormattingActions.wrapSelection(
      controller: controller,
      focusNode: focusNode,
      onTextChanged: onTextChanged,
      prefix: prefix,
      suffix: suffix,
    );
  }

  void _applyTag(String tagType) {
    HapticFeedback.lightImpact();
    EditorFormattingActions.applyTagTemplate(
      controller: controller,
      focusNode: focusNode,
      onTextChanged: onTextChanged,
      tagType: tagType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceNavbar,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            children: [
              // 1. Headings (H1, H2, H3)
              _buildItem(
                label: 'H1',
                tooltip: 'Heading 1',
                onTap: () => _wrap('# '),
              ),
              _buildItem(
                label: 'H2',
                tooltip: 'Heading 2',
                onTap: () => _wrap('## '),
              ),
              _buildItem(
                label: 'H3',
                tooltip: 'Heading 3',
                onTap: () => _wrap('### '),
              ),
              _buildDivider(),

              // 2. Directives (Diagram, Important)
              _buildPillItem(
                icon: Icons.brush_rounded,
                label: 'Diagram',
                color: const Color(0xFF2563EB),
                tooltip: 'Insert Excalidraw Diagram (@@drawing)',
                onTap: () {
                  HapticFeedback.lightImpact();
                  onInsertDrawing();
                },
              ),
              const SizedBox(width: 4),
              _buildPillItem(
                icon: Icons.star_rounded,
                label: 'Important',
                color: AppColors.markImportant,
                tooltip: 'Tag as Important (@@imp)',
                onTap: () => _applyTag('imp'),
              ),
              _buildDivider(),

              // 3. Formatting & Inserts (Code, Link, List, Bold, Italic)
              _buildItem(
                icon: Icons.code_rounded,
                tooltip: 'Code (` or ```)',
                onTap: () => _wrap('`', '`'),
              ),
              _buildItem(
                icon: Icons.link_rounded,
                tooltip: 'Insert Link',
                onTap: () {
                  HapticFeedback.lightImpact();
                  EditorFormattingActions.insertLink(
                    controller: controller,
                    focusNode: focusNode,
                    onTextChanged: onTextChanged,
                  );
                },
              ),
              _buildItem(
                icon: Icons.format_list_bulleted_rounded,
                tooltip: 'Bullet List (-)',
                onTap: () => _wrap('- '),
              ),
              _buildItem(
                icon: Icons.format_bold_rounded,
                tooltip: 'Bold (**)',
                onTap: () => _wrap('**', '**'),
              ),
              _buildItem(
                icon: Icons.format_italic_rounded,
                tooltip: 'Italic (*)',
                onTap: () => _wrap('*', '*'),
              ),
              _buildItem(
                icon: Icons.format_strikethrough_rounded,
                tooltip: 'Strikethrough (~~)',
                onTap: () => _wrap('~~', '~~'),
              ),
              _buildItem(
                icon: Icons.check_box_outlined,
                tooltip: 'Task Checklist (- [ ])',
                onTap: () => _wrap('- [ ] '),
              ),
              _buildItem(
                icon: Icons.format_quote_rounded,
                tooltip: 'Quote (>)',
                onTap: () => _wrap('> '),
              ),
              _buildItem(
                icon: Icons.table_chart_outlined,
                tooltip: 'Insert Table',
                onTap: () {
                  HapticFeedback.lightImpact();
                  EditorFormattingActions.insertTable(
                    controller: controller,
                    focusNode: focusNode,
                    onTextChanged: onTextChanged,
                  );
                },
              ),
              _buildItem(
                icon: Icons.horizontal_rule_rounded,
                tooltip: 'Divider (---)',
                onTap: () {
                  HapticFeedback.lightImpact();
                  EditorFormattingActions.insertHorizontalRule(
                    controller: controller,
                    focusNode: focusNode,
                    onTextChanged: onTextChanged,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    IconData? icon,
    String? label,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: icon != null
              ? Icon(icon, size: 18, color: AppColors.textPrimary)
              : Text(
                  label ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPillItem({
    required IconData icon,
    required String label,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      color: AppColors.borderSubtle,
    );
  }
}
