import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/app/notebook_app.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/render/render.dart';
import 'package:noteflow/features/canvas/presentation/screens/drawing_editor_screen.dart';
import 'package:noteflow/features/shell/presentation/home_screen.dart';
import 'package:noteflow/features/vault/presentation/widgets/vault_tree_widget.dart';
import 'package:noteflow/features/vault/vault.dart';

void main() {
  group('MobileHomeScreen Tests', () {
    setUp(() {
      AppPlatform.overrideIsMobileForTest = true;
      VaultStateStorage.disablePersistenceForTest = true;
      VaultStateStorage.testOverrideLastPath = null;
      LocalPathVaultFileSystem.disableWatcherForTest = true;
    });

    tearDown(() {
      AppPlatform.overrideIsMobileForTest = null;
      VaultStateStorage.disablePersistenceForTest = false;
    });

    testWidgets(
      'HomeScreen routes to MobileHomeScreen when on mobile platform',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(
          const Size(390, 844),
        ); // iPhone 12/13/14 size
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const ProviderScope(child: NotebookApp()));
        await tester.pumpAndSettle();

        // Should render MobileHomeScreen and WelcomeView
        expect(find.byType(MobileHomeScreen), findsOneWidget);
        expect(find.text('Noteflow'), findsWidgets);
        expect(find.text('Explore Sample Vault'), findsOneWidget);
        expect(find.text('Open Local Folder'), findsOneWidget);

        // WindowChrome desktop widgets must NOT be present on mobile
        expect(find.text('Search...'), findsNothing);
      },
    );

    testWidgets(
      'MobileHomeScreen renders navigation bar, tabs, and drawer when vault is open',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fs = MemoryVaultFileSystem();
        fs.seed('note1.md', '# Note Title\nNote body text.');
        final treeRepo = VaultTreeRepository();
        final manager = VaultManager(treeRepository: treeRepo);
        await manager.openCustomFileSystem(fs, 'Mobile Vault');

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

        // 1. Verify AppBar is present with const 'Notebook Workspace' title
        expect(find.byType(AppBar), findsWidgets);
        expect(find.text('Notebook Workspace'), findsWidgets);

        // 2. Verify Bottom NavigationBar is present with 4 tabs: Notes, Editor, Canvas, Vault
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Notes'), findsOneWidget);
        expect(find.text('Editor'), findsOneWidget);
        expect(find.text('Canvas'), findsOneWidget);
        expect(find.text('Vault'), findsOneWidget);

        // Verify Reading stream is active
        expect(find.byType(MobileReadingScreen), findsOneWidget);

        // 3. Switch to Editor tab
        await tester.tap(find.text('Editor'));
        await tester.pumpAndSettle();
        expect(find.byType(MobileEditorScreen), findsOneWidget);

        // 4. Switch to Canvas tab
        await tester.tap(find.text('Canvas'));
        await tester.pumpAndSettle();
        expect(find.byType(MobileDrawingsGallery), findsOneWidget);

        // 5. Switch to Vault tab
        await tester.tap(find.text('Vault'));
        await tester.pumpAndSettle();
        expect(find.byType(MobileVaultDetailsTab), findsOneWidget);
        // Top AppBar is hidden on Vault tab
        expect(find.text('Notebook Workspace'), findsNothing);

        // Switch back to Notes tab to test drawer
        await tester.tap(find.widgetWithText(NavigationDestination, 'Notes'));
        await tester.pumpAndSettle();
        expect(find.text('Notebook Workspace'), findsWidgets);

        // 6. Open Left Drawer (desktop left panel)
        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        expect(find.byType(VaultTreeWidget), findsOneWidget);

        // Close left drawer
        tester.state<NavigatorState>(find.byType(Navigator).last).pop();
        await tester.pumpAndSettle();

        // 7. Open Right Drawer (desktop right panel)
        scaffoldState.openEndDrawer();
        await tester.pumpAndSettle();

        expect(find.text('Outline & Structure'), findsOneWidget);
      },
    );

    testWidgets(
      'Canvas tab renders full-bleed drawing without inner AppBar and top AppBar adapts with back chevron',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fs = MemoryVaultFileSystem();
        fs.seed('diagram.excalidraw', '{"elements":[]}');
        final treeRepo = VaultTreeRepository();
        final manager = VaultManager(treeRepository: treeRepo);
        await manager.openCustomFileSystem(fs, 'Mobile Vault');

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

        // 1. Switch to Canvas tab
        await tester.tap(find.text('Canvas'));
        await tester.pumpAndSettle();
        expect(find.byType(MobileDrawingsGallery), findsOneWidget);
        expect(find.text('Notebook Workspace'), findsOneWidget);
        // Right drawer button must NOT be present in Canvas tab
        expect(find.byTooltip('Outline & Structure'), findsNothing);

        // 2. Tap on drawing to open it
        await tester.tap(find.text('diagram'));
        await tester.pump(const Duration(milliseconds: 200));

        // Verify DrawingEditorScreen is rendered with showAppBar: false
        final drawingEditor = tester.widget<DrawingEditorScreen>(
          find.byType(DrawingEditorScreen),
        );
        expect(drawingEditor.showAppBar, isFalse);

        // Top AppBar should now show [←] diagram.excalidraw
        expect(find.byTooltip('Back to drawings'), findsOneWidget);
        expect(find.text('diagram.excalidraw'), findsOneWidget);

        // The redundant inner save button must NOT exist
        expect(find.text('Save'), findsNothing);

        // 3. Tap back chevron
        await tester.tap(find.byTooltip('Back to drawings'));
        await tester.pump(const Duration(milliseconds: 200));

        // Returns to gallery with Notebook Workspace title
        expect(find.byType(MobileDrawingsGallery), findsOneWidget);
        expect(find.text('Notebook Workspace'), findsOneWidget);
      },
    );

    testWidgets(
      'Notes tab FAB click opens Left Drawer with create buttons and inline creation',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fs = MemoryVaultFileSystem();
        fs.seed('note1.md', '# Note 1\nContent');
        final treeRepo = VaultTreeRepository();
        final manager = VaultManager(treeRepository: treeRepo);
        await manager.openCustomFileSystem(fs, 'Mobile Vault');

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

        // 1. FAB is present on Notes tab
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        // 2. Click FAB
        await tester.tap(fabFinder);
        await tester.pumpAndSettle();

        // 4. Verify InlineCreateRow is activated
        expect(find.byType(InlineCreateRow), findsOneWidget);

        // 5. Switch to creating folder
        await tester.tap(find.byIcon(Icons.create_new_folder_outlined));
        await tester.pumpAndSettle();
        expect(find.byType(InlineCreateRow), findsOneWidget);

        // Close drawer
        tester.state<NavigatorState>(find.byType(Navigator).last).pop();
        await tester.pumpAndSettle();

        // 6. Switch to Editor tab - FAB must NOT be present
        await tester.tap(find.text('Editor'));
        await tester.pumpAndSettle();
        expect(find.byType(FloatingActionButton), findsNothing);

        // Verify empty state "No note selected" is present and tapping "New Note" opens drawer
        expect(find.text('No note selected'), findsOneWidget);
        final newNoteButton = find.widgetWithText(FilledButton, 'New Note');
        expect(newNoteButton, findsOneWidget);

        await tester.tap(newNoteButton);
        await tester.pumpAndSettle();

        expect(find.byType(VaultTreeWidget), findsOneWidget);
        expect(find.byType(InlineCreateRow), findsOneWidget);

        // Close drawer
        tester.state<NavigatorState>(find.byType(Navigator).last).pop();
        await tester.pumpAndSettle();

        // 7. Switch to Canvas tab - FAB must NOT be present
        await tester.tap(find.text('Canvas'));
        await tester.pumpAndSettle();
        expect(find.byType(FloatingActionButton), findsNothing);

        // Verify empty state "New Diagram" button is present and tapping it opens drawer with InlineCreateRow
        expect(find.text('No diagrams yet'), findsOneWidget);
        final newDiagramButton = find.widgetWithText(
          FilledButton,
          'New Diagram',
        );
        expect(newDiagramButton, findsOneWidget);

        await tester.tap(newDiagramButton);
        await tester.pumpAndSettle();

        expect(find.byType(VaultTreeWidget), findsOneWidget);
        expect(find.byType(InlineCreateRow), findsOneWidget);

        // Close drawer
        tester.state<NavigatorState>(find.byType(Navigator).last).pop();
        await tester.pumpAndSettle();

        // 8. Switch to Vault tab - FAB must NOT be present
        await tester.tap(find.text('Vault'));
        await tester.pumpAndSettle();
        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );

    testWidgets(
      'Tapping folder in left drawer expands/collapses folder, does not close drawer, and updates active folder',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fs = MemoryVaultFileSystem();
        fs.seed('projects/subnote.md', '# Subnote\nSubnote content');
        fs.seed('root_note.md', '# Root Note\nRoot note content');
        final treeRepo = VaultTreeRepository();
        final manager = VaultManager(treeRepository: treeRepo);
        await manager.openCustomFileSystem(fs, 'Mobile Vault');

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

        // 1. Open left drawer
        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        expect(find.byType(VaultTreeWidget), findsOneWidget);
        expect(find.text('projects'), findsOneWidget);
        // subnote.md is inside projects and projects is initially collapsed
        expect(find.text('subnote.md'), findsNothing);

        // 2. Tap projects folder
        await tester.tap(find.text('projects'));
        await tester.pumpAndSettle();

        // Drawer MUST STILL BE OPEN!
        expect(find.byType(VaultTreeWidget), findsOneWidget);
        // Folder is now expanded, showing subnote.md
        expect(find.text('subnote.md'), findsOneWidget);

        // 3. Tap projects folder again to minimize/collapse
        await tester.tap(find.text('projects'));
        await tester.pumpAndSettle();

        // Drawer MUST STILL BE OPEN!
        expect(find.byType(VaultTreeWidget), findsOneWidget);
        // Folder is now collapsed, subnote.md is hidden
        expect(find.text('subnote.md'), findsNothing);

        // 4. Tap projects folder once more to expand again
        await tester.tap(find.text('projects'));
        await tester.pumpAndSettle();
        expect(find.text('subnote.md'), findsOneWidget);

        // 5. Tapping a file from Notes tab opens in Notes mode and closes the drawer
        await tester.tap(find.text('subnote.md'));
        await tester.pumpAndSettle();

        // Drawer should now be closed
        expect(find.byType(VaultTreeWidget), findsNothing);
        // Stays on Notes tab (MobileReadingScreen is active, MobileEditorScreen is not)
        expect(find.byType(MobileReadingScreen), findsOneWidget);
        expect(find.byType(MobileEditorScreen), findsNothing);

        // 6. Switch to Editor tab and open drawer again
        await tester.tap(find.text('Editor'));
        await tester.pumpAndSettle();
        expect(find.byType(MobileEditorScreen), findsOneWidget);

        final scaffoldStateInEditor = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        scaffoldStateInEditor.openDrawer();
        await tester.pumpAndSettle();
        expect(find.byType(VaultTreeWidget), findsOneWidget);

        // Tapping a file while on Editor tab opens it in MobileEditorScreen
        final fileInDrawer = find.descendant(
          of: find.byType(VaultTreeWidget),
          matching: find.text('root_note.md'),
        );
        await tester.tap(fileInDrawer);
        await tester.pumpAndSettle();

        expect(find.byType(VaultTreeWidget), findsNothing);
        expect(find.byType(MobileEditorScreen), findsOneWidget);
        expect(find.text('root_note.md'), findsWidgets);
      },
    );

    testWidgets(
      'Clicking .md file in left drawer opens in Notes or Editor depending on active tab, and drawings open in Canvas',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fs = MemoryVaultFileSystem();
        fs.seed('note1.md', '# Note One\nContent 1');
        fs.seed('note2.md', '# Note Two\nContent 2');
        fs.seed(
          'drawing.excalidraw',
          '{"type":"excalidraw","version":2,"source":"test","elements":[],"appState":{}}',
        );
        final treeRepo = VaultTreeRepository();
        final manager = VaultManager(treeRepository: treeRepo);
        await manager.openCustomFileSystem(fs, 'Context Test Vault');

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

        // Initially on Notes tab
        expect(find.byType(MobileReadingScreen), findsOneWidget);

        // 1. Open drawer from Notes tab and select note2.md
        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        final note2InDrawer = find.descendant(
          of: find.byType(VaultTreeWidget),
          matching: find.text('note2.md'),
        );
        await tester.tap(note2InDrawer);
        await tester.pumpAndSettle();

        // Drawer closed, remains on Notes tab!
        expect(find.byType(VaultTreeWidget), findsNothing);
        expect(find.byType(MobileReadingScreen), findsOneWidget);
        expect(find.byType(MobileEditorScreen), findsNothing);

        // 2. Open drawer from Notes tab and select drawing.excalidraw
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        final drawingInDrawer = find.descendant(
          of: find.byType(VaultTreeWidget),
          matching: find.text('drawing.excalidraw'),
        );
        await tester.tap(drawingInDrawer);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // Drawing opens in Canvas tab
        expect(find.byType(VaultTreeWidget), findsNothing);
        expect(find.byType(DrawingEditorScreen), findsOneWidget);

        // Tap back to exit drawing editor
        await tester.tap(find.byTooltip('Back to drawings'));
        await tester.pump(const Duration(milliseconds: 200));

        // 3. Switch to Editor tab
        await tester.tap(find.text('Editor'));
        await tester.pumpAndSettle();
        expect(find.byType(MobileEditorScreen), findsOneWidget);

        // Open drawer from Editor tab and select note1.md
        final scaffoldStateInEditor = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        scaffoldStateInEditor.openDrawer();
        await tester.pumpAndSettle();

        final note1InDrawer = find.descendant(
          of: find.byType(VaultTreeWidget),
          matching: find.text('note1.md'),
        );
        await tester.tap(note1InDrawer);
        await tester.pumpAndSettle();

        // Opens in Editor tab
        expect(find.byType(VaultTreeWidget), findsNothing);
        expect(find.byType(MobileEditorScreen), findsOneWidget);
        expect(find.text('note1.md'), findsWidgets);
      },
    );

    testWidgets(
      'Tapping note in drawer while viewing tagged content clears tag filter and shows note in Viewer',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fs = MemoryVaultFileSystem();
        fs.seed('note1.md', '# Note One\nContent 1 @todo');
        fs.seed('note2.md', '# Note Two\nContent without tag');
        final treeRepo = VaultTreeRepository();
        final manager = VaultManager(treeRepository: treeRepo);
        await manager.openCustomFileSystem(fs, 'Tag Context Vault');

        late WidgetRef capturedRef;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              vaultTreeRepositoryProvider.overrideWith((ref) => treeRepo),
              vaultManagerProvider.overrideWith((ref) => manager),
              currentVaultProvider.overrideWith((ref) => manager.currentVault),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                capturedRef = ref;
                return const MaterialApp(home: HomeScreen());
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Set tag filter to customTag 'todo'
        capturedRef
            .read(activeFolderControllerProvider.notifier)
            .setFilter(ScrollFilterMode.customTag, 'todo');
        await tester.pumpAndSettle();

        expect(
          capturedRef.read(activeFolderControllerProvider).filterMode,
          ScrollFilterMode.customTag,
        );

        // 2. Open drawer while on Notes tab and tap note2.md (which does not have the tag)
        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        final note2InDrawer = find.descendant(
          of: find.byType(VaultTreeWidget),
          matching: find.text('note2.md'),
        );
        await tester.tap(note2InDrawer);
        await tester.pumpAndSettle();

        // Tag filter should now be cleared!
        expect(
          capturedRef.read(activeFolderControllerProvider).filterMode,
          ScrollFilterMode.all,
        );
        // And we remain in Viewer (MobileReadingScreen)
        expect(find.byType(MobileReadingScreen), findsOneWidget);
        expect(find.byType(MobileEditorScreen), findsNothing);
      },
    );

    testWidgets(
      'Tapping folder in drawer while on Editor tab opens first note of that folder in Editor',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fs = MemoryVaultFileSystem();
        fs.seed('root_note.md', '# Root Note\nContent');
        fs.seed('docs/guide.md', '# Guide Note\nGuide Content');
        final treeRepo = VaultTreeRepository();
        final manager = VaultManager(treeRepository: treeRepo);
        await manager.openCustomFileSystem(fs, 'Folder Editor Vault');

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

        // 1. Switch to Editor tab
        await tester.tap(find.text('Editor'));
        await tester.pumpAndSettle();
        expect(find.byType(MobileEditorScreen), findsOneWidget);

        // 2. Open drawer from Editor tab
        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // 3. Tap docs folder in drawer
        final docsFolder = find.descendant(
          of: find.byType(VaultTreeWidget),
          matching: find.text('docs'),
        );
        await tester.tap(docsFolder);
        await tester.pumpAndSettle();

        // Stays on Editor tab with docs/guide.md opened
        expect(find.byType(MobileEditorScreen), findsOneWidget);
        expect(find.text('guide.md'), findsWidgets);
      },
    );
  });
}
