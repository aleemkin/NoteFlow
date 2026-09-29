import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';
import 'package:noteflow/features/vault/presentation/dialogs/create_vault_dialog.dart';

void main() {
  group('CreateVaultDialog Path Formatting', () {
    test('formats Android emulator and internal storage paths without noise', () {
      expect(
        CreateVaultDialog.formatDisplayLocation('/storage/emulated/0/Documents'),
        'Documents',
      );
      expect(
        CreateVaultDialog.formatDisplayLocation('/storage/emulator/0/Documents'),
        'Documents',
      );
      expect(
        CreateVaultDialog.formatDisplayLocation('emulator/0/Documents'),
        'Documents',
      );
      expect(
        CreateVaultDialog.formatDisplayLocation('emulated/0/Documents'),
        'Documents',
      );
      expect(
        CreateVaultDialog.formatDisplayLocation('/storage/emulated/0'),
        'Internal Storage',
      );
      expect(
        CreateVaultDialog.formatDisplayLocation('/storage/emulator/0/'),
        'Internal Storage',
      );
      expect(
        CreateVaultDialog.formatDisplayLocation('/storage/self/primary/Documents'),
        'Documents',
      );
      expect(
        CreateVaultDialog.formatDisplayLocation('/sdcard/Documents/Notes'),
        'Documents / Notes',
      );
      expect(
        CreateVaultDialog.formatDisplayLocation('/storage/emulated/0/Download'),
        'Download',
      );
    });

    test('formats app data and iOS sandbox storage cleanly', () {
      expect(
        CreateVaultDialog.formatDisplayLocation(
          '/data/user/0/com.noteflow.app/app_flutter/my_vaults',
        ),
        'App Storage / my_vaults',
      );
      expect(
        CreateVaultDialog.formatDisplayLocation(
          '/var/mobile/Containers/Data/Application/ABC-123/Documents',
        ),
        'Documents',
      );
    });

    test('formats preview paths combining location and vault name', () {
      expect(
        CreateVaultDialog.formatPreviewPath(
          '/storage/emulated/0/Documents',
          'My Vault',
        ),
        'Documents / My Vault',
      );
      expect(
        CreateVaultDialog.formatPreviewPath(
          '/storage/emulator/0/Documents',
          'Research',
        ),
        'Documents / Research',
      );
      expect(
        CreateVaultDialog.formatPreviewPath(
          '/storage/emulated/0',
          'Work',
        ),
        'Internal Storage / Work',
      );
      expect(
        CreateVaultDialog.formatPreviewPath(
          '/sdcard/Notes',
          'Personal',
        ),
        'Notes / Personal',
      );
    });
  });

  group('CreateVaultDialog Widget & SVG Icons', () {
    testWidgets('renders modal with SVG icons and no Flutter built-in icons', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateVaultDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dialog title and description
      expect(find.text('Create New Vault'), findsOneWidget);
      expect(
        find.text('Initialize a local-first markdown workspace'),
        findsOneWidget,
      );

      // Verify our SVG icons are present
      final svgIcons = find.byType(AppSvgIcon);
      expect(svgIcons, findsWidgets);

      // Verify that old Flutter built-in icons are NOT used
      expect(find.byIcon(Icons.create_new_folder_outlined), findsNothing);
      expect(find.byIcon(Icons.folder_outlined), findsNothing);
      expect(find.byIcon(Icons.folder_open_outlined), findsNothing);
      expect(find.byIcon(Icons.folder_open_rounded), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Check fields
      expect(find.text('VAULT NAME'), findsOneWidget);
      expect(find.text('LOCATION'), findsOneWidget);
      expect(find.text('Browse...'), findsOneWidget);
      expect(find.text('Create Vault'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(
        find.text('Initialize with starter welcome note'),
        findsOneWidget,
      );

      // Location field and preview do not contain raw emulator/0 noise
      final locationField = find.byType(TextField).last;
      final locationController =
          tester.widget<TextField>(locationField).controller!;
      expect(locationController.text, isNot(contains('emulator/0')));
      expect(locationController.text, isNot(contains('emulated/0')));

      // Preview row text does not contain raw emulator/0 noise
      expect(find.textContaining('Will be created at:'), findsOneWidget);
      expect(find.textContaining('emulator/0'), findsNothing);
      expect(find.textContaining('/storage/emulated/0'), findsNothing);
    });

    testWidgets('toggles starter note option on row tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateVaultDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final checkboxFinder = find.byType(Checkbox);
      expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);

      // Tap on the row text to toggle
      await tester.tap(find.text('Initialize with starter welcome note'));
      await tester.pumpAndSettle();

      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
    });

    testWidgets('validates empty and invalid vault names', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateVaultDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);

      // Empty name
      await tester.enterText(textFields.first, '');
      await tester.tap(find.text('Create Vault'));
      await tester.pumpAndSettle();
      expect(find.text('Vault name cannot be empty'), findsOneWidget);

      // Invalid character
      await tester.enterText(textFields.first, 'My:Vault*');
      await tester.tap(find.text('Create Vault'));
      await tester.pumpAndSettle();
      expect(find.text('Vault name contains invalid characters'), findsOneWidget);
    });

    testWidgets('creates vault in custom directory when submitted', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final tempDir = Directory.systemTemp.createTempSync('noteflow_dialog_test_');
      addTearDown(() {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      });

      String? resultPath;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  resultPath = await showDialog<String>(
                    context: ctx,
                    builder: (_) => const CreateVaultDialog(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'TestVaultAlpha');
      await tester.enterText(textFields.last, tempDir.path);
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.text('Create Vault'));
        for (int i = 0; i < 50; i++) {
          await Future.delayed(const Duration(milliseconds: 50));
          if (resultPath != null) break;
        }
      });
      await tester.pumpAndSettle();

      final expectedPath = '${tempDir.path}/TestVaultAlpha';
      expect(resultPath, expectedPath);
      expect(Directory(expectedPath).existsSync(), isTrue);
      expect(File('$expectedPath/Welcome.md').existsSync(), isTrue);
    });
  });
}
