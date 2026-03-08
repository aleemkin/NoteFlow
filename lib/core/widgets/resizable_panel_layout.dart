import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';

/// A horizontally resizable panel layout with draggable dividers and flexible center area.
class ResizablePanelLayout extends StatefulWidget {
  final Widget? leftPanel;
  final Widget centerPanel;
  final Widget? rightPanel;
  final double initialLeftWidth;
  final double initialRightWidth;
  final double minLeftWidth;
  final double maxLeftWidth;
  final double minRightWidth;
  final double maxRightWidth;
  final double dividerWidth;

  const ResizablePanelLayout({
    super.key,
    this.leftPanel,
    required this.centerPanel,
    this.rightPanel,
    this.initialLeftWidth = 240,
    this.initialRightWidth = 220,
    this.minLeftWidth = 140,
    this.maxLeftWidth = 380,
    this.minRightWidth = 140,
    this.maxRightWidth = 360,
    this.dividerWidth = 4,
  });

  @override
  State<ResizablePanelLayout> createState() => _ResizablePanelLayoutState();
}

class _ResizablePanelLayoutState extends State<ResizablePanelLayout> {
  late double _leftWidth;
  late double _rightWidth;
  bool _draggingLeft = false;
  bool _draggingRight = false;

  @override
  void initState() {
    super.initState();
    _leftWidth = widget.initialLeftWidth;
    _rightWidth = widget.initialRightWidth;
  }

  @override
  void didUpdateWidget(covariant ResizablePanelLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLeftWidth != widget.initialLeftWidth) {
      _leftWidth = widget.initialLeftWidth;
    }
    if (oldWidget.initialRightWidth != widget.initialRightWidth) {
      _rightWidth = widget.initialRightWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // Check if side panels exist and can fit
        final hasRight = widget.rightPanel != null && totalWidth > 450;
        final hasLeft = widget.leftPanel != null && totalWidth > 320;

        final effectiveLeftWidth = hasLeft
            ? _leftWidth.clamp(widget.minLeftWidth, totalWidth * 0.4)
            : 0.0;
        final effectiveRightWidth = hasRight
            ? _rightWidth.clamp(widget.minRightWidth, totalWidth * 0.35)
            : 0.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left panel
            if (hasLeft && widget.leftPanel != null) ...[
              SizedBox(width: effectiveLeftWidth, child: widget.leftPanel!),

              // Left divider
              _DragDivider(
                width: widget.dividerWidth,
                isDragging: _draggingLeft,
                onDragStart: () => setState(() => _draggingLeft = true),
                onDragUpdate: (dx) {
                  setState(() {
                    _leftWidth = (_leftWidth + dx).clamp(
                      widget.minLeftWidth,
                      widget.maxLeftWidth,
                    );
                  });
                },
                onDragEnd: () => setState(() => _draggingLeft = false),
              ),
            ],

            // Center panel (Expanded takes all remaining space)
            Expanded(child: widget.centerPanel),

            // Right divider + panel
            if (hasRight && widget.rightPanel != null) ...[
              _DragDivider(
                width: widget.dividerWidth,
                isDragging: _draggingRight,
                onDragStart: () => setState(() => _draggingRight = true),
                onDragUpdate: (dx) {
                  setState(() {
                    _rightWidth = (_rightWidth - dx).clamp(
                      widget.minRightWidth,
                      widget.maxRightWidth,
                    );
                  });
                },
                onDragEnd: () => setState(() => _draggingRight = false),
              ),
              SizedBox(width: effectiveRightWidth, child: widget.rightPanel!),
            ],
          ],
        );
      },
    );
  }
}

class _DragDivider extends StatefulWidget {
  final double width;
  final bool isDragging;
  final VoidCallback onDragStart;
  final void Function(double dx) onDragUpdate;
  final VoidCallback onDragEnd;

  const _DragDivider({
    required this.width,
    required this.isDragging,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  State<_DragDivider> createState() => _DragDividerState();
}

class _DragDividerState extends State<_DragDivider> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isDragging || _hovering;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => widget.onDragStart(),
        onHorizontalDragUpdate: (d) => widget.onDragUpdate(d.delta.dx),
        onHorizontalDragEnd: (_) => widget.onDragEnd(),
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
