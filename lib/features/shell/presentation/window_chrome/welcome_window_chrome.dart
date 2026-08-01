import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'app_icon_widget.dart';
import 'window_chrome.dart';

/// Minimal window chrome displayed on the First / Welcome Screen (when no vault is active).
/// Provides frameless desktop window dragging, app branding, docs/github links,
/// settings gear icon, and window control buttons (Minimize, Maximize, Close).
class WelcomeWindowChrome extends StatelessWidget {
  const WelcomeWindowChrome({super.key});

  @override
  Widget build(BuildContext context) {
    const chromeHeight = 36.0;

    return Container(
      height: chromeHeight,
      decoration: const BoxDecoration(
        color: AppColors.chromeBackground,
        border: Border(bottom: BorderSide(color: AppColors.chromeBottomBorder)),
      ),
      padding: const EdgeInsets.only(left: 12.0, right: 16.0),
      child: Row(
        children: [
          const AppIconWidget(size: 24),
          const SizedBox(width: 8),
          const Text(
            'Noteflow',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const Expanded(child: SafeDragToMoveArea(child: SizedBox.expand())),
          _HeaderLink(label: 'Docs', onTap: () {}),
          const SizedBox(width: 12),
          _HeaderLink(label: 'GitHub', onTap: () {}),
          const SizedBox(width: 12),
          Container(height: 14, width: 1, color: AppColors.borderDefault),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              size: 16,
              color: AppColors.textTertiary,
            ),
            tooltip: 'Settings',
            splashRadius: 14,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            onPressed: () {
              // Action reserved for future settings dialog
            },
          ),
          const SizedBox(width: 8),
          const WindowControlButtons(),
        ],
      ),
    );
  }
}

class _HeaderLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
