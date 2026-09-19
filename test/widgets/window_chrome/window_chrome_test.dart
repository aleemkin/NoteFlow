import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/core/constants/view_mode.dart';
import 'package:noteflow/features/shell/presentation/window_chrome/app_icon_widget.dart';
import 'package:noteflow/core/widgets/custom_chrome_icons.dart';
import 'package:noteflow/features/shell/presentation/window_chrome/search_bar_button.dart';
import 'package:noteflow/features/shell/presentation/window_chrome/view_mode_toggle.dart';
import 'package:noteflow/features/shell/presentation/window_chrome/window_chrome.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'WindowChrome renders logo, name, slash, folder icon, and vault name',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      ViewMode currentMode = ViewMode.reading;
      bool searchTapped = false;
      bool leftSidebarToggled = false;
      bool rightSidebarToggled = false;
      bool vaultTapped = false;
      bool openVaultCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WindowChrome(
              viewMode: currentMode,
              onViewModeChanged: (mode) => currentMode = mode,
              vaultName: 'my_research_vault',
              onVaultTap: () => vaultTapped = true,
              onSearchTapped: () => searchTapped = true,
              isLeftSidebarOpen: true,
              isRightSidebarOpen: false,
              isFullscreen: false,
              onToggleLeftSidebar: () => leftSidebarToggled = true,
              onToggleRightSidebar: () => rightSidebarToggled = true,
              onToggleFullscreen: () {},
              onOpenVault: () => openVaultCalled = true,
            ),
          ),
        ),
      );

      // 1. Logo > name > / > folder icon > vault name text
      expect(find.byType(AppIconWidget), findsOneWidget);
      expect(find.text('Noteflow'), findsOneWidget);
      expect(find.text('/'), findsOneWidget);
      expect(find.text('my_research_vault'), findsOneWidget);

      // Tap vault name
      await tester.tap(find.text('my_research_vault'));
      expect(vaultTapped, isTrue);

      // 2. Reading/Editor toggle is present without selection/filter menu
      expect(find.byType(ViewModeToggle), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('Editor'), findsOneWidget);
      expect(find.text('All Notes'), findsNothing);
      expect(find.text('Important Highlights'), findsNothing);

      // 3. No create note button in title bar
      expect(find.byIcon(Icons.add_circle_outline), findsNothing);
      expect(find.text('New Markdown Note'), findsNothing);

      // 4. Search bar button
      expect(find.byType(SearchBarButton), findsOneWidget);
      expect(find.text('Search...'), findsOneWidget);
      await tester.tap(find.byType(SearchBarButton));
      expect(searchTapped, isTrue);

      // 5. Synced action buttons: Left, Right, Code Menu (Menu & Vault options), Min, Max, Close
      expect(find.byType(LeftSidebarIcon), findsOneWidget);
      expect(find.byType(RightSidebarIcon), findsOneWidget);
      expect(find.byType(MenuGripIcon), findsOneWidget);

      await tester.tap(find.byType(LeftSidebarIcon));
      expect(leftSidebarToggled, isTrue);

      await tester.tap(find.byType(RightSidebarIcon));
      expect(rightSidebarToggled, isTrue);

      // Open Menu & Vault options via code_menu icon
      await tester.tap(find.byType(MenuGripIcon));
      await tester.pumpAndSettle();

      expect(find.text('Open Vault Folder...'), findsOneWidget);
      expect(find.text('Refresh Current View'), findsOneWidget);
      expect(find.text('Keyboard Shortcuts'), findsOneWidget);

      // Tap Open Vault
      await tester.tap(find.text('Open Vault Folder...'));
      await tester.pumpAndSettle();
      expect(openVaultCalled, isTrue);
    },
  );
}
