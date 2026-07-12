import 'package:flutter/material.dart';

/// Helper actions for manipulating markdown text in the editor.
class EditorFormattingActions {
  const EditorFormattingActions._();

  /// Wraps current selection or inserts formatted markdown text.
  static void wrapSelection({
    required TextEditingController controller,
    required FocusNode focusNode,
    required void Function(String) onTextChanged,
    required String prefix,
    String suffix = '',
  }) {
    final sel = controller.selection;
    final text = controller.text;

    if (!sel.isValid || sel.isCollapsed) {
      final pos = sel.baseOffset.clamp(0, text.length);
      final insertText = '$prefix$suffix';
      controller.text =
          text.substring(0, pos) + insertText + text.substring(pos);
      controller.selection = TextSelection.collapsed(
        offset: pos + prefix.length,
      );
    } else {
      final selected = text.substring(sel.start, sel.end);
      final wrapped = '$prefix$selected$suffix';
      controller.text =
          text.substring(0, sel.start) + wrapped + text.substring(sel.end);
      controller.selection = TextSelection(
        baseOffset: sel.start,
        extentOffset: sel.start + wrapped.length,
      );
    }
    onTextChanged(controller.text);
    focusNode.requestFocus();
  }

  /// Inserts a block-level tag template (e.g. @@imp, @@info, @@tag) immediately without modal prompts.
  static void applyTagTemplate({
    required TextEditingController controller,
    required FocusNode focusNode,
    required void Function(String) onTextChanged,
    String tagType = 'tag',
  }) {
    final sel = controller.selection;
    final text = controller.text;
    final markId = tagType != 'tag'
        ? ' #${tagType}_${DateTime.now().millisecondsSinceEpoch}'
        : '';

    if (!sel.isValid || sel.isCollapsed) {
      final pos = sel.baseOffset.clamp(0, text.length);
      final template = '\n@@$tagType$markId\n\n@@/$tagType\n';
      controller.text = text.substring(0, pos) + template + text.substring(pos);
      controller.selection = TextSelection.collapsed(
        offset: (pos + '\n@@$tagType$markId\n'.length).clamp(
          0,
          controller.text.length,
        ),
      );
    } else {
      final selected = text.substring(sel.start, sel.end);
      final wrapped = '\n@@$tagType$markId\n$selected\n@@/$tagType\n';
      controller.text =
          text.substring(0, sel.start) + wrapped + text.substring(sel.end);
      controller.selection = TextSelection.collapsed(
        offset: sel.start + wrapped.length,
      );
    }

    onTextChanged(controller.text);
    focusNode.requestFocus();
  }

  static void insertTable({
    required TextEditingController controller,
    required FocusNode focusNode,
    required void Function(String) onTextChanged,
  }) {
    const tableTemplate =
        '\n| Header 1 | Header 2 | Header 3 |\n| :--- | :--- | :--- |\n| Item 1 | Item 2 | Item 3 |\n| Item 4 | Item 5 | Item 6 |\n\n';
    wrapSelection(
      controller: controller,
      focusNode: focusNode,
      onTextChanged: onTextChanged,
      prefix: tableTemplate,
    );
  }

  static void insertLink({
    required TextEditingController controller,
    required FocusNode focusNode,
    required void Function(String) onTextChanged,
  }) {
    final sel = controller.selection;
    final text = controller.text;
    if (!sel.isValid || sel.isCollapsed) {
      wrapSelection(
        controller: controller,
        focusNode: focusNode,
        onTextChanged: onTextChanged,
        prefix: '[link text](url)',
      );
    } else {
      final selected = text.substring(sel.start, sel.end);
      wrapSelection(
        controller: controller,
        focusNode: focusNode,
        onTextChanged: onTextChanged,
        prefix: '[$selected](https://)',
      );
    }
  }

  static void insertImage({
    required TextEditingController controller,
    required FocusNode focusNode,
    required void Function(String) onTextChanged,
  }) {
    final sel = controller.selection;
    final text = controller.text;
    if (!sel.isValid || sel.isCollapsed) {
      wrapSelection(
        controller: controller,
        focusNode: focusNode,
        onTextChanged: onTextChanged,
        prefix: '![alt text](image-url)',
      );
    } else {
      final selected = text.substring(sel.start, sel.end);
      wrapSelection(
        controller: controller,
        focusNode: focusNode,
        onTextChanged: onTextChanged,
        prefix: '![$selected](image-url)',
      );
    }
  }

  static void insertHorizontalRule({
    required TextEditingController controller,
    required FocusNode focusNode,
    required void Function(String) onTextChanged,
  }) {
    wrapSelection(
      controller: controller,
      focusNode: focusNode,
      onTextChanged: onTextChanged,
      prefix: '\n---\n\n',
    );
  }

  static void insertViewDirective({
    required TextEditingController controller,
    required FocusNode focusNode,
    required void Function(String) onTextChanged,
  }) {
    final sel = controller.selection;
    final text = controller.text;

    if (!sel.isValid || sel.isCollapsed) {
      final pos = sel.baseOffset.clamp(0, text.length);
      const template = '\n@@view #mark-id\n';
      controller.text = text.substring(0, pos) + template + text.substring(pos);
      final idStart = pos + '\n@@view #'.length;
      final idEnd = idStart + 'mark-id'.length;
      controller.selection = TextSelection(
        baseOffset: idStart,
        extentOffset: idEnd,
      );
    } else {
      final selected = text.substring(sel.start, sel.end).trim();
      final cleanId = selected.startsWith('#')
          ? selected.substring(1)
          : selected;
      final template = '\n@@view #$cleanId\n';
      controller.text =
          text.substring(0, sel.start) + template + text.substring(sel.end);
      controller.selection = TextSelection.collapsed(
        offset: sel.start + template.length,
      );
    }
    onTextChanged(controller.text);
    focusNode.requestFocus();
  }
}
