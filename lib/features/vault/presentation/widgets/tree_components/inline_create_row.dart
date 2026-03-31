import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/core/platform/app_platform.dart';
import '../../../domain/vault_tree_types.dart';

/// VS Code-style inline creation row shown in the tree at the target directory.
class InlineCreateRow extends StatefulWidget {
  final InlineCreateType type;
  final int depth;
  final ValueChanged<String> onCommit;
  final VoidCallback onCancel;

  const InlineCreateRow({
    super.key,
    required this.type,
    required this.depth,
    required this.onCommit,
    required this.onCancel,
  });

  @override
  State<InlineCreateRow> createState() => _InlineCreateRowState();
}

class _InlineCreateRowState extends State<InlineCreateRow> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _handled = false;
  bool _isInvalid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChange);
    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        _cancel();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    final invalid =
        text.isNotEmpty &&
        (RegExp(r'[\\/:*?"<>|]').hasMatch(text) || text == '.' || text == '..');
    if (invalid != _isInvalid) {
      setState(() => _isInvalid = invalid);
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && !_handled) {
      final text = _controller.text.trim();
      if (text.isNotEmpty && !_isInvalid) {
        _commit(text);
      } else {
        _cancel();
      }
    }
  }

  void _commit(String name) {
    if (_handled) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty ||
        RegExp(r'[\\/:*?"<>|]').hasMatch(trimmed) ||
        trimmed == '.' ||
        trimmed == '..') {
      _cancel();
      return;
    }
    var finalName = trimmed;
    if (widget.type == InlineCreateType.note && !finalName.contains('.')) {
      finalName = '$finalName.md';
    } else if (widget.type == InlineCreateType.drawing &&
        !finalName.contains('.')) {
      finalName = '$finalName.excalidraw';
    }
    _handled = true;
    widget.onCommit(finalName);
  }

  void _cancel() {
    if (_handled) return;
    _handled = true;
    widget.onCancel();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppPlatform.isMobile;
    final IconData icon;
    final Color iconColor;
    final String hintText;

    switch (widget.type) {
      case InlineCreateType.note:
        icon = Icons.description_outlined;
        iconColor = AppColors.textMuted;
        hintText = 'note.md';
      case InlineCreateType.drawing:
        icon = Icons.draw_outlined;
        iconColor = AppColors.secondary;
        hintText = 'diagram.excalidraw';
      case InlineCreateType.folder:
        icon = Icons.folder;
        iconColor = AppColors.textMuted;
        hintText = 'folder name';
    }

    return Padding(
      padding: EdgeInsets.only(
        left:
            (widget.depth * (isMobile ? 16.0 : 14.0)) +
            (isMobile ? 10.0 : 10.0),
        right: 10.0,
        top: isMobile ? 5.0 : 2.0,
        bottom: isMobile ? 5.0 : 2.0,
      ),
      child: Row(
        children: [
          Icon(icon, size: isMobile ? 18 : 14, color: iconColor),
          SizedBox(width: isMobile ? 9 : 7),
          Expanded(
            child: SizedBox(
              height: isMobile ? 36 : 24,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                cursorColor: AppColors.textPrimary,
                cursorWidth: 1.5,
                style: TextStyle(
                  fontSize: isMobile ? 13.5 : 12,
                  color: AppColors.textPrimary,
                ),
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 6,
                    vertical: isMobile ? 8 : 3,
                  ),
                  hintText: hintText,
                  hintStyle: TextStyle(
                    fontSize: isMobile ? 12.5 : 11,
                    color: AppColors.textTertiary,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 6 : 2),
                    borderSide: BorderSide(
                      color: _isInvalid
                          ? AppColors.markDanger
                          : AppColors.primary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 6 : 2),
                    borderSide: BorderSide(
                      color: _isInvalid
                          ? AppColors.markDanger
                          : AppColors.primary,
                    ),
                  ),
                ),
                onSubmitted: (val) => _commit(val),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _commit(_controller.text),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 6 : 2),
              child: Icon(
                Icons.check,
                size: isMobile ? 18 : 16,
                color: AppColors.primary,
              ),
            ),
          ),
          InkWell(
            onTap: _cancel,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 6 : 2),
              child: Icon(
                Icons.close,
                size: isMobile ? 18 : 16,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
