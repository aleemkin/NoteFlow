import 'package:flutter/material.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';
import 'package:noteflow/core/constants/view_mode.dart';
import 'package:noteflow/core/theme/app_theme.dart';

/// Segmented toggle matching the [Reading | Editor] control in the header.
class ViewModeToggle extends StatelessWidget {
  final ViewMode currentMode;
  final ValueChanged<ViewMode> onModeChanged;

  const ViewModeToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  static const double _radius = 6.0;
  static const double _height = 28.0;
  static const double _width = 216.0;
  static const Duration _duration = Duration(milliseconds: 400);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final isReading = currentMode == ViewMode.reading;

    return Container(
      width: _width,
      height: _height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.controlBackground.withAlpha(150),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: AppColors.controlBorder),
      ),
      // No clipBehavior here – the border must stay outside the animated pill
      child: Stack(
        children: [
          // ── Sliding active pill ──────────────────────────────────
          AnimatedAlign(
            duration: _duration,
            curve: _curve,
            alignment: isReading ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Padding(
                // Inset so the pill never touches the outer border
                padding: const EdgeInsets.all(2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.activeSegment,
                    borderRadius: BorderRadius.circular(_radius - 2),
                  ),
                ),
              ),
            ),
          ),

          // ── Labels (always on top) ───────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SegmentLabel(
                  label: 'Reading',
                  icon: AppSvgIcon.readingToggle(size: 12),
                  isSelected: isReading,
                  onTap: () => onModeChanged(ViewMode.reading),
                  tooltip: 'Reading Mode (Ctrl+1 / ⌘1)',
                  duration: _duration,
                  curve: _curve,
                ),
              ),
              Expanded(
                child: _SegmentLabel(
                  label: 'Editor',
                  icon: AppSvgIcon.editorToggle(size: 12),
                  iconSize: 18,
                  isSelected: !isReading,
                  onTap: () => onModeChanged(ViewMode.editor),
                  tooltip: 'Editor Mode (Ctrl+2 / ⌘2)',
                  duration: _duration,
                  curve: _curve,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentLabel extends StatefulWidget {
  final String label;
  final AppSvgIcon icon;
  final double iconSize;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;
  final Duration duration;
  final Curve curve;

  const _SegmentLabel({
    required this.label,
    required this.icon,
    this.iconSize = 15,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
    required this.duration,
    required this.curve,
  });

  @override
  State<_SegmentLabel> createState() => _SegmentLabelState();
}

class _SegmentLabelState extends State<_SegmentLabel> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final highlight = widget.isSelected || _isHovered;
    final foreground = highlight
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: widget.duration,
              curve: widget.curve,
              style: TextStyle(
                fontSize: 12,
                fontWeight: widget.isSelected
                    ? FontWeight.w600
                    : FontWeight.w500,
                letterSpacing: 0.1,
                color: foreground,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.icon,
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
