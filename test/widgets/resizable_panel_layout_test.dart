import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/shell/presentation/home_screen.dart';
import 'package:noteflow/features/editor/presentation/outline/outline_inspector_panel.dart';
import 'package:noteflow/core/widgets/resizable_panel_layout.dart';
import 'package:noteflow/features/vault/presentation/widgets/vault_tree_widget.dart';
import 'package:noteflow/features/vault/vault.dart';

void main() {
  group('ResizablePanelLayout & HomeScreen Layout Shortcuts', () {
    testWidgets(
      'ResizablePanelLayout: center panel takes full space when leftPanel is null',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. When leftPanel is null, center panel takes full 800 width
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizablePanelLayout(
                centerPanel: SizedBox.expand(key: Key('center_panel')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final centerSizeNoLeft = tester.getSize(
          find.byKey(const Key('center_panel')),
        );
        expect(centerSizeNoLeft.width, 800.0);

        // 2. When leftPanel is provided (width=200), center panel takes remaining width (800 - 200 - dividerWidth = 596)
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizablePanelLayout(
                leftPanel: SizedBox(key: Key('left_panel')),
                initialLeftWidth: 200,
                minLeftWidth: 100,
                centerPanel: SizedBox.expand(key: Key('center_panel')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final leftSize = tester.getSize(find.byKey(const Key('left_panel')));
        expect(leftSize.width, 200.0);
        final centerSizeWithLeft = tester.getSize(
          find.byKey(const Key('center_panel')),
        );
        expect(centerSizeWithLeft.width, 596.0);
      },
    );

    testWidgets(
      'HomeScreen handles Ctrl+J to toggle right panel and Ctrl+B to toggle left panel',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fs = MemoryVaultFileSystem();
        fs.seed('note.md', '# Note\nSome content.');
        final treeRepo = VaultTreeRepository();
        final manager = VaultManager(treeRepository: treeRepo);
        await manager.openCustomFileSystem(fs, 'Test Vault');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              vaultTreeRepositoryProvider.overrideWith((ref) => treeRepo),
              vaultManagerProvider.overrideWith((ref) => manager),
              currentVaultProvider.overrideWith((ref) => manager.currentVault),
            ],
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Initially, left panel (VaultTreeWidget) is open
        expect(find.byType(VaultTreeWidget), findsOneWidget);

        // Press Ctrl+B to toggle left panel closed
        await tester.sendKeyEvent(LogicalKeyboardKey.keyB, platform: 'linux');
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        // Left panel is closed
        expect(find.byType(VaultTreeWidget), findsNothing);

        // Press Ctrl+J to toggle right panel
        final initialRightOpen = find
            .byType(OutlineInspectorPanel)
            .evaluate()
            .isNotEmpty;
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        // Right panel state must have flipped
        final afterCtrlJOpen = find
            .byType(OutlineInspectorPanel)
            .evaluate()
            .isNotEmpty;
        expect(afterCtrlJOpen, !initialRightOpen);
      },
    );
  });
}
