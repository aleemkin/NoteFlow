import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';
import 'package:noteflow/features/shell/presentation/window_chrome/window_action_controls.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSvgIcon', () {
    testWidgets('renders SvgPicture with specified asset and dimensions', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppSvgIcon(
              assetPath: AppSvgIcons.folder,
              size: 24,
              color: Colors.blue,
            ),
          ),
        ),
      );

      final svgFinder = find.byType(SvgPicture);
      expect(svgFinder, findsOneWidget);

      final SvgPicture svgWidget = tester.widget<SvgPicture>(svgFinder);
      expect(svgWidget.width, 24);
      expect(svgWidget.height, 24);
    });

    testWidgets('named constructors provide appropriate asset paths', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppSvgIcon.appIcon(size: 32),
                AppSvgIcon.folder(size: 16),
                AppSvgIcon.notes(size: 18),
                AppSvgIcon.canvas(size: 18),
                AppSvgIcon.rightPanelOpen(size: 18),
                AppSvgIcon.rightPanelClosed(size: 18),
                AppSvgIcon.codeMenu(size: 18),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AppSvgIcon), findsNWidgets(7));
      expect(find.byType(SvgPicture), findsNWidgets(7));
    });
  });

  group('WindowActionControls SVG Icons', () {
    testWidgets(
      'renders left and right panel icons reflecting sidebar states',
      (tester) async {
        bool leftOpen = true;
        bool rightOpen = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return WindowActionControls(
                    isLeftSidebarOpen: leftOpen,
                    isRightSidebarOpen: rightOpen,
                    isFullscreen: false,
                    onToggleLeftSidebar: () {
                      setState(() => leftOpen = !leftOpen);
                    },
                    onToggleRightSidebar: () {
                      setState(() => rightOpen = !rightOpen);
                    },
                    onToggleFullscreen: () {},
                  );
                },
              ),
            ),
          ),
        );

        // Verify that AppSvgIcon widgets are present for the 3 action controls
        expect(find.byType(AppSvgIcon), findsNWidgets(3));

        // Tap to toggle left sidebar closed
        await tester.tap(find.byTooltip('Hide Sidebar (Ctrl+B / ⌘B)'));
        await tester.pumpAndSettle();
        expect(leftOpen, isFalse);

        // Tap to toggle right sidebar open
        await tester.tap(
          find.byTooltip('Show Inspector / Outline (Ctrl+J / ⌘J)'),
        );
        await tester.pumpAndSettle();
        expect(rightOpen, isTrue);
      },
    );
  });
}
