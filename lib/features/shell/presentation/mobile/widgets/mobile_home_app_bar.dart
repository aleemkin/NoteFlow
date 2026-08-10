import 'package:flutter/material.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';

/// Top AppBar for MobileHomeScreen with contextual title, search, and drawer toggles.
class MobileHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MobileHomeAppBar({
    super.key,
    required this.currentTabIndex,
    required this.openedNotePath,
    required this.openedDrawingPath,
    required this.onCloseNote,
    required this.onCloseDrawing,
    required this.onOpenDrawer,
    required this.onOpenEndDrawer,
    required this.onCloseEndDrawer,
    required this.isEndDrawerOpen,
    required this.onSearchTap,
  });

  final int currentTabIndex;
  final String? openedNotePath;
  final String? openedDrawingPath;
  final VoidCallback onCloseNote;
  final VoidCallback onCloseDrawing;
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenEndDrawer;
  final VoidCallback onCloseEndDrawer;
  final bool isEndDrawerOpen;
  final VoidCallback onSearchTap;

  @override
  Size get preferredSize => const Size.fromHeight(44.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 44.0,
      backgroundColor: const Color(0xFF0B0F15),
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 14,
      title: _buildTitle(),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Color(0xFFDFE2EB),
          ),
          tooltip: 'Search notes and drawings',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          splashRadius: 18,
          onPressed: onSearchTap,
        ),
        if (currentTabIndex != 2)
          IconButton(
            icon: isEndDrawerOpen
                ? const AppSvgIcon.rightPanelOpen(
                    color: Color(0xFFDFE2EB),
                    size: 18,
                  )
                : const AppSvgIcon.rightPanelClosed(
                    color: Color(0xFFDFE2EB),
                    size: 18,
                  ),
            tooltip: 'Outline & Structure',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            splashRadius: 18,
            onPressed: () {
              if (isEndDrawerOpen) {
                onCloseEndDrawer();
              } else {
                onOpenEndDrawer();
              }
            },
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTitle() {
    if (currentTabIndex == 1 && openedNotePath != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: Color(0xFFDFE2EB),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Back to notes',
            onPressed: onCloseNote,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              openedNotePath!.contains('/')
                  ? openedNotePath!.split('/').last
                  : openedNotePath!,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: Color(0xFFDFE2EB),
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (currentTabIndex == 2 && openedDrawingPath != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: Color(0xFFDFE2EB),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Back to drawings',
            onPressed: onCloseDrawing,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              openedDrawingPath!.contains('/')
                  ? openedDrawingPath!.split('/').last
                  : openedDrawingPath!,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: Color(0xFFDFE2EB),
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onOpenDrawer,
      borderRadius: BorderRadius.circular(6),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon.folder(color: Color(0xFFDFE2EB), width: 18, height: 14),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Notebook Workspace',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDFE2EB),
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
