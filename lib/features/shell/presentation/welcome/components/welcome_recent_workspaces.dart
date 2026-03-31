import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'welcome_workspace_list_item.dart';

/// Recent workspaces list section with search filtering, empty state, and history management.
class WelcomeRecentWorkspaces extends StatefulWidget {
  final List<String> recentVaults;
  final bool isLoading;
  final ValueChanged<String> onOpenVaultPath;
  final ValueChanged<String> onRemoveRecent;
  final VoidCallback onClearRecents;

  const WelcomeRecentWorkspaces({
    super.key,
    required this.recentVaults,
    required this.isLoading,
    required this.onOpenVaultPath,
    required this.onRemoveRecent,
    required this.onClearRecents,
  });

  @override
  State<WelcomeRecentWorkspaces> createState() =>
      _WelcomeRecentWorkspacesState();
}

class _WelcomeRecentWorkspacesState extends State<WelcomeRecentWorkspaces> {
  static const Color _surfaceContainer = Color(0xFF1C2026);
  static const Color _surfaceContainerLow = Color(0xFF181C22);
  static const Color _surfaceContainerHighest = Color(0xFF31353C);
  static const Color _primary = Color(0xFFADC6FF);
  static const Color _onSurface = Color(0xFFDFE2EB);
  static const Color _onSurfaceVariant = Color(0xFFC2C6D6);
  static const Color _outline = Color(0xFF8C909F);
  static const Color _outlineVariant = Color(0xFF424754);

  final TextEditingController _filterController = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  String _formatDisplayPath(String fullPath) {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty && fullPath.startsWith(home)) {
      return '~${fullPath.substring(home.length)}';
    }
    return fullPath;
  }

  List<String> get _filteredVaults {
    if (_filterQuery.trim().isEmpty) return widget.recentVaults;
    final q = _filterQuery.trim().toLowerCase();
    return widget.recentVaults.where((path) {
      final name = p.basename(path).toLowerCase();
      final full = path.toLowerCase();
      return name.contains(q) || full.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Text(
              'RECENT WORKSPACES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: _outline,
              ),
            ),
            if (widget.recentVaults.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.recentVaults.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _outline,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: widget.onClearRecents,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Clear History',
                    style: TextStyle(fontSize: 11, color: _outline),
                  ),
                ),
              ),
            ],
          ],
        ),

        // Search / Filter if >= 3 vaults
        if (widget.recentVaults.length >= 3) ...[
          const SizedBox(height: 10),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 15, color: _outline),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _filterController,
                    style: const TextStyle(fontSize: 12, color: _onSurface),
                    decoration: const InputDecoration(
                      hintText: 'Filter recent workspaces...',
                      hintStyle: TextStyle(fontSize: 12, color: _outline),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) => setState(() => _filterQuery = val),
                  ),
                ),
                if (_filterQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _filterController.clear();
                      setState(() => _filterQuery = '');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: _outline,
                    ),
                  ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 10),

        // Container of items or empty state
        Container(
          decoration: BoxDecoration(
            color: _surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
        ),
      );
    }

    if (widget.recentVaults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open_rounded, size: 30, color: _outline),
              SizedBox(height: 10),
              Text(
                'No Recent Workspaces',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _onSurface,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Open a local folder to start organizing notes and drawings.',
                style: TextStyle(fontSize: 12, color: _onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredVaults;

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No matching workspaces found',
            style: TextStyle(fontSize: 12, color: _outline),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: _surfaceContainer),
      itemBuilder: (context, index) {
        final vaultPath = filtered[index];
        final vaultName = p.basename(vaultPath);
        final displayPath = _formatDisplayPath(vaultPath);

        return WelcomeWorkspaceListItem(
          name: vaultName,
          displayPath: displayPath,
          fullPath: vaultPath,
          onTap: () => widget.onOpenVaultPath(vaultPath),
          onRemove: () => widget.onRemoveRecent(vaultPath),
        );
      },
    );
  }
}
