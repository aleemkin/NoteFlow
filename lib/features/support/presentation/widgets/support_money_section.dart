import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/support/domain/support_tier.dart';
import 'package:noteflow/features/support/presentation/widgets/support_tier_card.dart';

/// Section allowing users to select a tip tier and send a contribution.
class SupportMoneySection extends StatelessWidget {
  final List<SupportTier> tiers;
  final SupportTier selectedTier;
  final ValueChanged<SupportTier> onSelectTier;
  final bool isPurchasing;
  final VoidCallback onPayTier;
  final Color accentColor;

  const SupportMoneySection({
    super.key,
    required this.tiers,
    required this.selectedTier,
    required this.onSelectTier,
    required this.isPurchasing,
    required this.onPayTier,
    this.accentColor = const Color(0xFFF59E0B),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.coffee_outlined,
              size: 18,
              color: accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              'CONTRIBUTE WITH MONEY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Send a one-time tip to fuel new features and optimizations.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),

        // List of support tiers
        ...tiers.map((tier) {
          final isSelected = selectedTier.id == tier.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SupportTierCard(
              tier: tier,
              isSelected: isSelected,
              onTap: () => onSelectTier(tier),
              accentColor: accentColor,
            ),
          );
        }),

        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isPurchasing ? null : onPayTier,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isPurchasing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.coffee_rounded, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Send ${selectedTier.name} (${selectedTier.priceDisplay})',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
