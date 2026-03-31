import 'package:flutter/material.dart';
import 'package:noteflow/core/platform/app_platform.dart';
import 'package:noteflow/features/vault/vault.dart';
import 'components/welcome.dart';

export 'components/welcome.dart';

/// Sleek, minimal workspace launcher and vault manager for noteflow.
class WelcomeView extends StatefulWidget {
  final VoidCallback onOpenVault;
  final ValueChanged<String> onOpenVaultPath;
  final VoidCallback? onOpenSampleVault;
  final VoidCallback? onCreateVault;

  const WelcomeView({
    super.key,
    required this.onOpenVault,
    required this.onOpenVaultPath,
    this.onOpenSampleVault,
    this.onCreateVault,
  });

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> with RecentVaultsMixin {
  static const Color _surface = Color(0xFF10141A);

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppPlatform.isDesktop;

    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          // Main Scrollable Content Area
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 896),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Section
                        const WelcomeHero(),

                        const SizedBox(height: 36),

                        // Action Cards (Open Local Folder, Explore Sample Vault, New Vault)
                        WelcomeActionCards(
                          onOpenVault: widget.onOpenVault,
                          onOpenSampleVault: widget.onOpenSampleVault,
                          onCreateVault: widget.onCreateVault,
                        ),

                        const SizedBox(height: 36),

                        // Recent Workspaces Section
                        WelcomeRecentWorkspaces(
                          recentVaults: recentVaults,
                          isLoading: loadingRecents,
                          onOpenVaultPath: widget.onOpenVaultPath,
                          onRemoveRecent: removeRecentVault,
                          onClearRecents: clearAllRecentVaults,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Footer Bar (Keyboard shortcuts)
          if (isDesktop) const WelcomeFooter(),
        ],
      ),
    );
  }
}
