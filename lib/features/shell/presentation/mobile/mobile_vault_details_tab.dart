import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';
import 'package:noteflow/features/support/support.dart';
import 'package:noteflow/features/vault/vault.dart';
import 'widgets/vault_tab/vault_overview_card.dart';
import 'widgets/workspace_action_cards.dart';
import 'widgets/recent_workspaces_card.dart';

/// Clean and minimal mobile Vault tab:
/// - Active workspace overview with key metrics (notes, drawings, folders)
/// - Grouped vault actions (Open, Create, Sample)
/// - Recent workspaces with quick switch and remove
/// - Workspace actions (Contribute and Close Vault)
class MobileVaultDetailsTab extends ConsumerStatefulWidget {
  final VoidCallback onOpenVault;
  final VoidCallback onCreateVault;
  final VoidCallback onOpenSampleVault;
  final ValueChanged<String> onOpenVaultPath;
  final VoidCallback onCloseVault;
  final VoidCallback? onContribute;

  const MobileVaultDetailsTab({
    super.key,
    required this.onOpenVault,
    required this.onCreateVault,
    required this.onOpenSampleVault,
    required this.onOpenVaultPath,
    required this.onCloseVault,
    this.onContribute,
  });

  @override
  ConsumerState<MobileVaultDetailsTab> createState() =>
      _MobileVaultDetailsTabState();
}

class _MobileVaultDetailsTabState extends ConsumerState<MobileVaultDetailsTab>
    with RecentVaultsMixin {
  @override
  Widget build(BuildContext context) {
    final vault =
        ref.watch(currentVaultProvider) ??
        ref.watch(vaultSessionControllerProvider).currentVault;
    final treeRepo = ref.watch(vaultTreeRepositoryProvider);
    final allNodes = <VaultTreeNode>[];
    void collect(VaultTreeNode node) {
      allNodes.add(node);
      for (final child in node.children) {
        collect(child);
      }
    }

    if (treeRepo.root != null) {
      for (final child in treeRepo.root!.children) {
        collect(child);
      }
    }
    final noteCount = allNodes
        .where((n) => !n.isDirectory && n.uri.path.endsWith('.md'))
        .length;
    final drawingCount = allNodes
        .where((n) => !n.isDirectory && n.uri.path.endsWith('.excalidraw'))
        .length;
    final folderCount = allNodes.where((n) => n.isDirectory).length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          const SizedBox(height: 24),
          Column(
            children: [
              const SizedBox(height: 8),
              const AppSvgIcon.appIcon(width: 44, height: 44),
              const SizedBox(height: 8),
              const Text(
                'Noteflow',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Color(0xFFDFE2EB),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Local-first knowledge notebook\nwith Markdown & Excalidraw diagrams',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: Color(0xFF8B949E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 1. Current Active Workspace Card
          VaultOverviewCard(
            vaultDisplayName: vault?.displayName ?? 'Notebook Workspace',
            noteCount: noteCount,
            drawingCount: drawingCount,
            folderCount: folderCount,
          ),

          const SizedBox(height: 22),

          // 2. Grouped Actions Section
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'ACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8B949E),
                letterSpacing: 0.8,
              ),
            ),
          ),
          WorkspaceActionCards(
            onOpenVault: widget.onOpenVault,
            onCreateVault: widget.onCreateVault,
            onOpenSampleVault: widget.onOpenSampleVault,
          ),

          const SizedBox(height: 24),

          // 3. Recent Workspaces Section
          RecentWorkspacesCard(
            recentVaults: recentVaults,
            isLoading: loadingRecents,
            currentVaultPath: vault?.rootUri.path,
            onOpenVaultPath: widget.onOpenVaultPath,
            onRemoveRecent: removeRecentVault,
          ),

          const SizedBox(height: 28),

          // 4. Action Buttons (Contribute & Close Vault)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                icon: const AppSvgIcon.longCoffee(
                  size: 16,
                  color: Color(0xFFF59E0B),
                ),
                label: const Text(
                  'Contribute',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0x33F59E0B)),
                  ),
                  backgroundColor: const Color(0x12F59E0B),
                ),
                onPressed: () {
                  if (widget.onContribute != null) {
                    widget.onContribute!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SupportScreen(),
                      ),
                    );
                  }
                },
              ),
              TextButton.icon(
                icon: const Icon(
                  Icons.power_settings_new_rounded,
                  size: 16,
                  color: Color(0xFFF85149),
                ),
                label: const Text(
                  'Close Vault',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF85149),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0x33F85149)),
                  ),
                  backgroundColor: const Color(0x12F85149),
                ),
                onPressed: widget.onCloseVault,
              ),
            ],
          ),

          const SizedBox(height: 36),
        ],
      ),
    );
  }
}
