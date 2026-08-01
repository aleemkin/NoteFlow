import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';

/// Quick search bar button matching the [🔍 Search... ⌘K] component in the header.
class SearchBarButton extends StatefulWidget {
  final VoidCallback onTap;
  final String shortcutText;

  const SearchBarButton({
    super.key,
    required this.onTap,
    this.shortcutText = '⌘K',
  });

  @override
  State<SearchBarButton> createState() => _SearchBarButtonState();
}

class _SearchBarButtonState extends State<SearchBarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Quick search & commands (${widget.shortcutText} / Ctrl+K)',
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 148,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppColors.controlHover
                  : AppColors.controlBackground.withAlpha(150),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isHovered
                    ? AppColors.activeSegmentBorder
                    : AppColors.controlBorder.withAlpha(150),
              ),
            ),
            child: Row(
              children: [
                // Search icon
                Icon(
                  Icons.search_rounded,
                  size: 15,
                  color: _isHovered
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),

                const SizedBox(width: 7),

                // Hint text: "Search..."
                Expanded(
                  child: Text(
                    'Search...',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                      color: _isHovered
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Shortcut key badge: ⌘K
                const Text(
                  "⌘",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    textBaseline: TextBaseline.ideographic,
                    fontWeight: FontWeight.w600,
                    color: AppColors.badgeText,
                  ),
                ),
                const Text(
                  "K",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    textBaseline: TextBaseline.ideographic,
                    fontWeight: FontWeight.w600,
                    color: AppColors.badgeText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
