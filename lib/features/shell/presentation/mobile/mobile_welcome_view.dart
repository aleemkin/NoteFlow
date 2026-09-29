import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/vault/vault.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';
import 'package:noteflow/features/support/support.dart';
import 'widgets/widgets.dart';

/// Mobile-optimized Welcome / Onboarding view for Android.
///
/// Designed from scratch for touch screens:
/// - Prominent thumb-friendly primary action tiles (Choose Folder, New Vault, Explore Sample).
/// - Grouped recent workspaces card with search, breadcrumb path display, and swipe to remove.
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
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeroHeader(),
                            const SizedBox(height: 32),
                            WorkspaceActionCards(
                              onOpenVault: widget.onOpenVault,
                              onCreateVault: widget.onCreateVault,
                              onOpenSampleVault: widget.onOpenSampleVault,
                            ),
                            const SizedBox(height: 32),
                            RecentWorkspacesCard(
                              recentVaults: recentVaults,
                              isLoading: loadingRecents,
                              onOpenVaultPath: widget.onOpenVaultPath,
                              onRemoveRecent: removeRecentVault,
                              onClearRecents: clearAllRecentVaults,
                              enableSearch: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          18,
                          horizontalPadding,
                          0,
                        ),
                        child: WelcomeSupportCard(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SupportScreen(),
                              ),
                            );
                          },
                        ),
                      ),
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
}
