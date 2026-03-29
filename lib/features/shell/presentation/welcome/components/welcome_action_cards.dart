import 'package:flutter/material.dart';
import 'package:noteflow/core/platform/app_platform.dart';
import 'welcome_action_card.dart';

/// Renders the primary action cards (Open Folder, Explore Sample, New Vault)
/// with a responsive multi-column or single-column layout.
class WelcomeActionCards extends StatelessWidget {
  static const Color _primary = Color(0xFFADC6FF);
  static const Color _onPrimary = Color(0xFF002E6A);
  static const Color _secondary = Color(0xFFFFB95F);
  static const Color _tertiary = Color(0xFF4EDEA3);
  static const Color _surfaceContainerHighest = Color(0xFF31353C);
  static const Color _onSurface = Color(0xFFDFE2EB);

  final VoidCallback onOpenVault;
  final VoidCallback? onOpenSampleVault;
  final VoidCallback? onCreateVault;

  const WelcomeActionCards({
    super.key,
    required this.onOpenVault,
    this.onOpenSampleVault,
    this.onCreateVault,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        final isDesktop = AppPlatform.isDesktop;

        final card1 = WelcomeActionCard(
          isHighlighted: true,
          icon: Icons.folder_open_rounded,
          iconColor: _primary,
          badgeText: isDesktop ? 'Ctrl+O' : 'Open',
          title: 'Open Local Folder',
          description:
              'Open any directory containing Markdown notes and drawings.',
          onTap: onOpenVault,
          button: FilledButton.icon(
            onPressed: onOpenVault,
            icon: const Icon(Icons.folder_rounded, size: 17),
            label: const Text('Choose Folder'),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: _onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );

        final card2 = WelcomeActionCard(
          isHighlighted: false,
          icon: Icons.auto_stories_rounded,
          iconColor: _secondary,
          badgeText: 'Sandbox',
          title: 'Explore Sample Vault',
          description:
              'Interactive sandbox with architecture notes and sample sketches.',
          onTap: onOpenSampleVault,
          button: FilledButton(
            onPressed: onOpenSampleVault,
            style: FilledButton.styleFrom(
              backgroundColor: _surfaceContainerHighest,
              foregroundColor: _onSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Launch Sandbox'),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 15),
              ],
            ),
          ),
        );

        final card3 = WelcomeActionCard(
          isHighlighted: false,
          icon: Icons.add_box_rounded,
          iconColor: _tertiary,
          badgeText: isDesktop ? 'Ctrl+N' : 'New',
          title: 'New Vault',
          description:
              'Create an empty workspace with default config and templates.',
          onTap: onCreateVault ?? onOpenVault,
          button: FilledButton.icon(
            onPressed: onCreateVault ?? onOpenVault,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Create Empty'),
            style: FilledButton.styleFrom(
              backgroundColor: _surfaceContainerHighest,
              foregroundColor: _onSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: card1),
              const SizedBox(width: 14),
              Expanded(child: card2),
              const SizedBox(width: 14),
              Expanded(child: card3),
            ],
          );
        } else {
          return Column(
            children: [
              card1,
              const SizedBox(height: 14),
              card2,
              const SizedBox(height: 14),
              card3,
            ],
          );
        }
      },
    );
  }
}
