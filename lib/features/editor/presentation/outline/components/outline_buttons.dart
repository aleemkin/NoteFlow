import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';

class OutlineReorderToggleIconButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const OutlineReorderToggleIconButton({
    super.key,
    required this.isActive,
    required this.onToggle,
  });

  @override
  State<OutlineReorderToggleIconButton> createState() =>
      _OutlineReorderToggleIconButtonState();
}

class _OutlineReorderToggleIconButtonState
    extends State<OutlineReorderToggleIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final highlight = widget.isActive || _isHovered;

    return Tooltip(
      message: widget.isActive
          ? 'Done Reordering (Exit Reorder Mode)'
          : 'Reorder Sections (Drag & Drop Reordering)',
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppColors.accentCyan.withAlpha(35)
                  : (_isHovered
                        ? AppColors.actionIconHoverBg
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: widget.isActive
                    ? AppColors.accentCyan.withAlpha(140)
                    : (_isHovered
                          ? AppColors.controlBorder
                          : Colors.transparent),
              ),
            ),
            child: Icon(
              Icons.swap_vert_rounded,
              size: 15,
              color: highlight
                  ? (widget.isActive
                        ? AppColors.accentCyan
                        : AppColors.actionIconActive)
                  : AppColors.actionIcon,
            ),
          ),
        ),
      ),
    );
  }
}

class OutlineHeaderIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  const OutlineHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<OutlineHeaderIconButton> createState() =>
      _OutlineHeaderIconButtonState();
}

class _OutlineHeaderIconButtonState extends State<OutlineHeaderIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppColors.accentCyan.withAlpha(30)
                  : (_isHovered ? AppColors.controlHover : Colors.transparent),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: widget.isActive
                  ? AppColors.accentCyan
                  : (_isHovered ? AppColors.textPrimary : AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
