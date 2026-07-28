import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteflow/features/document/domain/models.dart';
import 'package:noteflow/features/vault/vault.dart';
import 'package:noteflow/core/theme/app_theme.dart';

export 'components/outline_buttons.dart';
export 'components/outline_tile.dart';

import 'components/outline_buttons.dart';
import 'components/outline_tile.dart';

/// Unified right-side inspector panel displaying Document Outline
/// and on-demand section drag-and-drop reordering.
class OutlineInspectorPanel extends ConsumerStatefulWidget {
  final VaultTreeNode folderNode;
  final List<AtomicUnit> units;
  final Future<void> Function(List<AtomicUnit> newOrder)? onUnitsReordered;
  final void Function(AtomicUnit unit)? onUnitSelected;

  const OutlineInspectorPanel({
    super.key,
    required this.folderNode,
    required this.units,
    this.onUnitsReordered,
    this.onUnitSelected,
  });

  @override
  ConsumerState<OutlineInspectorPanel> createState() =>
      _OutlineInspectorPanelState();
}

class _OutlineInspectorPanelState extends ConsumerState<OutlineInspectorPanel> {
  late List<AtomicUnit> _units;
  bool _isReorderMode = false;
  bool _isDragging = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  String _searchFilter = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _units = List.from(widget.units);
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
      }
    });
    _searchFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        if (_searchController.text.isNotEmpty) {
          _clearSearch();
        } else {
          setState(() => _showSearch = false);
        }
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void didUpdateWidget(OutlineInspectorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _units = List.from(widget.units);
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchFilter = '');
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    if (newIndex > oldIndex) newIndex -= 1;

    setState(() {
      final item = _units.removeAt(oldIndex);
      _units.insert(newIndex, item);
    });

    if (widget.onUnitsReordered != null) {
      await widget.onUnitsReordered!(_units);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.sidebarBackground),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_isReorderMode) _buildReorderBanner(),
          if (_showSearch || _searchFilter.isNotEmpty || _units.length > 5)
            _buildSearchBar(),

          Expanded(child: _buildOutlineBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: AppColors.chromeBackground,
        border: Border(bottom: BorderSide(color: AppColors.chromeBottomBorder)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.format_list_bulleted_rounded,
            size: 14,
            color: AppColors.accentCyan,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Flexible(
                  child: Text(
                    'Document Outline',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder, width: 0.8),
                  ),
                  child: Text(
                    '${_units.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          OutlineHeaderIconButton(
            key: const Key('outline_search_toggle'),
            icon: Icons.search_rounded,
            tooltip: _showSearch
                ? 'Hide search filter'
                : 'Filter outline sections',
            isActive: _showSearch,
            onTap: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchFilter = '';
                  _searchController.clear();
                }
              });
            },
          ),
          const SizedBox(width: 2),
          OutlineReorderToggleIconButton(
            isActive: _isReorderMode,
            onToggle: () {
              setState(() => _isReorderMode = !_isReorderMode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReorderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accentCyan.withAlpha(20),
        border: const Border(
          bottom: BorderSide(color: AppColors.sidebarBorder, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.swap_vert_rounded,
            size: 13,
            color: AppColors.accentCyan,
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Reorder Active',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.accentCyan,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _isReorderMode = false),
            child: const MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text(
                'Done',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentCyan,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: SizedBox(
        height: 24,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.controlBackground,
            hintText: 'Filter sections...',
            hintStyle: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 13,
              color: _isSearchFocused
                  ? AppColors.accentCyan
                  : AppColors.textMuted,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 22,
              minHeight: 24,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _clearSearch,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 24,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: AppColors.controlBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: AppColors.accentCyan),
            ),
          ),
          onChanged: (val) {
            setState(() => _searchFilter = val.trim().toLowerCase());
          },
        ),
      ),
    );
  }

  Widget _buildOutlineBody() {
    final filtered = _units.where((u) {
      if (_searchFilter.isEmpty) return true;
      return u.title.toLowerCase().contains(_searchFilter) ||
          u.docUri.fileName.toLowerCase().contains(_searchFilter);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Text(
            'No matching sections found',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ),
      );
    }

    if (_isReorderMode && _searchFilter.isEmpty) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        itemCount: filtered.length,
        onReorderStart: (_) => _isDragging = true,
        onReorderEnd: (_) => _isDragging = false,
        // ignore: deprecated_member_use
        onReorder: _handleReorder,
        buildDefaultDragHandles: false,
        itemBuilder: (context, index) {
          final unit = filtered[index];
          final origIndex = _units.indexOf(unit);
          return ReorderableDragStartListener(
            key: ValueKey(unit.id),
            index: index,
            child: OutlineTile(
              unit: unit,
              index: origIndex,
              isReorderMode: true,
              onTap: () => widget.onUnitSelected?.call(unit),
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final unit = filtered[index];
        final origIndex = _units.indexOf(unit);
        return OutlineTile(
          key: ValueKey(unit.id),
          unit: unit,
          index: origIndex,
          isReorderMode: false,
          onTap: () => widget.onUnitSelected?.call(unit),
        );
      },
    );
  }
}
