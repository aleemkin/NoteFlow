import 'package:flutter/material.dart';

/// Individual action card on the welcome screen.
class WelcomeActionCard extends StatefulWidget {
  final bool isHighlighted;
  final IconData icon;
  final Color iconColor;
  final String badgeText;
  final String title;
  final String description;
  final Widget button;
  final VoidCallback? onTap;

  const WelcomeActionCard({
    super.key,
    required this.isHighlighted,
    required this.icon,
    required this.iconColor,
    required this.badgeText,
    required this.title,
    required this.description,
    required this.button,
    this.onTap,
  });

  @override
  State<WelcomeActionCard> createState() => _WelcomeActionCardState();
}

class _WelcomeActionCardState extends State<WelcomeActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isHighlighted
        ? const Color(0xFF1C2026)
        : const Color(0xFF181C22);
    final borderColor = widget.isHighlighted
        ? const Color(0x33ADC6FF)
        : (_isHovered ? const Color(0x33FFFFFF) : Colors.transparent);

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              if (widget.isHighlighted || _isHovered)
                const BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Icon + Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(widget.icon, size: 22, color: widget.iconColor),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF31353C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.badgeText,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                            color: Color(0xFF8C909F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDFE2EB),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFC2C6D6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Button
              SizedBox(width: double.infinity, child: widget.button),
            ],
          ),
        ),
      ),
    );
  }
}
