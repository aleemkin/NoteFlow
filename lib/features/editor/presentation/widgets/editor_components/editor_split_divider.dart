import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';

/// Draggable split divider for side-by-side editor panels.
class EditorSplitDivider extends StatefulWidget {
  final double width;
  final void Function(double dx) onDragUpdate;

  const EditorSplitDivider({
    super.key,
    required this.width,
    required this.onDragUpdate,
  });

  @override
  State<EditorSplitDivider> createState() => _EditorSplitDividerState();
}

class _EditorSplitDividerState extends State<EditorSplitDivider> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || _isDragging;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => setState(() => _isDragging = true),
        onHorizontalDragUpdate: (d) => widget.onDragUpdate(d.delta.dx),
        onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
        child: Container(
          width: widget.width,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 1.0,
              color: isActive ? AppColors.primary : AppColors.borderSubtle,
            ),
          ),
        ),
      ),
    );
  }
}
