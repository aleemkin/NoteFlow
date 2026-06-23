import 'package:noteflow/features/document/domain/models.dart';

/// Allocates continuous, non-shifting horizontal lane indices (0, 1, 2, ...)
/// for semantic tag strips in the gutter across a document's blocks.
///
/// Follows industry standards (VS Code git decorations & IDE gutter columns):
/// - Continuing tag streams permanently retain their lane index without shifting.
/// - Newly starting / nested tags take the next available lane to the right.
/// - Terminated tags free their lane for subsequent tags.
class GutterLaneAllocator {
  /// Computes a map of blockId -> (markId -> laneIndex) for all blocks in [blocks].
  static Map<String, Map<String, int>> computeLanes(
    List<DocumentBlock> blocks, {
    String? activeFilterTag,
  }) {
    final result = <String, Map<String, int>>{};
    final filterTag = activeFilterTag?.trim().toLowerCase();
    final activeLanes = <int, String>{};

    for (final block in blocks) {
      final visibleMarks = block.marks.where((m) {
        if (filterTag == null || filterTag.isEmpty) return true;
        final mType = m.type.trim().toLowerCase();
        if (filterTag == 'imp' || filterTag == 'important') {
          return mType != 'imp' && mType != 'important';
        }
        return mType != filterTag;
      }).toList();

      if (visibleMarks.isEmpty) {
        activeLanes.clear();
        continue;
      }

      final currentMarkIds = visibleMarks.map((m) => m.id).toSet();
      final blockLanes = <String, int>{};

      // 1. Evict any lanes whose marks have ended
      activeLanes.removeWhere((lane, id) => !currentMarkIds.contains(id));

      // 2. Retain existing lanes for continuing marks (Rule 1: Never shift continuing tracks)
      for (final entry in activeLanes.entries) {
        blockLanes[entry.value] = entry.key;
      }

      // 3. Allocate lowest available lane for newly started marks
      for (final mark in visibleMarks) {
        if (!blockLanes.containsKey(mark.id)) {
          var lane = 0;
          while (activeLanes.containsKey(lane)) {
            lane++;
          }
          activeLanes[lane] = mark.id;
          blockLanes[mark.id] = lane;
        }
      }

      result[block.id] = blockLanes;
    }

    return result;
  }
}
