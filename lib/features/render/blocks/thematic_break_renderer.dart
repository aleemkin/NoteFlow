import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';

/// Renders a horizontal divider / thematic break (`---`).
class ThematicBreakRenderer extends StatelessWidget {
  const ThematicBreakRenderer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
    );
  }
}
