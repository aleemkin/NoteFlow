import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/search/search.dart';
import 'package:noteflow/features/vault/presentation/dialogs/shortcuts_dialog.dart';

/// Compact, modern spotlight search trigger in the title bar.
class SearchWidget extends StatelessWidget {
  final void Function(String path)? onResultSelected;
  final bool compact;

  const SearchWidget({super.key, this.onResultSelected, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        icon: const Icon(Icons.search, size: 17),
        tooltip: 'Search notes & commands (Ctrl+K)',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        color: AppColors.textMuted,
        onPressed: () => SpotlightSearchDialog.show(context, onResultSelected),
      );
    }

    return InkWell(
      onTap: () => SpotlightSearchDialog.show(context, onResultSelected),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSidebar,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, size: 13, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            const Text(
              'Search notes...',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Text(
                'Ctrl+K',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered Spotlight / Command Palette Dialog for fast knowledge retrieval and quick actions.
class SpotlightSearchDialog extends ConsumerStatefulWidget {
  final void Function(String path)? onResultSelected;

  const SpotlightSearchDialog({super.key, this.onResultSelected});

  static Future<void> show(
    BuildContext context,
    void Function(String path)? onResultSelected,
  ) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) =>
          SpotlightSearchDialog(onResultSelected: onResultSelected),
    );
  }

  @override
  ConsumerState<SpotlightSearchDialog> createState() =>
      _SpotlightSearchDialogState();
}

class _SpotlightSearchDialogState extends ConsumerState<SpotlightSearchDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<SearchResult> _results = [];
  bool _isSearching = false;
  int _selectedIndex = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
          _selectedIndex = 0;
        });
      }
      return;
    }

    setState(() => _isSearching = true);
    final service = ref.read(searchServiceProvider);
    final results = await service.search(query);

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
        _selectedIndex = 0;
      });
    }
  }

  void _selectResult(SearchResult result) {
    Navigator.of(context).pop();
    widget.onResultSelected?.call(result.uri.path);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (_results.isNotEmpty) {
                setState(() {
                  _selectedIndex = (_selectedIndex + 1).clamp(
                    0,
                    _results.length - 1,
                  );
                });
                return KeyEventResult.handled;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (_results.isNotEmpty) {
                setState(() {
                  _selectedIndex = (_selectedIndex - 1).clamp(
                    0,
                    _results.length - 1,
                  );
                });
                return KeyEventResult.handled;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.enter) {
              if (_results.isNotEmpty && _selectedIndex < _results.length) {
                _selectResult(_results[_selectedIndex]);
                return KeyEventResult.handled;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          width: 580,
          margin: const EdgeInsets.only(top: 50),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderDefault, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Input Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: _onChanged,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search notes, headings, drawings, tags...',
                          hintStyle: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_isSearching)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    else if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Results or Quick Actions Command Palette
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: _buildResultsBody(),
              ),

              // Footer Bar with Keyboard Shortcuts
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSidebar,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(9),
                  ),
                  border: Border(
                    top: BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                child: const Row(
                  children: [
                    Text(
                      '↑↓ Navigate',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(width: 14),
                    Text(
                      '↵ Open',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(width: 14),
                    Text(
                      'ESC Close',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Noteflow Spotlight',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsBody() {
    if (_controller.text.trim().isEmpty) {
      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'QUICK COMMANDS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          _CommandTile(
            icon: Icons.keyboard_outlined,
            title: 'View Keyboard Shortcuts',
            shortcut: '?',
            onTap: () {
              Navigator.pop(context);
              ShortcutsDialog.show(context);
            },
          ),
          _CommandTile(
            icon: Icons.auto_stories,
            title: 'Read Roll Mode',
            shortcut: 'Ctrl+1',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _CommandTile(
            icon: Icons.edit_note,
            title: 'Edit View Mode',
            shortcut: 'Ctrl+2',
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      );
    }

    if (_results.isEmpty && !_isSearching) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        alignment: Alignment.center,
        child: Text(
          'No matching notes found for "${_controller.text}"',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        final isSelected = index == _selectedIndex;
        final isDraw = result.fileName.endsWith('.excalidraw');

        return InkWell(
          onTap: () => _selectResult(result),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 10),
                  child: Icon(
                    isDraw ? Icons.draw_outlined : Icons.description_outlined,
                    size: 16,
                    color: isSelected
                        ? AppColors.primary
                        : (isDraw ? AppColors.secondary : AppColors.textMuted),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              result.fileName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSidebar,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${result.matchCount} match${result.matchCount == 1 ? "" : "es"}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (result.snippet.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          result.snippet,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommandTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String shortcut;
  final VoidCallback onTap;

  const _CommandTile({
    required this.icon,
    required this.title,
    required this.shortcut,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceSidebar,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                shortcut,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
