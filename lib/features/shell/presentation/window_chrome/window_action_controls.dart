import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/core/widgets/custom_chrome_icons.dart';
import 'window_control_buttons.dart';

/// Right-side actions:
/// [LeftSidebarIcon] [RightSidebarIcon] [MenuGripIcon]
class WindowActionControls extends StatelessWidget {
  final bool isLeftSidebarOpen;
  final bool isRightSidebarOpen;
  final bool isFullscreen;
  final VoidCallback onToggleLeftSidebar;
  final VoidCallback onToggleRightSidebar;
  final VoidCallback onToggleFullscreen;
  final VoidCallback? onToggleZenMode;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenVault;
  final VoidCallback? onCreateVault;
  final VoidCallback? onOpenSampleVault;
  final VoidCallback? onRefreshFolder;
  final VoidCallback? onCopyTaggedRoll;
  final VoidCallback? onExportTaggedRoll;
  final VoidCallback? onShowShortcuts;
  final VoidCallback? onCloseVault;
  final bool isEditMode;

  const WindowActionControls({
    super.key,
    required this.isLeftSidebarOpen,
    required this.isRightSidebarOpen,
    required this.isFullscreen,
    required this.onToggleLeftSidebar,
    required this.onToggleRightSidebar,
    required this.onToggleFullscreen,
    this.onToggleZenMode,
    this.onOpenSettings,
    this.onOpenVault,
    this.onCreateVault,
    this.onOpenSampleVault,
    this.onRefreshFolder,
    this.onCopyTaggedRoll,
    this.onExportTaggedRoll,
    this.onShowShortcuts,
    this.onCloseVault,
    this.isEditMode = false,
  });

  void _showVaultMenu(BuildContext context, TapDownDetails details) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(
        details.globalPosition.dx,
        details.globalPosition.dy + 12,
        0,
        0,
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: AppColors.cardBackground,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'open_vault',
          height: 38,
          child: Row(
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 15,
                color: AppColors.accentCyan,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Open Vault Folder...',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Ctrl+O',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'create_vault',
          height: 38,
          child: Row(
            children: [
              Icon(Icons.add_box_outlined, size: 15, color: Color(0xFF4EDEA3)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Create New Vault...',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Ctrl+N',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        if (onOpenSampleVault != null)
          const PopupMenuItem<String>(
            value: 'open_sample',
            height: 38,
            child: Row(
              children: [
                Icon(
                  Icons.rocket_launch_outlined,
                  size: 15,
                  color: AppColors.accentOrange,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Try Sample Vault',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const PopupMenuItem<String>(
          value: 'refresh',
          height: 38,
          child: Row(
            children: [
              Icon(Icons.refresh, size: 15, color: AppColors.textSecondary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Refresh Current View',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isEditMode) ...[
          const PopupMenuDivider(height: 8),
          const PopupMenuItem<String>(
            value: 'copy_roll',
            height: 38,
            child: Row(
              children: [
                Icon(Icons.copy, size: 15, color: AppColors.textSecondary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Copy Markdown to Clipboard',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'export_roll',
            height: 38,
            child: Row(
              children: [
                Icon(
                  Icons.save_as_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Export View as Dedicated Note',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const PopupMenuDivider(height: 8),
        const PopupMenuItem<String>(
          value: 'shortcuts',
          height: 38,
          child: Row(
            children: [
              Icon(
                Icons.keyboard_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Keyboard Shortcuts',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Ctrl+/',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        if (onCloseVault != null) ...[
          const PopupMenuDivider(height: 8),
          const PopupMenuItem<String>(
            value: 'close_vault',
            height: 38,
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 15, color: Color(0xFFEF4444)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Close Vault',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFFEF4444)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ).then((selected) {
      if (selected == null) return;
      switch (selected) {
        case 'open_vault':
          onOpenVault?.call();
          break;
        case 'create_vault':
          onCreateVault?.call();
          break;
        case 'open_sample':
          onOpenSampleVault?.call();
          break;
        case 'refresh':
          onRefreshFolder?.call();
          break;
        case 'copy_roll':
          onCopyTaggedRoll?.call();
          break;
        case 'export_roll':
          onExportTaggedRoll?.call();
          break;
        case 'shortcuts':
          onShowShortcuts?.call();
          break;
        case 'close_vault':
          onCloseVault?.call();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Left Sidebar toggle button
        ChromeActionButton(
          tooltip: isLeftSidebarOpen
              ? 'Hide Sidebar (Ctrl+B / ⌘B)'
              : 'Show Sidebar (Ctrl+B / ⌘B)',
          onTap: onToggleLeftSidebar,
          child: LeftSidebarIcon(
            color: isLeftSidebarOpen
                ? AppColors.actionIconActive
                : AppColors.actionIcon,
            isActive: isLeftSidebarOpen,
          ),
        ),

        // 2. Right Sidebar / Inspector toggle button
        ChromeActionButton(
          tooltip: isRightSidebarOpen
              ? 'Hide Inspector / Outline (Ctrl+J / ⌘J)'
              : 'Show Inspector / Outline (Ctrl+J / ⌘J)',
          onTap: onToggleRightSidebar,
          child: RightSidebarIcon(
            color: isRightSidebarOpen
                ? AppColors.actionIconActive
                : AppColors.actionIcon,
            isFilled: isRightSidebarOpen,
          ),
        ),

        // 3. Menu grip / Window options button
        ChromeActionButton(
          tooltip: 'Menu & Vault Options',
          onTapDown: (details) => _showVaultMenu(context, details),
          child: const MenuGripIcon(color: AppColors.actionIcon),
        ),

        // 4. Window Control Buttons (Minimize, Maximize, Close)
        const WindowControlButtons(),
      ],
    );
  }
}
