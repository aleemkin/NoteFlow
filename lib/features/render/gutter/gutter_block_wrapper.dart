import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/domain/models.dart';

/// Gutter indicator displaying subtle, color-coded vertical strips (20-30% opacity, VS Code git-style)
/// or an edit button in the left margin.
class GutterBlockWrapper extends StatelessWidget {
  final DocumentBlock block;
  final DocumentBlock? prevBlock;
  final DocumentBlock? nextBlock;
  final Widget child;
  final VoidCallback? onEdit;
  final String? activeFilterTag;
  final Map<String, int>? markLanes;

  const GutterBlockWrapper({
    super.key,
    required this.block,
    this.prevBlock,
    this.nextBlock,
    required this.child,
    this.onEdit,
    this.activeFilterTag,
    this.markLanes,
  });

  static Color _markColor(String type) => switch (type.toLowerCase()) {
    'imp' || 'important' => AppColors.markImportant,
    'info' => AppColors.markInfo,
    'todo' => AppColors.secondary,
    'review' => AppColors.accent,
    'question' => AppColors.markImportant,
    _ => AppColors.markTag,
  };

  Map<String, int> _resolveLocalLanes(List<SemanticMark> visibleMarks) {
    if (visibleMarks.isEmpty) return const {};
    final lanes = <String, int>{};
    final occupied = <int>{};

    // If mark continues from prevBlock, keep it in Lane 0 if it was present
    if (prevBlock != null) {
      for (final mark in visibleMarks) {
        if (prevBlock!.marks.any(
          (pm) =>
              pm.id == mark.id ||
              pm.type.toLowerCase() == mark.type.toLowerCase(),
        )) {
          lanes[mark.id] = 0;
          occupied.add(0);
          break; // First continuing mark holds Lane 0
        }
      }
    }

    // Allocate lowest free lanes for remaining marks
    for (final mark in visibleMarks) {
      if (!lanes.containsKey(mark.id)) {
        var lane = 0;
        while (occupied.contains(lane)) {
          lane++;
        }
        lanes[mark.id] = lane;
        occupied.add(lane);
      }
    }
    return lanes;
  }

  @override
  Widget build(BuildContext context) {
    final marks = block.marks;
    final filterTag = activeFilterTag?.trim().toLowerCase();

    // In tagged views, suppress the strip of that specific active tag
    // to avoid a continuous line running down the entire filtered roll.
    final visibleMarks = marks.where((m) {
      if (filterTag == null || filterTag.isEmpty) return true;
      final mType = m.type.trim().toLowerCase();
      if (filterTag == 'imp' || filterTag == 'important') {
        return mType != 'imp' && mType != 'important';
      }
      return mType != filterTag;
    }).toList();

    final hasStrips = visibleMarks.isNotEmpty;
    final hasEdit = onEdit != null;

    if (!hasStrips && !hasEdit) {
      return Padding(padding: const EdgeInsets.only(left: 24), child: child);
    }

    final topPadding = switch (block) {
      TableBlock() => 18.0,
      ThematicBreakBlock() => 4.0,
      DrawingBlock() => 16.0,
      TextBlock(role: TextBlockRole.heading1) => 6.0,
      TextBlock(role: TextBlockRole.heading2) => 5.0,
      TextBlock(role: TextBlockRole.heading3) => 4.0,
      TextBlock(role: TextBlockRole.code) => 8.0,
      ViewBlock() => 4.0,
      _ => 2.0,
    };

    final lanes = markLanes ?? _resolveLocalLanes(visibleMarks);
    final maxLane = lanes.values.isEmpty ? 0 : lanes.values.reduce(math.max);
    final stripsWidth = hasStrips ? ((maxLane + 1) * 5.5) : 0.0;
    final gutterWidth = math.max(
      24.0,
      4.0 + stripsWidth + (hasEdit ? 18.0 : 4.0),
    );

    // Check continuation for each mark from previous and to next block
    bool markContinuesFromPrev(SemanticMark m) {
      if (prevBlock == null) return false;
      return prevBlock!.marks.any(
        (pm) => pm.id == m.id || pm.type.toLowerCase() == m.type.toLowerCase(),
      );
    }

    bool markContinuesToNext(SemanticMark m) {
      if (nextBlock == null) return false;
      return nextBlock!.marks.any(
        (nm) => nm.id == m.id || nm.type.toLowerCase() == m.type.toLowerCase(),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main block content indented for the gutter width
        Padding(
          padding: EdgeInsets.only(left: gutterWidth),
          child: child,
        ),

        // Left margin gutter: continuous VS Code git-style strips and edit button
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: gutterWidth,
          child: Stack(
            children: [
              if (hasStrips)
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 4,
                  width: stripsWidth,
                  child: Stack(
                    children: [
                      for (final mark in visibleMarks)
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: (lanes[mark.id] ?? 0) * 5.5,
                          width: 3.0,
                          child: _buildMarkStrip(
                            mark: mark,
                            continuesFromPrev: markContinuesFromPrev(mark),
                            continuesToNext: markContinuesToNext(mark),
                          ),
                        ),
                    ],
                  ),
                ),

              // Edit note button
              if (hasEdit)
                Positioned(
                  top: topPadding,
                  right: 2,
                  child: Tooltip(
                    message: 'Edit Note',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: onEdit,
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.edit_note,
                          size: 15,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarkStrip({
    required SemanticMark mark,
    required bool continuesFromPrev,
    required bool continuesToNext,
  }) {
    final topOffset = continuesFromPrev ? 0.0 : 2.0;
    final bottomOffset = continuesToNext ? 0.0 : 2.0;

    final borderRadius = BorderRadius.only(
      topLeft: continuesFromPrev ? Radius.zero : const Radius.circular(1.5),
      topRight: continuesFromPrev ? Radius.zero : const Radius.circular(1.5),
      bottomLeft: continuesToNext ? Radius.zero : const Radius.circular(1.5),
      bottomRight: continuesToNext ? Radius.zero : const Radius.circular(1.5),
    );

    return Tooltip(
      message: 'Tag: @@${mark.type}',
      child: Container(
        width: 3.0,
        margin: EdgeInsets.only(top: topOffset, bottom: bottomOffset),
        decoration: BoxDecoration(
          color: _markColor(mark.type).withValues(alpha: 0.28),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
