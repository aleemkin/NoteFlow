import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/support/domain/support_tier.dart';

/// Interactive card component representing a single [SupportTier].
///
/// Displays the tier emoji icon, title, optional POPULAR highlight badge,
/// descriptive impact text, and localized price.
class SupportTierCard extends StatelessWidget {
  final SupportTier tier;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  const SupportTierCard({
    super.key,
    required this.tier,
    required this.isSelected,
    required this.onTap,
    this.accentColor = const Color(0xFFF59E0B),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B2230) : const Color(0xFF13171F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (tier.isPopular
                    ? const Color(0x44F59E0B)
                    : const Color(0xFF262E3B)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(tier.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tier.name,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFFDFE2EB),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tier.isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x2EF59E0B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF59E0B),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tier.description,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              tier.priceDisplay,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? accentColor : const Color(0xFFDFE2EB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
