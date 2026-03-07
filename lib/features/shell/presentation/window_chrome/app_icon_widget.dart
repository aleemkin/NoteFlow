import 'package:flutter/material.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';

/// The 32x32 noteflow app icon badge widget.
class AppIconWidget extends StatelessWidget {
  final double size;

  const AppIconWidget({super.key, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return AppSvgIcon.appIcon(size: size);
  }
}
