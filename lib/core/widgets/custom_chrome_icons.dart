import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';

/// Left Sidebar Icon widget
class LeftSidebarIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool isActive;

  const LeftSidebarIcon({
    super.key,
    this.size = 18,
    this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppSvgIcon(
      assetPath: isActive
          ? AppSvgIcons.leftPanelOpen
          : AppSvgIcons.leftPanelClosed,
      size: size,
      color: color ?? AppColors.actionIcon,
    );
  }
}

/// Right Sidebar Icon widget (solid right pane matching open state)
class RightSidebarIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool isFilled;

  const RightSidebarIcon({
    super.key,
    this.size = 18,
    this.color,
    this.isFilled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppSvgIcon(
      assetPath: isFilled
          ? AppSvgIcons.rightPanelOpen
          : AppSvgIcons.rightPanelClosed,
      size: size,
      color: color ?? AppColors.actionIcon,
    );
  }
}

/// 6-dots grip icon widget
class MenuGripIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const MenuGripIcon({super.key, this.size = 18, this.color});

  @override
  Widget build(BuildContext context) {
    return AppSvgIcon.codeMenu(
      size: size,
      color: color ?? AppColors.actionIcon,
    );
  }
}
