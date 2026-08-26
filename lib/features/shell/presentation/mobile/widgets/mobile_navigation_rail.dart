import 'package:flutter/material.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';

/// Tablet landscape navigation rail.
class MobileNavigationRail extends StatelessWidget {
  const MobileNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: const Color(0xFF0B0F15),
      labelType: NavigationRailLabelType.all,
      indicatorColor: Colors.transparent,
      selectedLabelTextStyle: const TextStyle(
        fontSize: 10.5,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
        color: Color(0xFF0C6FFF),
        letterSpacing: 0.2,
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontSize: 10.5,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w500,
        color: Color(0xFFDFE2EB),
        letterSpacing: 0.2,
      ),
      destinations: const [
        NavigationRailDestination(
          padding: EdgeInsets.all(2),
          icon: AppSvgIcon.notes(size: 20),
          selectedIcon: AppSvgIcon.notesSelected(size: 20),
          label: Text('Notes'),
        ),
        NavigationRailDestination(
          padding: EdgeInsets.all(2),
          icon: AppSvgIcon.editor(size: 20),
          selectedIcon: AppSvgIcon.editorSelected(size: 20),
          label: Text('Editor'),
        ),
        NavigationRailDestination(
          padding: EdgeInsets.all(2),
          icon: AppSvgIcon.canvas(size: 20),
          selectedIcon: AppSvgIcon.canvasSelected(size: 20),
          label: Text('Canvas'),
        ),
        NavigationRailDestination(
          padding: EdgeInsets.all(2),
          icon: AppSvgIcon.vault(size: 20),
          selectedIcon: AppSvgIcon.vaultSelected(size: 20),
          label: Text('Vault'),
        ),
      ],
    );
  }
}
