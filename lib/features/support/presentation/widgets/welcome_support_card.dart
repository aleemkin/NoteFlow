import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';

/// Sleek "Buy me a coffee" prompt card displayed on the Welcome screen.
///
/// Positioned directly beneath the Recent Workspaces list and above the
/// Legal / Privacy Policy footer on touch devices.
class WelcomeSupportCard extends StatefulWidget {
  final VoidCallback onTap;

  const WelcomeSupportCard({super.key, required this.onTap});

  @override
  State<WelcomeSupportCard> createState() => _WelcomeSupportCardState();
}

class _WelcomeSupportCardState extends State<WelcomeSupportCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const accentAmber = Color(0xFFF59E0B);
    const borderAmber = Color(0x3DF59E0B);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: accentAmber.withValues(alpha: 0.12),
          highlightColor: accentAmber.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _isHovered
                  ? const Color(0xFF1B202A)
                  : const Color(0xFF141820),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isHovered
                    ? accentAmber.withValues(alpha: 0.45)
                    : borderAmber,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? accentAmber.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.25),
                  blurRadius: _isHovered ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                AppSvgIcon.longCoffee(
                  size: 32,
                  color: accentAmber,
                  fit: BoxFit.fitHeight,
                ),
                const SizedBox(width: 14),

                // Text labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Buy me a coffee',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: accentAmber.withValues(alpha: 0.6),
                                letterSpacing: -0.2,
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
                              color: const Color(0x28F59E0B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Support',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: accentAmber,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Contribute with a tip or support for free by watching an ad',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Trailing sleek chevron pill
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: accentAmber.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
