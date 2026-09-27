import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/features/shell/presentation/widgets/vault_loading_overlay.dart';
import 'package:noteflow/features/vault/data/sample_vault_loader.dart';
import 'package:noteflow/features/vault/data/vault_manager.dart';
import 'package:noteflow/features/vault/data/vault_tree_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('noteflow_sample_vault_test_');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('Desktop & Mobile Sample Vaults Tests', () {
    test('Desktop sample vault unpacks desktop-tailored content and sequences', () async {
      final desktopTargetDir = '${tempDir.path}/DesktopVault';
      final progressUpdates = <String>[];
      final progressValues = <double?>[];

      final resultDir = await SampleVaultLoader.ensureSampleVaultOnDisk(
        customTargetDir: desktopTargetDir,
        isMobile: false,
        onProgress: (msg, prog) {
          progressUpdates.add(msg);
          progressValues.add(prog);
        },
      );

      expect(Directory(resultDir).existsSync(), isTrue);
      expect(progressUpdates, isNotEmpty);
      expect(progressValues, isNotEmpty);

      // Verify desktop files
      final welcomeFile = File('$resultDir/01_Welcome_to_noteflow.md');
      expect(welcomeFile.existsSync(), isTrue);
      final welcomeContent = welcomeFile.readAsStringSync();
      expect(welcomeContent, contains('Welcome to noteflow'));
      expect(welcomeContent, contains('Ctrl+1'));
      expect(welcomeContent, contains('Ctrl+2'));

      final shortcutsFile = File('$resultDir/02_Keyboard_Shortcuts_and_Navigation.md');
      expect(shortcutsFile.existsSync(), isTrue);
      expect(shortcutsFile.readAsStringSync(), contains('Spotlight Search'));

      final directivesFile = File('$resultDir/03_Markdown_and_Tag_Directives.md');
      expect(directivesFile.existsSync(), isTrue);

      final guidesDir = Directory('$resultDir/01_Guides');
      expect(guidesDir.existsSync(), isTrue);
      expect(File('$resultDir/01_Guides/Dual_Pane_Split_Editor.md').existsSync(), isTrue);
      expect(File('$resultDir/01_Guides/Outline_and_Drag_Reorder.md').existsSync(), isTrue);

      final archDir = Directory('$resultDir/02_Architecture');
      expect(archDir.existsSync(), isTrue);
      expect(File('$resultDir/02_Architecture/System_Architecture.md').existsSync(), isTrue);
      expect(File('$resultDir/02_Architecture/system_architecture.excalidraw').existsSync(), isTrue);
      expect(File('$resultDir/02_Architecture/system_architecture.excalidraw.png').existsSync(), isTrue);

      final seqFile = File('$resultDir/.kn/sequences.json');
      expect(seqFile.existsSync(), isTrue);
      expect(seqFile.readAsStringSync(), contains('01_Guides/Dual_Pane_Split_Editor.md'));

      // Test opening via VaultManager
      final manager = VaultManager(treeRepository: VaultTreeRepository());
      addTearDown(() => manager.close());
      await manager.openLocalVault(resultDir, customDisplayName: 'Sample Vault');
      expect(manager.currentVault?.displayName, 'Sample Vault');
    });

    test('Mobile sample vault unpacks mobile-tailored content, gestures, and drawings', () async {
      final mobileTargetDir = '${tempDir.path}/MobileVault';
      final progressUpdates = <String>[];

      final resultDir = await SampleVaultLoader.ensureSampleVaultOnDisk(
        customTargetDir: mobileTargetDir,
        isMobile: true,
        onProgress: (msg, prog) {
          progressUpdates.add(msg);
        },
      );

      expect(Directory(resultDir).existsSync(), isTrue);
      expect(progressUpdates, isNotEmpty);

      // Verify mobile files
      final welcomeFile = File('$resultDir/01_Welcome_to_noteflow.md');
      expect(welcomeFile.existsSync(), isTrue);
      final welcomeContent = welcomeFile.readAsStringSync();
      expect(welcomeContent, contains('Welcome to noteflow'));
      expect(welcomeContent, contains('4 Core Mobile Tabs'));
      expect(welcomeContent, contains('Notes'));
      expect(welcomeContent, contains('Canvas'));

      final gesturesFile = File('$resultDir/02_Mobile_Gesture_and_Touch_Guide.md');
      expect(gesturesFile.existsSync(), isTrue);
      final gesturesContent = gesturesFile.readAsStringSync();
      expect(gesturesContent, contains('Horizontal Swipe'));
      expect(gesturesContent, contains('Floating Action Button'));

      final dailyDir = Directory('$resultDir/01_Daily_Notes');
      expect(dailyDir.existsSync(), isTrue);
      expect(File('$resultDir/01_Daily_Notes/Today_Focus.md').existsSync(), isTrue);
      expect(File('$resultDir/01_Daily_Notes/Meeting_and_Ideas.md').existsSync(), isTrue);

      final drawingsDir = Directory('$resultDir/02_Drawings');
      expect(drawingsDir.existsSync(), isTrue);
      expect(File('$resultDir/02_Drawings/Mobile_Diagram_Workflow.md').existsSync(), isTrue);
      final excalidrawFile = File('$resultDir/02_Drawings/mobile_workflow.excalidraw');
      expect(excalidrawFile.existsSync(), isTrue);
      expect(excalidrawFile.readAsStringSync(), contains('Quick Capture'));
      final excalidrawPng = File('$resultDir/02_Drawings/mobile_workflow.excalidraw.png');
      expect(excalidrawPng.existsSync(), isTrue);
      expect(excalidrawPng.lengthSync(), greaterThan(100));

      final seqFile = File('$resultDir/.kn/sequences.json');
      expect(seqFile.existsSync(), isTrue);
      expect(seqFile.readAsStringSync(), contains('01_Daily_Notes'));
    });

    testWidgets('VaultLoadingOverlay renders title, step message, and progress bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Center(child: Text('Underlying Screen')),
                VaultLoadingOverlay(
                  title: 'Setting up Sample Vault',
                  message: 'Saving sample notes & diagrams to disk...',
                  progress: 0.65,
                  subtitle: 'Saving notes and diagrams to local storage',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Setting up Sample Vault'), findsOneWidget);
      expect(find.text('Saving sample notes & diagrams to disk...'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('Saving files...'), findsOneWidget);
      expect(find.text('Saving notes and diagrams to local storage'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('VaultLoadingOverlay renders spinner when progress is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                VaultLoadingOverlay(
                  title: 'Opening Workspace',
                  message: 'Scanning notebook files...',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Opening Workspace'), findsOneWidget);
      expect(find.text('Scanning notebook files...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
