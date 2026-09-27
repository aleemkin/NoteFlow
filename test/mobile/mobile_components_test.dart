import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/vault/presentation/dialogs/vault_dialogs.dart';
import 'package:noteflow/features/canvas/presentation/screens/drawing_editor_screen.dart';
import 'package:noteflow/features/shell/presentation/mobile/mobile.dart';
import 'package:noteflow/features/editor/presentation/widgets/editor_components/editor.dart';
import 'package:noteflow/features/vault/vault.dart';

void main() {
  group('Mobile Components & Platform Tests', () {
    late Directory tempDir;
    late VaultManager vaultManager;

    setUp(() async {
      AppPlatform.overrideIsMobileForTest = true;
      VaultStateStorage.disablePersistenceForTest = true;
      tempDir = await Directory.systemTemp.createTemp(
        'nview_mobile_comp_test_',
      );

      // Create test files
      final noteFile = File('${tempDir.path}/test_note.md');
      await noteFile.writeAsString('# Mobile Title\n\nThis is a mobile note.');

      final drawFile = File('${tempDir.path}/test_diagram.excalidraw');
      await drawFile.writeAsString('{"elements":[]}');

      final treeRepo = VaultTreeRepository();
      vaultManager = VaultManager(treeRepository: treeRepo);
      await vaultManager.openLocalVault(tempDir.path);
    });

    tearDown(() async {
      AppPlatform.overrideIsMobileForTest = null;
      VaultStateStorage.disablePersistenceForTest = false;
      await vaultManager.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('AppPlatform returns correct mobile flags and directories', () async {
      expect(AppPlatform.isMobile, isTrue);
      expect(AppPlatform.isDesktop, isFalse);

      final docPath = await AppPlatform.getDocumentsDirectoryPath();
      expect(docPath, isNotEmpty);

      final supportPath = await AppPlatform.getSupportDirectoryPath();
      expect(supportPath, isNotEmpty);

      final deviceDocs = await AppPlatform.getDeviceDocumentsDirectory();
      expect(deviceDocs, isNotEmpty);

      final deviceDocsSync = AppPlatform.getDeviceDocumentsDirectorySync();
      expect(deviceDocsSync, isNotEmpty);
    });

    testWidgets(
      'MobileEditorScreen shows empty state when no document is selected',
      (tester) async {
        var openFilesCalled = false;
        var createNoteCalled = false;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: MobileEditorScreen(
                  documentPath: null,
                  onOpenFiles: () => openFilesCalled = true,
                  onCreateNote: () => createNoteCalled = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No note selected'), findsOneWidget);
        expect(
          find.text(
            'Select a file from the Files tab or create a new one to start writing.',
          ),
          findsOneWidget,
        );
        expect(find.text('Browse Files'), findsOneWidget);
        expect(find.text('New Note'), findsOneWidget);

        // Tap Browse Files
        await tester.tap(find.text('Browse Files'));
        expect(openFilesCalled, isTrue);

        // Tap New Note
        await tester.tap(find.text('New Note'));
        expect(createNoteCalled, isTrue);
      },
    );

    testWidgets(
      'MobileEditorScreen renders DrawingEditorScreen for .excalidraw files',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              vaultManagerProvider.overrideWithValue(vaultManager),
              currentVaultProvider.overrideWith(
                (ref) => vaultManager.currentVault,
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: MobileEditorScreen(
                  documentPath: 'test_diagram.excalidraw',
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(DrawingEditorScreen), findsOneWidget);
        final drawing = tester.widget<DrawingEditorScreen>(
          find.byType(DrawingEditorScreen),
        );
        expect(drawing.drawingPath, equals('test_diagram.excalidraw'));
      },
    );

    testWidgets(
      'MobileEditorScreen renders top accessory bar without inner AppBar or info tag',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              vaultManagerProvider.overrideWithValue(vaultManager),
              currentVaultProvider.overrideWith(
                (ref) => vaultManager.currentVault,
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: MobileEditorScreen(documentPath: 'test_note.md'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Inner AppBar is removed
        expect(
          find.descendant(
            of: find.byType(MobileEditorScreen),
            matching: find.byType(AppBar),
          ),
          findsNothing,
        );
        // Edit / Preview segments are removed
        expect(find.text('Edit'), findsNothing);
        expect(find.text('Preview'), findsNothing);

        // Top accessory bar is rendered
        expect(find.byType(MobileEditorAccessoryBar), findsOneWidget);
        expect(find.text('H1'), findsOneWidget);
        expect(find.text('Diagram'), findsOneWidget);
        expect(find.text('Important'), findsOneWidget);

        // Info tag button is removed
        expect(find.text('Info'), findsNothing);

        // Raw editor pane is active
        expect(find.byType(EditorRawPane), findsOneWidget);
      },
    );

    testWidgets(
      'MobileDrawingsGallery lists excalidraw files and allows opening canvas',
      (tester) async {
        String? openedDrawing;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              vaultManagerProvider.overrideWithValue(vaultManager),
              vaultTreeRepositoryProvider.overrideWith(
                (ref) => vaultManager.treeRepository,
              ),
              currentVaultProvider.overrideWith(
                (ref) => vaultManager.currentVault,
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MobileDrawingsGallery(
                  onOpenDrawing: (path) => openedDrawing = path,
                  onCreateDrawing: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MobileDrawingsGallery), findsOneWidget);
        expect(find.text('test_diagram'), findsOneWidget);

        // Tap drawing tile
        await tester.tap(find.text('test_diagram'));
        expect(openedDrawing, equals('test_diagram.excalidraw'));
      },
    );

    testWidgets(
      'MobileVaultDetailsTab renders clean minimal UI without shortcuts button',
      (tester) async {
        var closeVaultCalled = false;
        var openVaultCalled = false;
        var createVaultCalled = false;
        var sampleVaultCalled = false;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              vaultManagerProvider.overrideWithValue(vaultManager),
              vaultTreeRepositoryProvider.overrideWith(
                (ref) => vaultManager.treeRepository,
              ),
              currentVaultProvider.overrideWith(
                (ref) => vaultManager.currentVault,
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MobileVaultDetailsTab(
                  onOpenVault: () => openVaultCalled = true,
                  onCreateVault: () => createVaultCalled = true,
                  onOpenSampleVault: () => sampleVaultCalled = true,
                  onOpenVaultPath: (_) {},
                  onCloseVault: () => closeVaultCalled = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Active workspace card & metrics
        expect(find.byType(MobileVaultDetailsTab), findsOneWidget);
        expect(find.text('ACTIVE'), findsOneWidget);
        expect(find.text('Notes'), findsOneWidget);
        expect(find.text('Drawings'), findsOneWidget);
        expect(find.text('Folders'), findsOneWidget);

        // Clean grouped actions
        expect(find.text('ACTIONS'), findsOneWidget);
        expect(find.text('Open Local Vault'), findsOneWidget);
        expect(find.text('Create New Vault'), findsOneWidget);
        expect(find.text('Explore Sample Vault'), findsOneWidget);

        // Keyboard shortcuts button is removed
        expect(find.text('Shortcuts'), findsNothing);
        expect(find.byIcon(Icons.keyboard_outlined), findsNothing);

        // Clean Close Vault button
        await tester.scrollUntilVisible(find.text('Close Vault'), 200);
        expect(find.text('Close Vault'), findsOneWidget);
        await tester.tap(find.text('Close Vault'));
        expect(closeVaultCalled, isTrue);

        // Action callbacks
        await tester.scrollUntilVisible(find.text('Open Local Vault'), -200);
        await tester.tap(find.text('Open Local Vault'));
        expect(openVaultCalled, isTrue);
        await tester.tap(find.text('Create New Vault'));
        expect(createVaultCalled, isTrue);
        await tester.tap(find.text('Explore Sample Vault'));
        expect(sampleVaultCalled, isTrue);
      },
    );

    testWidgets(
      'VaultDialogs.showCreateVaultDialog renders clean UI with device documents directory',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => VaultDialogs.showCreateVaultDialog(context),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Create New Vault'), findsOneWidget);
        expect(find.text('VAULT NAME'), findsOneWidget);
        expect(find.text('LOCATION'), findsOneWidget);
        expect(
          find.text('Initialize with starter welcome note'),
          findsOneWidget,
        );
        expect(find.text('Browse...'), findsOneWidget);
        expect(find.text('Create Vault'), findsOneWidget);

        final locationField = tester.widget<TextField>(
          find.byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.controller?.text.isNotEmpty == true &&
                w.controller?.text != 'My Vault',
          ),
        );
        expect(locationField.controller?.text, isNotEmpty);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      },
    );

    test(
      'SampleVaultLoader unpacks sample files in mobile environment',
      () async {
        final sampleDir = await SampleVaultLoader.ensureSampleVaultOnDisk(
          customTargetDir: '${tempDir.path}/MobileSampleVault',
        );
        expect(Directory(sampleDir).existsSync(), isTrue);

        final welcomeFile = File('$sampleDir/01_Welcome_to_noteflow.md');
        expect(welcomeFile.existsSync(), isTrue);
        expect(welcomeFile.readAsStringSync(), contains('Welcome to noteflow'));

        final manager = VaultManager(treeRepository: VaultTreeRepository());
        addTearDown(() => manager.close());
        await manager.openLocalVault(
          sampleDir,
          customDisplayName: 'Sample Vault',
        );
        expect(manager.currentVault?.displayName, 'Sample Vault');
      },
    );
  });
}
