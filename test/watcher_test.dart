import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/features/canvas/data/drawing_service.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/canvas/presentation/screens/drawing_editor_screen.dart';
import 'package:noteflow/features/shell/presentation/home_screen.dart';
import 'package:noteflow/features/editor/presentation/outline/outline_inspector_panel.dart';
import 'package:noteflow/features/vault/vault.dart';

void main() {
  test(
    'LocalPathVaultFileSystem watch detects external file modifications',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'vault_watcher_test_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final fs = LocalPathVaultFileSystem(rootPath: tempDir.path);
      final changes = <VaultChange>[];

      final sub = fs.watch(const VaultUri(path: '')).listen((batch) {
        changes.addAll(batch.changes);
      });
      addTearDown(() => sub.cancel());

      // Allow watcher to initialize
      await Future.delayed(const Duration(milliseconds: 200));

      // Create a file externally
      final file = File('${tempDir.path}/test.md');
      await file.writeAsString('# Initial Content');

      await Future.delayed(const Duration(milliseconds: 500));
      expect(changes.any((c) => c.uri.path == 'test.md'), isTrue);

      // Modify file externally
      await file.writeAsString('# Updated Content From Outside');
      await Future.delayed(const Duration(milliseconds: 500));

      expect(
        changes.any(
          (c) => c.uri.path == 'test.md' && c.type == VaultChangeType.modified,
        ),
        isTrue,
      );
    },
  );
  test(
    'VaultManager broadcasts external file change events via onFileChanges',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'vault_manager_watcher_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final treeRepo = VaultTreeRepository();
      final manager = VaultManager(treeRepository: treeRepo);
      await manager.openLocalVault(tempDir.path);
      addTearDown(() => manager.close());

      final receivedChanges = <VaultChange>[];
      final sub = manager.onFileChanges.listen((batch) {
        receivedChanges.addAll(batch.changes);
      });
      addTearDown(() => sub.cancel());

      await Future.delayed(const Duration(milliseconds: 200));

      // Create file externally
      final note = File('${tempDir.path}/external_note.md');
      await note.writeAsString('# External Note Content');

      await Future.delayed(const Duration(milliseconds: 600));

      expect(
        receivedChanges.any((c) => c.uri.path == 'external_note.md'),
        isTrue,
      );

      // Modify file externally
      await note.writeAsString('# Edited Content From External App');
      await Future.delayed(const Duration(milliseconds: 600));

      expect(
        receivedChanges.any(
          (c) =>
              c.uri.path == 'external_note.md' &&
              c.type == VaultChangeType.modified,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'HomeScreen in reading view updates content live when file is modified externally',
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
      fs.seed('note1.md', '# Original Title\nInitial body text.');
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
          child: const MaterialApp(home: Scaffold(body: HomeScreen())),
        ),
      );
      await tester.pumpAndSettle();

      // Select the root folder to load documents into reading view
      await tester.tap(find.text('note1.md'));
      await tester.pumpAndSettle();

      expect(find.text('Original Title'), findsWidgets);
      expect(find.text('Initial body text.'), findsWidgets);

      // Modify file externally via filesystem writeBytes
      await fs.writeBytes(
        const VaultUri(path: 'note1.md'),
        Uint8List.fromList(
          utf8.encode(
            '# Updated From Outside\nNew body text from external editor.',
          ),
        ),
        const NoPrecondition(),
      );

      // Advance timer for debounce (200ms)
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify Reading View has updated automatically with new text
      expect(find.text('Updated From Outside'), findsWidgets);
      expect(find.text('New body text from external editor.'), findsWidgets);
    },
  );

  testWidgets(
    'HomeScreen in reading view opens excalidraw files in editor view',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await DrawingService.instance.stop();
      });

      final fs = MemoryVaultFileSystem();
      fs.seed('note1.md', '# Note Title\nNote body text.');
      fs.seed('diagram.excalidraw', '{"type":"excalidraw","elements":[]}');
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
          child: const MaterialApp(home: Scaffold(body: HomeScreen())),
        ),
      );
      await tester.pumpAndSettle();

      // In Reading view, tap diagram.excalidraw in the left panel
      await tester.tap(find.text('diagram.excalidraw'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify it opened in editor view with DrawingEditorScreen
      expect(find.byType(DrawingEditorScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await DrawingService.instance.stop();
    },
  );

  testWidgets(
    'HomeScreen in edit view renders Document Outline in right panel',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fs = MemoryVaultFileSystem();
      fs.seed(
        'note1.md',
        '# Note Title\nNote body text.\n\n## Section A\nSection A details.',
      );
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
          child: const MaterialApp(home: Scaffold(body: HomeScreen())),
        ),
      );
      // Select note1.md from the file tree
      await tester.tap(find.text('note1.md'));
      await tester.pumpAndSettle();

      // Switch to edit mode using top bar toggle
      await tester.tap(find.text('Editor'));
      await tester.pumpAndSettle();

      // Verify OutlineInspectorPanel is present in right panel during edit view
      expect(find.byType(OutlineInspectorPanel), findsOneWidget);
      expect(find.text('Document Outline'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(OutlineInspectorPanel),
          matching: find.text('Section A'),
        ),
        findsOneWidget,
      );

      // Tap Section A in the outline
      await tester.tap(
        find.descendant(
          of: find.byType(OutlineInspectorPanel),
          matching: find.text('Section A'),
        ),
      );
      await tester.pumpAndSettle();
    },
  );
}
