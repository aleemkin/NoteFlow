import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/features/vault/presentation/dialogs/vault_dialogs.dart';
import 'package:noteflow/features/shell/presentation/welcome/welcome_view.dart';
import 'package:noteflow/features/vault/data/vault_state_storage.dart';

void main() {
  group('WelcomeView Widget Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('noteflow_welcome_test_');
      VaultStateStorage.disablePersistenceForTest = true;
      VaultStateStorage.testOverrideRecentPaths = null;
    });

    tearDown(() {
      VaultStateStorage.testOverrideRecentPaths = null;
      VaultStateStorage.disablePersistenceForTest = false;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets(
      'renders brand header, primary action buttons, and keyboard shortcuts',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        var openVaultCalled = false;
        var sampleVaultCalled = false;
        var createVaultCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WelcomeView(
                onOpenVault: () => openVaultCalled = true,
                onCreateVault: () => createVaultCalled = true,
                onOpenVaultPath: (_) {},
                onOpenSampleVault: () => sampleVaultCalled = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Noteflow'), findsWidgets);
        expect(find.text('Open Local Folder'), findsOneWidget);
        expect(find.text('Choose Folder'), findsOneWidget);
        expect(find.text('Explore Sample Vault'), findsOneWidget);
        expect(find.text('Launch Sandbox'), findsOneWidget);
        expect(find.text('New Vault'), findsOneWidget);
        expect(find.text('Create Empty'), findsOneWidget);
        expect(find.text('Ctrl+O'), findsWidgets);
        expect(find.text('Ctrl+N'), findsWidgets);
        expect(find.text('Ctrl+K'), findsOneWidget);

        // Tap Choose Folder
        await tester.tap(find.text('Choose Folder'));
        expect(openVaultCalled, isTrue);

        // Tap Launch Sandbox
        await tester.tap(find.text('Launch Sandbox'));
        expect(sampleVaultCalled, isTrue);

        // Tap Create Empty
        await tester.tap(find.text('Create Empty'));
        expect(createVaultCalled, isTrue);
      },
    );

    testWidgets(
      'displays empty state with action buttons when no recent vaults exist',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        var openVaultCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WelcomeView(
                onOpenVault: () => openVaultCalled = true,
                onOpenVaultPath: (_) {},
                onOpenSampleVault: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No Recent Workspaces'), findsOneWidget);
        expect(find.text('Choose Folder'), findsOneWidget);

        await tester.tap(find.text('Choose Folder'));
        expect(openVaultCalled, isTrue);
      },
    );

    testWidgets(
      'displays recent vaults, supports filtering, and opens on tap',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final vaultA = Directory('${tempDir.path}/AlphaNotes')..createSync();
        final vaultB = Directory('${tempDir.path}/BetaResearch')..createSync();
        final vaultC = Directory('${tempDir.path}/GammaArchive')..createSync();

        VaultStateStorage.testOverrideRecentPaths = [
          vaultA.path,
          vaultB.path,
          vaultC.path,
        ];

        String? openedPath;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WelcomeView(
                onOpenVault: () {},
                onOpenVaultPath: (path) => openedPath = path,
                onOpenSampleVault: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('RECENT WORKSPACES'), findsOneWidget);
        expect(find.text('AlphaNotes'), findsOneWidget);
        expect(find.text('BetaResearch'), findsOneWidget);
        expect(find.text('GammaArchive'), findsOneWidget);

        // Filter recent vaults
        final searchInput = find.byType(TextField);
        expect(searchInput, findsOneWidget);

        await tester.enterText(searchInput, 'Gamma');
        await tester.pumpAndSettle();

        expect(find.text('GammaArchive'), findsOneWidget);
        expect(find.text('AlphaNotes'), findsNothing);

        // Scroll into view and tap GammaArchive to open
        await tester.ensureVisible(find.text('GammaArchive'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('GammaArchive'));
        await tester.pumpAndSettle();

        expect(openedPath, vaultC.path);
      },
    );

    testWidgets(
      'VaultDialogs.showCreateVaultDialog creates new vault folder and welcome note',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        String? createdPath;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    createdPath = await VaultDialogs.showCreateVaultDialog(
                      context,
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Create New Vault'), findsOneWidget);
        expect(find.text('Create Vault'), findsOneWidget);

        // Enter vault name and location
        final textFields = find.byType(TextField);
        expect(textFields, findsNWidgets(2));

        await tester.enterText(textFields.first, 'DeltaNotes');
        await tester.enterText(textFields.last, tempDir.path);
        await tester.pumpAndSettle();

        // Tap Create Vault
        await tester.runAsync(() async {
          await tester.tap(find.text('Create Vault'));
          for (int i = 0; i < 50; i++) {
            await Future.delayed(const Duration(milliseconds: 50));
            if (createdPath != null) break;
          }
        });
        await tester.pumpAndSettle();

        final expectedDir = Directory('${tempDir.path}/DeltaNotes');
        expect(createdPath, expectedDir.path);
        expect(expectedDir.existsSync(), isTrue);

        final welcomeNote = File('${expectedDir.path}/Welcome.md');
        expect(welcomeNote.existsSync(), isTrue);
        expect(
          welcomeNote.readAsStringSync(),
          contains('Welcome to DeltaNotes'),
        );
      },
    );
  });
}
