import 'package:flutter/material.dart';

import 'package:noteflow/features/document/domain/models.dart';
import 'package:noteflow/core/theme/app_theme.dart';

class OutlineTile extends StatefulWidget {
  final AtomicUnit unit;
  final int index;
  final bool isReorderMode;
  final VoidCallback onTap;

  const OutlineTile({
    super.key,
    required this.unit,
    required this.index,
    required this.isReorderMode,
    required this.onTap,
  });

  @override
  State<OutlineTile> createState() => _OutlineTileState();
}

class _OutlineTileState extends State<OutlineTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final (badgeText, badgeColor) = switch (widget.unit.kind) {
      AtomicUnitKind.document => ('DOC', AppColors.accentCyan),
      AtomicUnitKind.heading => (
        'H${widget.unit.headingLevel > 0 ? widget.unit.headingLevel : 1}',
        AppColors.textPrimary,
      ),
      AtomicUnitKind.drawing => ('DRAW', AppColors.accentOrange),
      AtomicUnitKind.section => ('SEC', AppColors.textSecondary),
    };

    final indent = switch (widget.unit.kind) {
      AtomicUnitKind.heading =>
        (widget.unit.headingLevel > 1
            ? (widget.unit.headingLevel - 1) * 12.0
            : 0.0),
      _ => 0.0,
    };

    final titleWeight = switch (widget.unit.kind) {
      AtomicUnitKind.document => FontWeight.w700,
      AtomicUnitKind.heading =>
        (widget.unit.headingLevel <= 2 ? FontWeight.w600 : FontWeight.w500),
      _ => FontWeight.w500,
    };

    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 2),
      child: MouseRegion(
        cursor: widget.isReorderMode
            ? SystemMouseCursors.grab
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.controlHover : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.isReorderMode && _isHovered
                    ? AppColors.accentCyan.withAlpha(120)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // Reorder drag hint indicator when in reorder mode
                if (widget.isReorderMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 14,
                      color: _isHovered
                          ? AppColors.accentCyan
                          : AppColors.textMuted,
                    ),
                  ),

                // Kind badge (DOC, H1, DRAW, SEC)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: badgeColor.withAlpha(60),
                      width: 0.7,
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),

                // Title
                Expanded(
                  child: Text(
                    widget.unit.title.isEmpty
                        ? 'Untitled Section'
                        : widget.unit.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: titleWeight,
                      letterSpacing: 0.1,
                      color: _isHovered
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withAlpha(215),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
