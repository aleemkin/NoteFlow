import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact floating quick-action toolbar that appears right above text selection.
///
/// Designed to be lightweight and sleek (matching Figma/mockup), offering single-row
/// access to Draw, IMP, INFO, Tag, View, Untag, Copy, and Dismiss.
class FloatingSelectionToolbar extends StatelessWidget {
  final String selectedText;
  final double? maxWidth;
  final VoidCallback onInsertDiagramAbove;
  final VoidCallback onInsertDiagramBelow;
  final VoidCallback onTagImportant;
  final VoidCallback onTagInfo;
  final VoidCallback onCustomTag;
  final VoidCallback onCopy;
  final VoidCallback onViewTag;
  final VoidCallback onUntag;
  final VoidCallback onDismiss;

  const FloatingSelectionToolbar({
    super.key,
    required this.selectedText,
    this.maxWidth,
    required this.onInsertDiagramAbove,
    required this.onInsertDiagramBelow,
    required this.onTagImportant,
    required this.onTagInfo,
    required this.onCustomTag,
    required this.onCopy,
    required this.onViewTag,
    required this.onUntag,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 36,
        constraints: maxWidth != null
            ? BoxConstraints(maxWidth: maxWidth!)
            : null,
        decoration: BoxDecoration(
          color: const Color(0xFF1E232B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF30363D)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPillAction(
                icon: Icons.add,
                iconColor: const Color(0xFF34D399),
                label: 'Draw',
                labelColor: const Color(0xFF34D399),
                tooltip: 'Insert diagram below',
                onPressed: onInsertDiagramBelow,
              ),
              _buildPillAction(
                icon: Icons.north_rounded,
                iconColor: const Color(0xFF34D399),
                label: 'Above',
                labelColor: const Color(0xFF34D399),
                tooltip: 'Insert diagram above',
                onPressed: onInsertDiagramAbove,
              ),
              _buildPillAction(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFF59E0B),
                label: 'IMP',
                labelColor: const Color(0xFFF59E0B),
                tooltip: 'Tag as Important (@@imp)',
                onPressed: onTagImportant,
              ),
              _buildPillAction(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF38BDF8),
                label: 'INFO',
                labelColor: const Color(0xFF38BDF8),
                tooltip: 'Tag as Info Reference (@@info)',
                onPressed: onTagInfo,
              ),
              _buildPillAction(
                icon: Icons.local_offer_outlined,
                iconColor: const Color(0xFF94A3B8),
                label: 'Tag',
                labelColor: const Color(0xFFDFE2EB),
                tooltip: 'Apply custom tag',
                onPressed: onCustomTag,
              ),
              _buildPillAction(
                icon: Icons.visibility_outlined,
                iconColor: const Color(0xFF94A3B8),
                label: 'View',
                labelColor: const Color(0xFFDFE2EB),
                tooltip: 'Copy @@view directive',
                onPressed: onViewTag,
              ),
              _buildPillAction(
                icon: Icons.label_off_outlined,
                iconColor: const Color(0xFFEF4444),
                label: 'Untag',
                labelColor: const Color(0xFFEF4444),
                tooltip: 'Remove tag directive',
                onPressed: onUntag,
              ),
              Container(
                width: 1,
                height: 16,
                color: const Color(0xFF30363D),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              IconButton(
                visualDensity: .compact,
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 15,
                  color: Color(0xFFDFE2EB),
                ),
                tooltip: 'Copy',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                splashRadius: 14,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onCopy();
                },
              ),
              IconButton(
                visualDensity: .compact,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: Color(0xFF8B949E),
                ),
                tooltip: 'Dismiss',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                splashRadius: 14,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onDismiss();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillAction({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: labelColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
