import 'package:flutter/material.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';

/// Primary grouped actions card for workspace management (Open Folder, New Vault, Sample Vault).
///
/// Shared across the mobile welcome view and vault details tab.
class WorkspaceActionCards extends StatelessWidget {
  const WorkspaceActionCards({
    super.key,
    required this.onOpenVault,
    this.onCreateVault,
    this.onOpenSampleVault,
  });

  final VoidCallback onOpenVault;
  final VoidCallback? onCreateVault;
  final VoidCallback? onOpenSampleVault;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF21262D)),
      ),
      child: Column(
        children: [
          // Primary: Open Local Folder
          _buildActionTile(
            icon: const AppSvgIcon.folder(size: 24),
            title: 'Open Local Folder',
            subtitle: 'Choose an existing notebook folder',
            isPrimary: true,
            onTap: onOpenVault,
            showDivider: onCreateVault != null || onOpenSampleVault != null,
          ),

          // Secondary: Create New Vault
          if (onCreateVault != null)
            _buildActionTile(
              icon: const AppSvgIcon.newFolder(size: 24),
              title: 'New Vault',
              subtitle: 'Create a brand new empty vault',
              onTap: onCreateVault!,
              showDivider: onOpenSampleVault != null,
            ),

          // Tertiary: Explore Sample Vault
          if (onOpenSampleVault != null)
            _buildActionTile(
              icon: const AppSvgIcon.openBook(size: 24),
              title: 'Explore Sample Vault',
              subtitle: 'Try notes, tags, and drawing canvas',
              onTap: onOpenSampleVault!,
            ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required Widget icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  SizedBox(width: 38, height: 38, child: Center(child: icon)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDFE2EB),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8B949E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: isPrimary
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFF484F58),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFF21262D)),
          ),
      ],
    );
  }
}
