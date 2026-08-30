import 'package:flutter/material.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';

/// Touch-first bottom navigation bar for mobile devices.
class MobileBottomNavBar extends StatelessWidget {
  const MobileBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF21262D))),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 52.0,
          backgroundColor: const Color(0xFF0B0F15),
          indicatorColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 10.5,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: Color(0xFF0C6FFF),
                letterSpacing: 0.2,
              );
            }
            return const TextStyle(
              fontSize: 10.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
              color: Color(0xFFDFE2EB),
              letterSpacing: 0.2,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: const Color(0xFF0B0F15),
          elevation: 0,
          height: 52.0,
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: AppSvgIcon.notes(size: 20),
              selectedIcon: AppSvgIcon.notesSelected(size: 20),
              label: 'Notes',
            ),
            NavigationDestination(
              icon: AppSvgIcon.editor(size: 20),
              selectedIcon: AppSvgIcon.editorSelected(size: 20),
              label: 'Editor',
            ),
            NavigationDestination(
              icon: AppSvgIcon.canvas(size: 20),
              selectedIcon: AppSvgIcon.canvasSelected(size: 20),
              label: 'Canvas',
            ),
            NavigationDestination(
              icon: AppSvgIcon.vault(size: 20),
              selectedIcon: AppSvgIcon.vaultSelected(size: 20),
              label: 'Vault',
            ),
          ],
        ),
      ),
    );
  }
}
