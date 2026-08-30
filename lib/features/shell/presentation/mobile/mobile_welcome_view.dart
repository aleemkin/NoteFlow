import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/vault/vault.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';
import 'widgets/widgets.dart';

/// Mobile-optimized Welcome / Onboarding view for Android.
///
/// Designed from scratch for touch screens:
/// - Prominent thumb-friendly primary action tiles (Choose Folder, New Vault, Explore Sample).
/// - Clean recent vaults list with search, path display, and quick removal.
/// - Adaptive layout for small phones up to tablets.
class MobileWelcomeView extends StatefulWidget {
  final VoidCallback onOpenVault;
  final ValueChanged<String> onOpenVaultPath;
  final VoidCallback? onOpenSampleVault;
  final VoidCallback? onCreateVault;

  const MobileWelcomeView({
    super.key,
    required this.onOpenVault,
    required this.onOpenVaultPath,
    this.onOpenSampleVault,
    this.onCreateVault,
  });

  @override
  State<MobileWelcomeView> createState() => _MobileWelcomeViewState();
}

class _MobileWelcomeViewState extends State<MobileWelcomeView>
    with RecentVaultsMixin {
  String _searchFilter = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getFilteredRecents(List<String> recents) {
    if (_searchFilter.trim().isEmpty) return recents;
    final q = _searchFilter.trim().toLowerCase();
    return recents.where((path) {
      final name = p.basename(path).toLowerCase();
      return name.contains(q) || path.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            final horizontalPadding = isTablet ? 32.0 : 16.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          16,
                          horizontalPadding,
                          12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeroHeader(),
                            const SizedBox(height: 16),
                            WelcomeActionSection(
                              onOpenVault: widget.onOpenVault,
                              onCreateVault: widget.onCreateVault,
                              onOpenSampleVault: widget.onOpenSampleVault,
                            ),
                            const SizedBox(height: 20),
                            _buildRecentsHeader(recentVaults),
                          ],
                        ),
                      ),
                    ),
                    _buildRecentsListSliver(
                      horizontalPadding,
                      recentVaults,
                      loadingRecents,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 24,
                        ),
                        child: const WelcomeLegalFooter(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      children: [
        const SizedBox(height: 24),
        const AppSvgIcon.appIcon(width: 56, height: 56),
        const SizedBox(height: 12),
        const Text(
          'Noteflow',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Color(0xFFDFE2EB),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Local-first knowledge notebook\nwith Markdown & Excalidraw diagrams',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF8B949E)),
        ),
      ],
    );
  }

  Widget _buildRecentsHeader(List<String> recentVaults) {
    final hasRecents = recentVaults.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'RECENT WORKSPACES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (hasRecents) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceNavbar,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${recentVaults.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (hasRecents)
              TextButton(
                onPressed: clearAllRecentVaults,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Clear All',
                  style: TextStyle(fontSize: 12, color: AppColors.markDanger),
                ),
              ),
          ],
        ),
        if (hasRecents && recentVaults.length > 3) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchFilter = val),
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search recent workspaces...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: AppColors.textMuted,
              ),
              suffixIcon: _searchFilter.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: 16,
                        color: AppColors.textMuted,
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
        ],
      ],
    );
  }

  Widget _buildRecentsListSliver(
    double horizontalPadding,
    List<String> recentVaults,
    bool loadingRecents,
  ) {
    if (loadingRecents) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (recentVaults.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.folder_off_outlined,
                  size: 36,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 10),
                const Text(
                  'No Recent Workspaces',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Open a local folder or sample vault to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: widget.onOpenVault,
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: const Text('Choose Folder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final list = _getFilteredRecents(recentVaults);

    if (list.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          child: const Center(
            child: Text(
              'No workspaces match your search',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final path = list[index];
          final name = p.basename(path);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: const Color(0xFF161B22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF21262D)),
              ),
              child: InkWell(
                onTap: () => widget.onOpenVaultPath(path),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF21262D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.folder_outlined,
                            size: 18,
                            color: Color(0xFF58A6FF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDFE2EB),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              path,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8B949E),
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Color(0xFF58A6FF),
                        ),
                        tooltip: 'Open workspace',
                        splashRadius: 16,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => widget.onOpenVaultPath(path),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF6E7681),
                        ),
                        tooltip: 'Remove from recents',
                        splashRadius: 16,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => removeRecentVault(path),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }, childCount: list.length),
      ),
    );
  }
}
