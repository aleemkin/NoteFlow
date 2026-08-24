import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/vault/vault.dart';

import 'mobile_quick_action_sheet.dart';

/// Dedicated visual gallery for all Excalidraw diagrams in the vault.
///
/// Features:
/// - Visual grid of drawings with auto-generated PNG canvas snapshots
/// - Quick creation of new Excalidraw sketches
/// - 1-tap full-screen editing
/// - Context menu for rename, duplicate, delete
class MobileDrawingsGallery extends ConsumerStatefulWidget {
  final ValueChanged<String> onOpenDrawing;
  final VoidCallback onCreateDrawing;

  const MobileDrawingsGallery({
    super.key,
    required this.onOpenDrawing,
    required this.onCreateDrawing,
  });

  @override
  ConsumerState<MobileDrawingsGallery> createState() =>
      _MobileDrawingsGalleryState();
}

class _MobileDrawingsGalleryState extends ConsumerState<MobileDrawingsGallery> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VaultTreeNode> _findAllDrawings(VaultTreeRepository treeRepo) {
    final results = <VaultTreeNode>[];
    void recurse(VaultTreeNode node) {
      if (!node.isDirectory && node.name.endsWith('.excalidraw')) {
        results.add(node);
      }
      for (final child in node.children) {
        recurse(child);
      }
    }

    if (treeRepo.root != null) {
      recurse(treeRepo.root!);
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final treeRepo = ref.watch(vaultTreeRepositoryProvider);
    final allDrawings = _findAllDrawings(treeRepo);

    final query = _searchQuery.trim().toLowerCase();
    final drawings = query.isEmpty
        ? allDrawings
        : allDrawings
              .where((d) => d.name.toLowerCase().contains(query))
              .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar

            // Search bar
            if (allDrawings.length > 4)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search drawings...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.borderSubtle,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.borderSubtle,
                      ),
                    ),
                  ),
                ),
              ),

            // Grid of drawings
            Expanded(
              child: drawings.isEmpty
                  ? _buildEmptyState(query.isNotEmpty)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth >= 600
                            ? 3
                            : 2;

                        return GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 88),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: drawings.length,
                          itemBuilder: (context, index) {
                            return _buildDrawingTile(context, drawings[index]);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingTile(BuildContext context, VaultTreeNode node) {
    final title = p.basenameWithoutExtension(node.name);
    final folder = p.dirname(node.uri.path);
    final hasFolder = folder.isNotEmpty && folder != '.';

    // Check for PNG preview file
    final manager = ref.read(vaultManagerProvider);
    final rootPath = manager.rootDirectoryPath;
    File? pngFile;
    if (rootPath != null) {
      final candidate = File(p.join(rootPath, '${node.uri.path}.png'));
      if (candidate.existsSync()) {
        pngFile = candidate;
      }
    }

    return Material(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onOpenDrawing(node.uri.path);
        },
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview canvas area
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1117),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                clipBehavior: Clip.antiAlias,
                child: pngFile != null
                    ? Image.file(
                        pngFile,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),

            // Metadata footer
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasFolder)
                          Text(
                            folder,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      MobileQuickActionSheet.showFileOptionsSheet(
                        context: context,
                        ref: ref,
                        filePath: node.uri.path,
                        isDirectory: false,
                        onOpen: () => widget.onOpenDrawing(node.uri.path),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.brush_outlined,
            size: 28,
            color: const Color(0xFFEC4899).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap to draw',
            style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.draw_rounded,
                size: 32,
                color: Color(0xFFEC4899),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No drawings found' : 'No diagrams yet',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Try a different search query.'
                  : 'Create visual mindmaps, flowcharts, and architecture diagrams with official Excalidraw.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: widget.onCreateDrawing,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Diagram'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
