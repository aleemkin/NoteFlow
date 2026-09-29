import 'dart:io';

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
            body: SingleChildScrollView(
              child: Column(
                children: [
                  AppSvgIcon.appIcon(size: 24),
                  AppSvgIcon.folder(size: 24),
                  AppSvgIcon.openFolder(size: 24),
                  AppSvgIcon.newFolder(size: 24),
                  AppSvgIcon.leftPanelOpen(size: 24),
                  AppSvgIcon.leftPanelClosed(size: 24),
                  AppSvgIcon.rightPanelOpen(size: 24),
                  AppSvgIcon.rightPanelClosed(size: 24),
                  AppSvgIcon.codeMenu(size: 24),
                  AppSvgIcon.readingToggle(size: 24),
                  AppSvgIcon.editorToggle(size: 24),
                  AppSvgIcon.notes(size: 24),
                  AppSvgIcon.notesSelected(size: 24),
                  AppSvgIcon.editor(size: 24),
                  AppSvgIcon.editorSelected(size: 24),
                  AppSvgIcon.canvas(size: 24),
                  AppSvgIcon.canvasSelected(size: 24),
                  AppSvgIcon.vault(size: 24),
                  AppSvgIcon.vaultSelected(size: 24),
                  AppSvgIcon.openBook(size: 24),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AppSvgIcon), findsNWidgets(20));
      expect(find.byType(SvgPicture), findsNWidgets(20));
    });

    test('all SVG asset files have synchronized 24x24 dimensions and viewBox', () {
      final assets = [
        AppSvgIcons.appIcon,
        AppSvgIcons.folder,
        AppSvgIcons.leftPanelClosed,
        AppSvgIcons.leftPanelOpen,
        AppSvgIcons.rightPanelClosed,
        AppSvgIcons.rightPanelOpen,
        AppSvgIcons.codeMenu,
        AppSvgIcons.readingToggle,
        AppSvgIcons.editorToggle,
        AppSvgIcons.notes,
        AppSvgIcons.notesSelected,
        AppSvgIcons.openFolder,
        AppSvgIcons.newFolder,
        AppSvgIcons.editor,
        AppSvgIcons.editorSelected,
        AppSvgIcons.canvas,
        AppSvgIcons.canvasSelected,
        AppSvgIcons.vault,
        AppSvgIcons.vaultSelected,
        AppSvgIcons.openBook,
      ];

      expect(assets.length, 20);

      for (final asset in assets) {
        final file = File(asset);
        expect(file.existsSync(), isTrue, reason: 'File $asset should exist');

        final content = file.readAsStringSync();
        expect(
          content,
          contains('viewBox="0 0 24 24"'),
          reason: '$asset must have viewBox="0 0 24 24"',
        );
        expect(
          content,
          contains('width="24"'),
          reason: '$asset must have width="24"',
        );
        expect(
          content,
          contains('height="24"'),
          reason: '$asset must have height="24"',
        );
      }
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
