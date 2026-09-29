import 'dart:io';
import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';
import 'package:path/path.dart' as p;

/// Card displaying the list of recently opened workspaces on mobile with quick open and swipe-to-remove actions.
///
/// Features:
/// - Grouped container with subtle dividers between workspaces.
/// - Production-ready display path formatting (human-friendly breadcrumb, no raw monospace).
/// - Clean section header with badge counter and optional Clear All action.
/// - Optional search filter when there are multiple recent workspaces.
/// - Touch-first swipe-to-remove (`Dismissible`) with red delete background.
class RecentWorkspacesCard extends StatefulWidget {
  final List<String> recentVaults;
  final bool isLoading;
  final String? currentVaultPath;
  final ValueChanged<String> onOpenVaultPath;
  final ValueChanged<String> onRemoveRecent;
  final VoidCallback? onClearRecents;
  final bool enableSearch;

  const RecentWorkspacesCard({
    super.key,
    required this.recentVaults,
    required this.isLoading,
    this.currentVaultPath,
    required this.onOpenVaultPath,
    required this.onRemoveRecent,
    this.onClearRecents,
    this.enableSearch = false,
  });

  /// Formats a raw filesystem path into a production-ready, human-readable breadcrumb.
  static String formatDisplayPath(String fullPath) {
    if (fullPath.isEmpty) return '';

    // Normalize backslashes (Windows)
    var path = fullPath.replaceAll(r'\', '/');
    while (path.endsWith('/') && path.length > 1) {
      path = path.substring(0, path.length - 1);
    }

    // Replace user home directory
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      final normalizedHome = home.replaceAll(r'\', '/');
      if (path.startsWith(normalizedHome)) {
        return '~${path.substring(normalizedHome.length)}';
      }
    }

    // Android primary shared storage: /storage/emulated/0/...
    const androidStorage = '/storage/emulated/0';
    if (path.startsWith(androidStorage)) {
      final sub = path.substring(androidStorage.length);
      final segments = sub.split('/').where((s) => s.isNotEmpty).toList();
      if (segments.isEmpty) return 'Device Storage';
      return segments.join(' / ');
    }

    // Android app-private storage: /data/user/0/<pkg>/app_flutter/...
    final appDataMatch = RegExp(
      r'^/data/(?:user/\d+|data)/[^/]+/(?:app_flutter/)?(.*)$',
    ).firstMatch(path);
    if (appDataMatch != null) {
      final sub = appDataMatch.group(1);
      if (sub == null || sub.isEmpty) return 'Local App Storage';
      final segments = sub.split('/').where((s) => s.isNotEmpty).toList();
      return 'App Storage / ${segments.join(' / ')}';
    }

    // iOS container sandbox
    final iosMatch = RegExp(
      r'^/var/mobile/Containers/Data/Application/[^/]+/Documents/?(.*)$',
    ).firstMatch(path);
    if (iosMatch != null) {
      final sub = iosMatch.group(1);
      if (sub == null || sub.isEmpty) return 'On My iPhone';
      return 'On My iPhone / $sub';
    }

    // Shorten long paths by displaying parent and folder
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length > 3) {
      return '.../${segments.sublist(segments.length - 2).join('/')}';
    }

    return path;
  }

  @override
  State<RecentWorkspacesCard> createState() => _RecentWorkspacesCardState();
}

class _RecentWorkspacesCardState extends State<RecentWorkspacesCard> {
  String _searchFilter = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredList {
    if (_searchFilter.trim().isEmpty) return widget.recentVaults;
    final q = _searchFilter.trim().toLowerCase();
    return widget.recentVaults.where((path) {
      final name = p.basename(path).toLowerCase();
      return name.contains(q) || path.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredList;
    final hasRecents = widget.recentVaults.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'RECENT WORKSPACES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B949E),
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (hasRecents) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF21262D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.recentVaults.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B949E),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (widget.onClearRecents != null && hasRecents)
                TextButton(
                  onPressed: widget.onClearRecents,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF85149),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Optional search input when >= 4 recents and enableSearch is true
        if (widget.enableSearch &&
            hasRecents &&
            widget.recentVaults.length > 3) ...[
          const SizedBox(height: 4),
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchFilter = val),
            style: const TextStyle(fontSize: 13, color: Color(0xFFDFE2EB)),
            decoration: InputDecoration(
              hintText: 'Search recent workspaces...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8B949E),
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: Color(0xFF8B949E),
              ),
              suffixIcon: _searchFilter.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: 16,
                        color: Color(0xFF8B949E),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchFilter = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              filled: true,
              fillColor: const Color(0xFF161B22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF21262D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF21262D)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF58A6FF)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (widget.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          )
        else if (widget.recentVaults.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF21262D)),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_off_outlined,
                    size: 28,
                    color: Color(0xFF8B949E),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No Recent Workspaces',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDFE2EB),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Open a local folder or sample vault to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF8B949E)),
                  ),
                ],
              ),
            ),
          )
        else if (list.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF21262D)),
            ),
            child: const Center(
              child: Text(
                'No workspaces match your search',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF8B949E)),
              ),
            ),
          )
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF21262D)),
            ),
            child: Column(
              children: List.generate(list.length, (index) {
                final vaultPath = list[index];
                final isCurrent =
                    widget.currentVaultPath != null &&
                    widget.currentVaultPath == vaultPath;
                final name = p.basename(vaultPath);
                final isLast = index == list.length - 1;

                return Dismissible(
                  key: Key('recent_vault_$vaultPath'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 18),
                    color: const Color(0xFFF85149).withValues(alpha: 0.18),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Remove',
                          style: TextStyle(
                            color: Color(0xFFF85149),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFF85149),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (_) => widget.onRemoveRecent(vaultPath),
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isCurrent
                              ? null
                              : () => widget.onOpenVaultPath(vaultPath),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 38,
                                  height: 38,
                                  child: Center(
                                    child: AppSvgIcon(
                                      assetPath: AppSvgIcons.openFolder,
                                      color: isCurrent
                                          ? const Color(0xFF58A6FF)
                                          : const Color(0xFF8B949E),
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              name.isNotEmpty
                                                  ? name
                                                  : vaultPath,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: isCurrent
                                                    ? const Color(0xFF58A6FF)
                                                    : const Color(0xFFDFE2EB),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isCurrent) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF34D399),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        RecentWorkspacesCard.formatDisplayPath(
                                          vaultPath,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          height: 1.3,
                                          color: Color(0xFF8B949E),
                                          letterSpacing: 0.1,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          indent: 44,
                          color: Color(0xFF21262D),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
