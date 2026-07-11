import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';

class ToolbarDivider extends StatelessWidget {
  const ToolbarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.borderSubtle,
    );
  }
}

class FormatButton extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final Color? iconColor;
  final String tooltip;
  final VoidCallback onTap;

  const FormatButton({
    super.key,
    this.icon,
    this.text,
    this.iconColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon != null
          ? Icon(icon, size: 14, color: iconColor)
          : Text(
              text ?? '',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: iconColor ?? AppColors.textMuted,
              ),
            ),
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        minimumSize: const Size(26, 26),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: iconColor ?? AppColors.textMuted,
      ),
      hoverColor: AppColors.surfaceHover,
      onPressed: onTap,
    );
  }
}
