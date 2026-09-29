import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';

/// Section allowing users to support NoteFlow without spending money
/// by voluntarily watching an opt-in sponsored video ad.
class SupportAdSection extends StatelessWidget {
  final bool isLoadingAd;
  final VoidCallback onWatchAd;
  final Color accentColor;

  const SupportAdSection({
    super.key,
    required this.isLoadingAd,
    required this.onWatchAd,
    this.accentColor = const Color(0xFF58A6FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131720),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232A36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  Icons.smart_display_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Contribute for Free',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDFE2EB),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x283FB950),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '100% Free',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3FB950),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Watch a short 30-second sponsored video',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Don\'t have spare change? You can support NoteFlow without spending a penny. '
            'NoteFlow never shows banner ads or popups in your notes—ads are only played right here on demand.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoadingAd ? null : onWatchAd,
              icon: isLoadingAd
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentColor,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                isLoadingAd
                    ? 'Loading Sponsor Ad...'
                    : 'Watch Sponsor Ad (~30s)',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(
                  color: accentColor.withValues(alpha: 0.65),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
