import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/features/document/parsing/tag_extractor.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/render/surfaces/continuous_folder_surface.dart';
import 'package:noteflow/features/vault/presentation/widgets/vault_tree_widget.dart';
import 'package:noteflow/features/vault/vault.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'VaultTreeWidget clicking bottom empty space selects root folder and no right-click popup appears',
    (WidgetTester tester) async {
      final mockTree = VaultTreeRepository();
      mockTree.setRoot(
        VaultTreeNode(
          uri: const VaultUri(path: ''),
          name: 'MyNotebook',
          isDirectory: true,
          modifiedAt: DateTime.now(),
          children: [
            VaultTreeNode(
              uri: const VaultUri(path: 'subfolder'),
              name: 'subfolder',
              isDirectory: true,
              modifiedAt: DateTime.now(),
              children: [
                VaultTreeNode(
                  uri: const VaultUri(path: 'subfolder/nested.md'),
                  name: 'nested.md',
                  isDirectory: false,
                  isSupported: true,
                  modifiedAt: DateTime.now(),
                ),
              ],
            ),
            VaultTreeNode(
              uri: const VaultUri(path: 'root_note.md'),
              name: 'root_note.md',
              isDirectory: false,
              isSupported: true,
              modifiedAt: DateTime.now(),
            ),
          ],
        ),
      );

      VaultUri? lastSelectedFolder;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultTreeRepositoryProvider.overrideWith((ref) => mockTree),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                width: 300,
                child: VaultTreeWidget(
                  onFolderSelected: (uri) => lastSelectedFolder = uri,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial state: root is active
      expect(find.text('MyNotebook'), findsOneWidget);

      // 2. Tap subfolder to select it
      await tester.tap(find.text('subfolder'));
      await tester.pumpAndSettle();

      expect(find.text('MyNotebook/subfolder'), findsOneWidget);
      expect(lastSelectedFolder?.path, equals('subfolder'));

      // 3. Right-click on empty space: no popup menu should appear
      final emptySpaceFinder = find.byKey(const Key('vault_tree_empty_space'));
      expect(emptySpaceFinder, findsOneWidget);

      await tester.tap(emptySpaceFinder, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      expect(find.text('New Note in root'), findsNothing);

      // 4. Primary tap the bottom empty space: selects root
      await tester.tap(emptySpaceFinder);
      await tester.pumpAndSettle();

      expect(find.text('MyNotebook'), findsOneWidget);
      expect(lastSelectedFolder?.path, equals(''));
    },
  );

  testWidgets(
    'VaultTreeWidget new note button opens inline creation input instead of modal dialog',
    (WidgetTester tester) async {
      final mockTree = VaultTreeRepository();
      mockTree.setRoot(
        VaultTreeNode(
          uri: const VaultUri(path: ''),
          name: 'MyNotebook',
          isDirectory: true,
          modifiedAt: DateTime.now(),
          children: [
            VaultTreeNode(
              uri: const VaultUri(path: 'sample.md'),
              name: 'sample.md',
              isDirectory: false,
              isSupported: true,
              modifiedAt: DateTime.now(),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultTreeRepositoryProvider.overrideWith((ref) => mockTree),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(height: 600, width: 300, child: VaultTreeWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the New Note icon button in the header
      final newNoteButton = find.byIcon(Icons.note_add_outlined);
      expect(newNoteButton, findsOneWidget);
      await tester.tap(newNoteButton);
      await tester.pumpAndSettle();

      // Verify NO AlertDialog was opened
      expect(find.byType(AlertDialog), findsNothing);

      // Verify inline input row appears in tree with hint 'note.md'
      expect(find.text('note.md'), findsOneWidget);
    },
  );

  testWidgets(
    'VaultTreeWidget rename opens inline rename input replacing node text',
    (WidgetTester tester) async {
      final mockTree = VaultTreeRepository();
      mockTree.setRoot(
        VaultTreeNode(
          uri: const VaultUri(path: ''),
          name: 'MyNotebook',
          isDirectory: true,
          modifiedAt: DateTime.now(),
          children: [
            VaultTreeNode(
              uri: const VaultUri(path: 'sample.md'),
              name: 'sample.md',
              isDirectory: false,
              isSupported: true,
              modifiedAt: DateTime.now(),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultTreeRepositoryProvider.overrideWith((ref) => mockTree),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(height: 600, width: 300, child: VaultTreeWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Right-click on sample.md node
      await tester.tap(find.text('sample.md'), buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      // Tap Rename menu option
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // Verify NO AlertDialog was opened
      expect(find.byType(AlertDialog), findsNothing);

      // An inline TextField should now be active containing 'sample.md'
      final textField = find.byType(TextField);
      expect(textField, findsWidgets); // search bar + inline rename field
    },
  );

  testWidgets(
    'VaultTreeWidget wraps nodes in Draggable and folders/empty space in DragTarget',
    (WidgetTester tester) async {
      final mockTree = VaultTreeRepository();
      mockTree.setRoot(
        VaultTreeNode(
          uri: const VaultUri(path: ''),
          name: 'MyNotebook',
          isDirectory: true,
          modifiedAt: DateTime.now(),
          children: [
            VaultTreeNode(
              uri: const VaultUri(path: 'docs'),
              name: 'docs',
              isDirectory: true,
              modifiedAt: DateTime.now(),
              children: [],
            ),
            VaultTreeNode(
              uri: const VaultUri(path: 'notes.md'),
              name: 'notes.md',
              isDirectory: false,
              isSupported: true,
              modifiedAt: DateTime.now(),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultTreeRepositoryProvider.overrideWith((ref) => mockTree),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(height: 600, width: 300, child: VaultTreeWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify nodes are wrapped in Draggable
      expect(find.byType(Draggable<VaultTreeNode>), findsWidgets);

      // Verify folders and empty space are DragTargets
      expect(find.byType(DragTarget<VaultTreeNode>), findsWidgets);
    },
  );

  testWidgets(
    'VaultTreeWidget canceling inline creation does not create any file',
    (WidgetTester tester) async {
      final mockTree = VaultTreeRepository();
      mockTree.setRoot(
        VaultTreeNode(
          uri: const VaultUri(path: ''),
          name: 'MyNotebook',
          isDirectory: true,
          modifiedAt: DateTime.now(),
          children: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultTreeRepositoryProvider.overrideWith((ref) => mockTree),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(height: 600, width: 300, child: VaultTreeWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap New Note
      await tester.tap(find.byIcon(Icons.note_add_outlined));
      await tester.pumpAndSettle();

      expect(find.text('note.md'), findsOneWidget);

      // Tap empty space to blur/cancel
      final emptySpace = find.byKey(const Key('vault_tree_empty_space'));
      await tester.tap(emptySpace);
      await tester.pumpAndSettle();

      // Input field should be dismissed without creating anything
      expect(find.text('note.md'), findsNothing);
      expect(mockTree.root?.children.isEmpty, isTrue);
    },
  );

  testWidgets(
    'Drawing snapshot files (.excalidraw.png) are not displayed in VaultTreeWidget',
    (WidgetTester tester) async {
      final mockTree = VaultTreeRepository();
      final entries = [
        VaultEntry(
          uri: const VaultUri(path: 'notes.md'),
          kind: VaultEntryKind.file,
          sizeBytes: 100,
          modifiedAt: DateTime.now(),
        ),
        VaultEntry(
          uri: const VaultUri(path: 'diagram.excalidraw'),
          kind: VaultEntryKind.file,
          sizeBytes: 200,
          modifiedAt: DateTime.now(),
        ),
        VaultEntry(
          uri: const VaultUri(path: 'diagram.excalidraw.png'),
          kind: VaultEntryKind.file,
          sizeBytes: 500,
          modifiedAt: DateTime.now(),
        ),
      ];
      mockTree.buildTree(entries, const VaultUri(path: ''), 'MyVault');

      // Verify tree repository filtered out the snapshot file
      expect(
        mockTree.root?.children.any((c) => c.name == 'diagram.excalidraw.png'),
        isFalse,
      );
      expect(
        mockTree.root?.children.any((c) => c.name == 'diagram.excalidraw'),
        isTrue,
      );
      expect(mockTree.root?.children.any((c) => c.name == 'notes.md'), isTrue);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultTreeRepositoryProvider.overrideWith((ref) => mockTree),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(height: 600, width: 300, child: VaultTreeWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Notes and drawings should be visible
      expect(find.text('notes.md'), findsOneWidget);
      expect(find.text('diagram.excalidraw'), findsOneWidget);

      // Drawing snapshot PNG should NOT be shown in the UI
      expect(find.text('diagram.excalidraw.png'), findsNothing);
    },
  );

  testWidgets(
    'VaultTreeWidget displays Topics section in left panel and triggers onFilterChanged on topic tap',
    (WidgetTester tester) async {
      final mockTree = VaultTreeRepository();
      mockTree.setRoot(
        VaultTreeNode(
          uri: const VaultUri(path: ''),
          name: 'MyVault',
          isDirectory: true,
          modifiedAt: DateTime.now(),
          children: [
            VaultTreeNode(
              uri: const VaultUri(path: 'welcome.md'),
              name: 'welcome.md',
              isDirectory: false,
              isSupported: true,
              modifiedAt: DateTime.now(),
            ),
          ],
        ),
      );

      final topic = TagSummary(
        slug: 'deepmind',
        label: 'DeepMind',
        count: 3,
        color: Colors.cyan,
        occurrences: [],
      );

      ScrollFilterMode activeMode = ScrollFilterMode.all;
      String? activeTopic;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultTreeRepositoryProvider.overrideWith((ref) => mockTree),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                width: 300,
                child: VaultTreeWidget(
                  tagSummaries: [topic],
                  filterMode: activeMode,
                  activeTagFilter: activeTopic,
                  onFilterChanged: (mode, tag) {
                    activeMode = mode;
                    activeTopic = tag;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify TOPICS header is rendered in left panel
      expect(find.text('TOPICS'), findsOneWidget);
      expect(find.text('DeepMind'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Tap the topic tile
      await tester.tap(find.text('DeepMind'));
      expect(activeMode, equals(ScrollFilterMode.customTag));
      expect(activeTopic, equals('deepmind'));
    },
  );

  testWidgets(
    'VaultTreeWidget inline rename shows VS Code style row and cancels on Escape',
    (WidgetTester tester) async {
      final mockTree = VaultTreeRepository();
      mockTree.setRoot(
        VaultTreeNode(
          uri: const VaultUri(path: ''),
          name: 'MyNotebook',
          isDirectory: true,
          modifiedAt: DateTime.now(),
          children: [
            VaultTreeNode(
              uri: const VaultUri(path: 'sample.md'),
              name: 'sample.md',
              isDirectory: false,
              isSupported: true,
              modifiedAt: DateTime.now(),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultTreeRepositoryProvider.overrideWith((ref) => mockTree),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(height: 600, width: 300, child: VaultTreeWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Right-click on sample.md node
      await tester.tap(find.text('sample.md'), buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      // Tap Rename
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // Find the inline rename textfield (with sample.md initial text)
      final renameField = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text == 'sample.md',
      );
      expect(renameField, findsOneWidget);

      // Cancel with Escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Inline rename row is dismissed and sample.md restored
      expect(renameField, findsNothing);
      expect(find.text('sample.md'), findsOneWidget);
    },
  );

  testWidgets(
    'VaultTreeController persists expandedPaths and selectedFolderUri across widget recreations',
    (WidgetTester tester) async {
      final mockTree = VaultTreeRepository();
      mockTree.setRoot(
        VaultTreeNode(
          uri: const VaultUri(path: ''),
          name: 'MyNotebook',
          isDirectory: true,
          modifiedAt: DateTime.now(),
          children: [
            VaultTreeNode(
              uri: const VaultUri(path: 'docs'),
              name: 'docs',
              isDirectory: true,
              modifiedAt: DateTime.now(),
              children: [
                VaultTreeNode(
                  uri: const VaultUri(path: 'docs/api'),
                  name: 'api',
                  isDirectory: true,
                  modifiedAt: DateTime.now(),
                  children: [
                    VaultTreeNode(
                      uri: const VaultUri(path: 'docs/api/endpoints.md'),
                      name: 'endpoints.md',
                      isDirectory: false,
                      isSupported: true,
                      modifiedAt: DateTime.now(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      final controller = VaultTreeController();

      // 1. Initial build with controller
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultTreeRepositoryProvider.overrideWith((ref) => mockTree),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                width: 300,
                child: VaultTreeWidget(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('docs'), findsOneWidget);
      expect(find.text('api'), findsNothing);

      // 2. Expand 'docs'
      await tester.tap(find.text('docs'));
      await tester.pumpAndSettle();

      expect(find.text('api'), findsOneWidget);
      expect(controller.expandedPaths.contains('docs'), isTrue);
      expect(controller.selectedFolderUri?.path, equals('docs'));

      // 3. Recreate VaultTreeWidget (simulating drawer close and reopen)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultTreeRepositoryProvider.overrideWith((ref) => mockTree),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                width: 300,
                child: VaultTreeWidget(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 'docs' should STILL be expanded, so 'api' is visible
      expect(find.text('api'), findsOneWidget);
    },
  );

  testWidgets(
    'VaultTreeWidget automatically expands all ancestor directories of selectedPath',
    (WidgetTester tester) async {
      final mockTree = VaultTreeRepository();
      mockTree.setRoot(
        VaultTreeNode(
          uri: const VaultUri(path: ''),
          name: 'MyNotebook',
          isDirectory: true,
          modifiedAt: DateTime.now(),
          children: [
            VaultTreeNode(
              uri: const VaultUri(path: 'level1'),
              name: 'level1',
              isDirectory: true,
              modifiedAt: DateTime.now(),
              children: [
                VaultTreeNode(
                  uri: const VaultUri(path: 'level1/level2'),
                  name: 'level2',
                  isDirectory: true,
                  modifiedAt: DateTime.now(),
                  children: [
                    VaultTreeNode(
                      uri: const VaultUri(path: 'level1/level2/deep.md'),
                      name: 'deep.md',
                      isDirectory: false,
                      isSupported: true,
                      modifiedAt: DateTime.now(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultTreeRepositoryProvider.overrideWith((ref) => mockTree),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                width: 300,
                child: VaultTreeWidget(selectedPath: 'level1/level2/deep.md'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both level1 and level2 should be expanded, so deep.md is visible
      expect(find.text('level1'), findsOneWidget);
      expect(find.text('level2'), findsOneWidget);
      expect(find.text('deep.md'), findsOneWidget);
    },
  );

  testWidgets(
    'VaultTreeWidget renders root and subfolders with action buttons',
    (WidgetTester tester) async {
      final mockTree = VaultTreeRepository();
      mockTree.setRoot(
        VaultTreeNode(
          uri: const VaultUri(path: ''),
          name: 'MyNotebook',
          isDirectory: true,
          modifiedAt: DateTime.now(),
          children: [
            VaultTreeNode(
              uri: const VaultUri(path: 'subfolder'),
              name: 'subfolder',
              isDirectory: true,
              modifiedAt: DateTime.now(),
              children: [
                VaultTreeNode(
                  uri: const VaultUri(path: 'subfolder/nested.md'),
                  name: 'nested.md',
                  isDirectory: false,
                  isSupported: true,
                  modifiedAt: DateTime.now(),
                ),
              ],
            ),
            VaultTreeNode(
              uri: const VaultUri(path: 'root_note.md'),
              name: 'root_note.md',
              isDirectory: false,
              isSupported: true,
              modifiedAt: DateTime.now(),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultTreeRepositoryProvider.overrideWith((ref) => mockTree),
          ],
          child: const MaterialApp(home: Scaffold(body: VaultTreeWidget())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MyNotebook'), findsOneWidget);
      expect(find.text('subfolder'), findsOneWidget);
      expect(find.text('root_note.md'), findsOneWidget);

      // Tap subfolder to expand and select it
      await tester.tap(find.text('subfolder'));
      await tester.pumpAndSettle();

      // Should now show active target folder in header
      expect(find.text('MyNotebook/subfolder'), findsOneWidget);
      // Should also reveal nested file
      expect(find.text('nested.md'), findsOneWidget);

      // Verify no inline '+' or '...' action buttons on directory rows
      expect(find.byIcon(Icons.more_horiz), findsNothing);
    },
  );
}
