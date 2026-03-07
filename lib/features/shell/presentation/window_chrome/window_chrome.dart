import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:noteflow/core/constants/view_mode.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'app_identity_section.dart';
import 'search_bar_button.dart';
import 'view_mode_toggle.dart';
import 'window_action_controls.dart';

export 'welcome_window_chrome.dart';
export 'window_control_buttons.dart';

/// Single unified WindowChrome widget that combines:
/// - Custom title bar consuming the native title bar height (56px)
/// - App identity & document breadcrumbs
/// - App state controls (Reading / Editor toggle, Search box)
/// - Window & layout action controls (Sidebars, Window Menu)
class WindowChrome extends StatelessWidget {
  final ViewMode viewMode;
  final ValueChanged<ViewMode> onViewModeChanged;
  final String? vaultName;
  final String currentFolder;
  final ValueChanged<String>? onFolderSelected;
  final VoidCallback? onVaultTap;
  final VoidCallback onSearchTapped;
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

  const WindowChrome({
    super.key,
    required this.viewMode,
    required this.onViewModeChanged,
    this.vaultName,
    this.currentFolder = 'personal_notes',
    this.onFolderSelected,
    this.onVaultTap,
    required this.onSearchTapped,
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

  @override
  Widget build(BuildContext context) {
    final chromeHeight = 36.0; // Fixed height for the custom title bar

    return Container(
      height: chromeHeight,
      decoration: const BoxDecoration(
        color: AppColors.chromeBackground,
        border: Border(bottom: BorderSide(color: AppColors.chromeBottomBorder)),
      ),
      padding: const EdgeInsets.only(left: 12.0, right: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 820;
          final isCompact = constraints.maxWidth < 680;

          return Row(
            children: [
              // 1. Left Section: [AppIcon] noteflow / [FolderIcon] vault_name
              AppIdentitySection(
                vaultName: vaultName,
                currentFolder: currentFolder,
                onFolderSelected: onFolderSelected,
                onVaultTap: onVaultTap,
                isCompact: isCompact,
              ),

              // Draggable Spacer between left section and center controls
              const Expanded(
                child: SafeDragToMoveArea(child: SizedBox.expand()),
              ),

              // 2. Center Section: [Reading | Editor] [Search... ⌘K]
              ViewModeToggle(
                currentMode: viewMode,
                onModeChanged: onViewModeChanged,
              ),
              const SizedBox(width: 12),

              if (!isNarrow)
                SearchBarButton(onTap: onSearchTapped)
              else
                _CompactSearchButton(onTap: onSearchTapped),

              // Draggable Spacer between center controls and right actions
              const Expanded(
                child: SafeDragToMoveArea(child: SizedBox.expand()),
              ),

              // 3. Right Section: [LeftSidebar] [RightSidebar] [MenuGrip] [Min/Max/Close]
              WindowActionControls(
                isLeftSidebarOpen: isLeftSidebarOpen,
                isRightSidebarOpen: isRightSidebarOpen,
                isFullscreen: isFullscreen,
                onToggleLeftSidebar: onToggleLeftSidebar,
                onToggleRightSidebar: onToggleRightSidebar,
                onToggleFullscreen: onToggleFullscreen,
                onToggleZenMode: onToggleZenMode,
                onOpenSettings: onOpenSettings,
                onOpenVault: onOpenVault,
                onCreateVault: onCreateVault,
                onOpenSampleVault: onOpenSampleVault,
                onRefreshFolder: onRefreshFolder,
                onCopyTaggedRoll: onCopyTaggedRoll,
                onExportTaggedRoll: onExportTaggedRoll,
                onShowShortcuts: onShowShortcuts,
                onCloseVault: onCloseVault,
                isEditMode: isEditMode,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Fallback compact search button for narrow screens
class _CompactSearchButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CompactSearchButton({required this.onTap});

  @override
  State<_CompactSearchButton> createState() => _CompactSearchButtonState();
}

class _CompactSearchButtonState extends State<_CompactSearchButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Quick search (⌘K / Ctrl+K)',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppColors.controlHover
                  : AppColors.controlBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isHovered
                    ? AppColors.activeSegmentBorder
                    : AppColors.controlBorder,
              ),
            ),
            child: Icon(
              Icons.search_rounded,
              size: 16,
              color: _isHovered
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Draggable area that enables dragging the desktop window across screen,
/// safely handling web/test environments.
class SafeDragToMoveArea extends StatelessWidget {
  final Widget child;

  const SafeDragToMoveArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) {
        try {
          windowManager.startDragging();
        } catch (_) {}
      },
      onDoubleTap: () async {
        try {
          final isMax = await windowManager.isMaximized();
          if (isMax) {
            await windowManager.unmaximize();
          } else {
            await windowManager.maximize();
          }
        } catch (_) {}
      },
      child: child,
    );
  }
}
