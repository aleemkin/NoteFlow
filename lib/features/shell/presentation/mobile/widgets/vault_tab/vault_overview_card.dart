import 'package:flutter/material.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';

/// Card displaying the active workspace name, active badge, and note/drawing/folder metrics.
class VaultOverviewCard extends StatelessWidget {
  final String vaultDisplayName;
  final int noteCount;
  final int drawingCount;
  final int folderCount;

  const VaultOverviewCard({
    super.key,
    required this.vaultDisplayName,
    required this.noteCount,
    required this.drawingCount,
    required this.folderCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF21262D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Center(
                child: AppSvgIcon.folder(
                  color: Color(0xFF58A6FF),
                  width: 18,
                  height: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        vaultDisplayName,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDFE2EB),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x1F34D399),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x3D34D399)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34D399),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF34D399),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF21262D), height: 1),
          const SizedBox(height: 12),
          // Sleek 3-stat strip
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  count: '$noteCount',
                  label: 'Notes',
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFF58A6FF),
                ),
              ),
              Container(width: 1, height: 15, color: const Color(0xFF21262D)),
              Expanded(
                child: _buildMetricItem(
                  count: '$drawingCount',
                  label: 'Drawings',
                  icon: Icons.brush_outlined,
                  iconColor: const Color(0xFFF472B6),
                ),
              ),
              Container(width: 1, height: 15, color: const Color(0xFF21262D)),
              Expanded(
                child: _buildMetricItem(
                  count: '$folderCount',
                  label: 'Folders',
                  icon: Icons.folder_outlined,
                  iconColor: const Color(0xFF34D399),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String count,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text(
              count,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDFE2EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8B949E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
