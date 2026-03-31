import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/core/platform/app_platform.dart';

class HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const HeaderActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppPlatform.isMobile;
    final size = isMobile ? 36.0 : 26.0;
    final iconSize = isMobile ? 18.0 : 14.0;
    final splash = isMobile ? 18.0 : 13.0;

    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        splashRadius: splash,
        color: AppColors.textMuted,
      ),
    );
  }
}
