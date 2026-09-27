import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/core/platform/app_platform.dart';
import 'package:noteflow/features/vault/vault.dart';

/// VS Code-style inline rename row replacing the node's label in place.
class InlineRenameRow extends StatefulWidget {
  final VaultTreeNode node;
  final int depth;
  final ValueChanged<String> onCommit;
  final VoidCallback onCancel;

  const InlineRenameRow({
    super.key,
    required this.node,
    required this.depth,
    required this.onCommit,
    required this.onCancel,
  });

  @override
  State<InlineRenameRow> createState() => _InlineRenameRowState();
}

class _InlineRenameRowState extends State<InlineRenameRow> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _handled = false;
  bool _isInvalid = false;
  bool _hasEverFocused = false;
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.node.name);
    final dotIndex = widget.node.name.lastIndexOf('.');
    if (!widget.node.isDirectory && dotIndex > 0) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: dotIndex,
      );
    } else {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.node.name.length,
      );
    }
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        try {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 150),
          );
        } catch (_) {}
      }
    });

    if (AppPlatform.isMobile) {
      _focusTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted && !_handled) {
          _focusNode.requestFocus();
        }
      });
    }
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
    if (_focusNode.hasFocus) {
      _hasEverFocused = true;
      return;
    }
    if (!_focusNode.hasFocus && !_handled && _hasEverFocused) {
      final text = _controller.text.trim();
      if (text.isNotEmpty && text != widget.node.name && !_isInvalid) {
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
    // Smart extension preservation: if renaming a file and user omitted extension, keep existing
    if (!widget.node.isDirectory) {
      final dotIndex = widget.node.name.lastIndexOf('.');
      if (dotIndex > 0 && !finalName.contains('.')) {
        final ext = widget.node.name.substring(dotIndex);
        finalName = '$finalName$ext';
      }
    }
    if (finalName == widget.node.name) {
      _cancel();
      return;
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
    _focusTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppPlatform.isMobile;
    final isDraw = widget.node.uri.path.endsWith('.excalidraw');
    final IconData icon = widget.node.isDirectory
        ? Icons.folder
        : (isDraw ? Icons.draw_outlined : Icons.description_outlined);
    final Color iconColor = isDraw ? AppColors.secondary : AppColors.textMuted;

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
