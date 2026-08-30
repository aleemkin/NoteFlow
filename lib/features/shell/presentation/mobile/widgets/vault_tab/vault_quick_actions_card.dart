import 'package:flutter/material.dart';

/// Card providing grouped quick actions for mobile vault management (Open, Create, Explore Sample).
class VaultQuickActionsCard extends StatelessWidget {
  final VoidCallback onOpenVault;
  final VoidCallback onCreateVault;
  final VoidCallback onOpenSampleVault;

  const VaultQuickActionsCard({
    super.key,
    required this.onOpenVault,
    required this.onCreateVault,
    required this.onOpenSampleVault,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF21262D)),
          ),
          child: Column(
            children: [
              _buildActionRow(
                icon: Icons.folder_open_outlined,
                iconColor: const Color(0xFF58A6FF),
                title: 'Open Local Vault',
                subtitle: 'Select an existing folder on device',
                onTap: onOpenVault,
                showDivider: true,
              ),
              _buildActionRow(
                icon: Icons.create_new_folder_outlined,
                iconColor: const Color(0xFF34D399),
                title: 'Create New Vault',
                subtitle: 'Initialize a clean workspace',
                onTap: onCreateVault,
                showDivider: true,
              ),
              _buildActionRow(
                icon: Icons.explore_outlined,
                iconColor: const Color(0xFFA78BFA),
                title: 'Explore Sample Vault',
                subtitle: 'Built-in guides and diagrams',
                onTap: onOpenSampleVault,
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(icon, color: iconColor, size: 17),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDFE2EB),
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8B949E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF484F58),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 58, color: Color(0xFF21262D)),
      ],
    );
  }
}
