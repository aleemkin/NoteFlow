import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/shell/presentation/mobile/mobile.dart';
import 'package:noteflow/features/vault/vault.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';

void main() {
  group('Android Mobile UI & Adaptive Design Tests', () {
    late Directory tempDir;
    late VaultManager vaultManager;

    setUp(() async {
      AppPlatform.overrideIsMobileForTest = true;
      VaultStateStorage.disablePersistenceForTest = true;
      tempDir = await Directory.systemTemp.createTemp('nview_android_test_');

      // Create sample vault structure:
      // /note1.md
      // /diagram1.excalidraw
      // /docs/guide.md
      final noteFile = File('${tempDir.path}/note1.md');
      await noteFile.writeAsString('# Note 1\nHello from mobile Android.');

      final drawFile = File('${tempDir.path}/diagram1.excalidraw');
      await drawFile.writeAsString('{"elements":[]}');

      final docsDir = Directory('${tempDir.path}/docs');
      await docsDir.create();
      final guideFile = File('${docsDir.path}/guide.md');
      await guideFile.writeAsString('## Guide Note\nMobile instructions.');

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

    testWidgets(
      'MobileWelcomeView displays touch-first action tiles and manages recents',
      (tester) async {
        var openVaultCalled = false;
        var createVaultCalled = false;
        var sampleVaultCalled = false;
        String? openedRecentPath;

        final recentVaultPath = '${tempDir.path}/RecentVault';
        VaultStateStorage.testOverrideRecentPaths = [recentVaultPath];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileWelcomeView(
                onOpenVault: () => openVaultCalled = true,
                onCreateVault: () => createVaultCalled = true,
                onOpenSampleVault: () => sampleVaultCalled = true,
                onOpenVaultPath: (path) => openedRecentPath = path,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify branding & tagline
        expect(
          find.byWidgetPredicate(
            (w) => w is AppSvgIcon && w.width == 56 && w.height == 56,
          ),
          findsOneWidget,
        );
        expect(find.text('Noteflow'), findsOneWidget);
        expect(
          find.text(
            'Local-first knowledge notebook\nwith Markdown & Excalidraw diagrams',
          ),
          findsOneWidget,
        );

        // Verify action tiles
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is AppSvgIcon &&
                (w.assetPath == AppSvgIcons.folder ||
                    w.assetPath == AppSvgIcons.openFolder),
          ),
          findsWidgets,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is AppSvgIcon && w.assetPath == AppSvgIcons.newFolder,
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is AppSvgIcon &&
                (w.assetPath == AppSvgIcons.openBook ||
                    w.assetPath == AppSvgIcons.notes),
          ),
          findsOneWidget,
        );
        expect(find.text('Open Local Folder'), findsOneWidget);
        expect(find.text('New Vault'), findsOneWidget);
        expect(find.text('Explore Sample Vault'), findsOneWidget);

        // Verify recent vaults list
        expect(find.text('RECENT WORKSPACES'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('RecentVault'), 200);
        expect(find.text('RecentVault'), findsOneWidget);

        // Test tap on Open Local Folder
        await tester.tap(find.text('Open Local Folder'));
        expect(openVaultCalled, isTrue);

        // Test tap on New Vault
        await tester.tap(find.text('New Vault'));
        expect(createVaultCalled, isTrue);

        // Test tap on Explore Sample Vault
        await tester.tap(find.text('Explore Sample Vault'));
        expect(sampleVaultCalled, isTrue);

        // Test tap on Recent Vault
        await tester.scrollUntilVisible(find.text('RecentVault'), 200);
        await tester.tap(find.text('RecentVault'));
        expect(openedRecentPath, equals(recentVaultPath));

        // Verify "Buy me a coffee" support section below recent workspaces and before privacy policy
        await tester.scrollUntilVisible(find.text('Buy me a coffee'), 200);
        expect(find.text('Buy me a coffee'), findsOneWidget);

        await tester.scrollUntilVisible(find.text('Privacy Policy'), 200);
        expect(find.text('Privacy Policy'), findsOneWidget);

        // Tap on Buy me a coffee section to open SupportScreen
        await tester.tap(find.text('Buy me a coffee'));
        await tester.pumpAndSettle();
        expect(find.text('Support NoteFlow'), findsOneWidget);
      },
    );
    testWidgets(
      'MobileEditorAccessoryBar inserts markdown formatting and directives',
      (tester) async {
        final controller = TextEditingController(text: 'Hello mobile world');
        final focusNode = FocusNode();
        String? changedText;
        var drawingRequested = false;

        await tester.binding.setSurfaceSize(const Size(1000, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileEditorAccessoryBar(
                controller: controller,
                focusNode: focusNode,
                onTextChanged: (val) => changedText = val,
                onInsertDrawing: () => drawingRequested = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify formatting buttons exist
        expect(find.text('H1'), findsOneWidget);
        expect(find.text('H2'), findsOneWidget);
        expect(find.text('H3'), findsOneWidget);
        expect(find.text('Diagram'), findsOneWidget);
        expect(find.text('Important'), findsOneWidget);
        expect(find.text('Info'), findsNothing);

        // Select 'mobile' in text
        controller.selection = const TextSelection(
          baseOffset: 6,
          extentOffset: 12,
        );

        // Tap Bold icon
        await tester.tap(find.byIcon(Icons.format_bold_rounded));
        await tester.pumpAndSettle();

        expect(controller.text, equals('Hello **mobile** world'));
        expect(changedText, isNotNull);

        // Tap Diagram pill
        await tester.tap(find.text('Diagram'));
        expect(drawingRequested, isTrue);
      },
    );

    testWidgets(
      'MobileQuickActionSheet shows create sheet with Note, Diagram, Folder',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [vaultManagerProvider.overrideWithValue(vaultManager)],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (ctx, ref, _) => ElevatedButton(
                    onPressed: () {
                      MobileQuickActionSheet.showCreateSheet(
                        context: ctx,
                        ref: ref,
                        parentDir: const VaultUri(path: ''),
                        onFileCreated: (_) {},
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Create in Vault Root'), findsOneWidget);
        expect(find.text('New Note (.md)'), findsOneWidget);
        expect(find.text('New Excalidraw Diagram'), findsOneWidget);
        expect(find.text('New Subfolder'), findsOneWidget);
      },
    );

    testWidgets(
      'MobileHomeScreen adapts to wide tablet width by showing NavigationRail',
      (tester) async {
        // Simulate tablet size 800 x 1280
        await tester.binding.setSurfaceSize(const Size(800, 1280));
        tester.view.physicalSize = const Size(800, 1280);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

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
            child: const MaterialApp(home: MobileHomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // On wide screens (>= 720dp), NavigationRail is used instead of Bottom NavigationBar
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      },
    );
  });
}
