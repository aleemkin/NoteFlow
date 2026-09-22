import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/editor/presentation/widgets/dual_pane_editor.dart';
import 'package:noteflow/features/vault/vault.dart';

void main() {
  group('DualPaneEditor Tests', () {
    testWidgets(
      'DualPaneEditor renders rich formatting toolbar, always split layout, and auto-saves',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 800));
        tester.view.physicalSize = const Size(1400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fs = MemoryVaultFileSystem();
        fs.seed('test_note.md', '# Hello World\nSome sample content.');
        final treeRepo = VaultTreeRepository();
        final manager = VaultManager(treeRepository: treeRepo);
        await manager.openCustomFileSystem(fs, 'Test Vault');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              vaultTreeRepositoryProvider.overrideWith((ref) => treeRepo),
              vaultManagerProvider.overrideWith((ref) => manager),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 1400,
                    height: 800,
                    child: DualPaneEditor(documentPath: 'test_note.md'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify document loaded and always split layout is active
        expect(find.text('Hello World'), findsWidgets);
        expect(find.text('RAW MARKDOWN & DIRECTIVES'), findsOneWidget);
        expect(find.text('LIVE SYNCHRONIZED PREVIEW'), findsOneWidget);
        expect(find.text('Auto-saved'), findsOneWidget);

        // Verify format buttons exist
        expect(find.byTooltip('Heading 1 (#)'), findsOneWidget);
        expect(find.byTooltip('Bold (Ctrl+B)'), findsOneWidget);
        expect(find.byTooltip('Italic (Ctrl+I)'), findsOneWidget);
        expect(find.byTooltip('Strikethrough (~~)'), findsOneWidget);
        expect(find.byTooltip('Inline Code (`)'), findsOneWidget);
        expect(find.byTooltip('Insert Table'), findsOneWidget);
        expect(find.byTooltip('Tag Section (@@tag)'), findsOneWidget);
        expect(
          find.byTooltip('Important Block (@@imp) (Ctrl+Shift+H)'),
          findsOneWidget,
        );
        expect(
          find.byTooltip('Info Reference (@@info) (Ctrl+Shift+I)'),
          findsOneWidget,
        );
        expect(
          find.byTooltip('To-Do Task (@@todo) (Ctrl+Shift+T)'),
          findsOneWidget,
        );
        expect(
          find.byTooltip('Review Block (@@review) (Ctrl+Shift+R)'),
          findsOneWidget,
        );

        // Tap Important Block button to verify zero-modal template insertion
        await tester.tap(
          find.byTooltip('Important Block (@@imp) (Ctrl+Shift+H)'),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('@@imp'), findsWidgets);
        expect(find.textContaining('@@/imp'), findsWidgets);

        // Pump to trigger auto-save debounce (600ms)
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(find.text('Auto-saved'), findsOneWidget);
      },
    );

    testWidgets(
      'DualPaneEditor always renders split layout (Raw Editor + Live Preview) without view toggle buttons',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(750, 600));
        tester.view.physicalSize = const Size(750, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fs = MemoryVaultFileSystem();
        fs.seed('preset_note.md', '# Presets Note\nContent here.');
        final treeRepo = VaultTreeRepository();
        final manager = VaultManager(treeRepository: treeRepo);
        await manager.openCustomFileSystem(fs, 'Test Vault');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              vaultTreeRepositoryProvider.overrideWith((ref) => treeRepo),
              vaultManagerProvider.overrideWith((ref) => manager),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 750,
                    height: 600,
                    child: DualPaneEditor(documentPath: 'preset_note.md'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // At 750px width, formatting bar must be directly visible (NOT hidden behind popup)
        expect(find.byTooltip('Bold (Ctrl+B)'), findsOneWidget);
        expect(find.byTooltip('Heading 1 (#)'), findsOneWidget);
        expect(find.byTooltip('Heading 3 (###)'), findsOneWidget);
        expect(find.byTooltip('Insert Link (Ctrl+K)'), findsOneWidget);

        // Always in Split mode: both raw editor and preview pane are present simultaneously
        expect(find.text('RAW MARKDOWN & DIRECTIVES'), findsOneWidget);
        expect(find.text('LIVE SYNCHRONIZED PREVIEW'), findsOneWidget);

        // Verify EditorSegmentedButtons (toggle options) are removed
        expect(find.byTooltip('Split View (Raw + Live Preview)'), findsNothing);
        expect(find.byTooltip('Editor Only (Raw Markdown)'), findsNothing);
        expect(find.byTooltip('Live Preview Only'), findsNothing);
      },
    );

    testWidgets(
      'DualPaneEditor displays syntax warning on incomplete directive and auto-saves to disk',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 800));
        tester.view.physicalSize = const Size(1400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fs = MemoryVaultFileSystem();
        fs.seed('note2.md', '# Clean Note\n');
        final treeRepo = VaultTreeRepository();
        final manager = VaultManager(treeRepository: treeRepo);
        await manager.openCustomFileSystem(fs, 'Test Vault');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              vaultTreeRepositoryProvider.overrideWith((ref) => treeRepo),
              vaultManagerProvider.overrideWith((ref) => manager),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 1400,
                    height: 800,
                    child: DualPaneEditor(documentPath: 'note2.md'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter an incomplete directive
        await tester.enterText(
          find.byType(TextField),
          '# Clean Note\n\n@@imp\nUnclosed text',
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        // Verify syntax warning is displayed
        expect(
          find.textContaining('Incomplete directive: @@imp'),
          findsWidgets,
        );

        // Now close the directive properly
        await tester.enterText(
          find.byType(TextField),
          '# Clean Note\n\n@@imp\nUnclosed text\n@@/imp',
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        // Syntax warning is gone
        expect(find.textContaining('Incomplete directive'), findsNothing);

        // Trigger auto-save debounce (600ms)
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(find.text('Auto-saved'), findsOneWidget);

        // Verify content was actually saved to filesystem on disk
        final savedBytes = await fs.readBytes(const VaultUri(path: 'note2.md'));
        final savedText = utf8.decode(savedBytes);
        expect(savedText, contains('@@imp'));
        expect(savedText, contains('@@/imp'));
      },
    );
  });
}
