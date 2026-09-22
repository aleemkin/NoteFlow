import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/features/document/domain/models.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/features/editor/presentation/outline/outline_inspector_panel.dart';
import 'package:noteflow/features/vault/vault.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testFolder = VaultTreeNode(
    uri: const VaultUri(path: 'personal_notes'),
    name: 'personal_notes',
    isDirectory: true,
    modifiedAt: DateTime.now(),
  );

  final unit1 = const AtomicUnit(
    id: 'u1',
    docUri: VaultUri(path: 'personal_notes/intro.md'),
    title: 'Introduction to Architecture',
    kind: AtomicUnitKind.document,
    rawMarkdown: '# Introduction to Architecture',
    targetBlockId: 'b1',
  );

  final unit2 = const AtomicUnit(
    id: 'u2',
    docUri: VaultUri(path: 'personal_notes/intro.md'),
    title: 'Design Philosophy',
    kind: AtomicUnitKind.heading,
    headingLevel: 2,
    rawMarkdown: '## Design Philosophy',
    targetBlockId: 'b2',
  );

  final unit3 = const AtomicUnit(
    id: 'u3',
    docUri: VaultUri(path: 'personal_notes/diagram.excalidraw'),
    title: 'System Topology Diagram',
    kind: AtomicUnitKind.drawing,
    drawingPath: 'personal_notes/diagram.excalidraw',
    rawMarkdown: '@@drawing ./diagram.excalidraw #d1',
    targetBlockId: 'b3',
  );

  testWidgets(
    'OutlineInspectorPanel renders outline mode with clean tiles and tap-to-scroll',
    (WidgetTester tester) async {
      AtomicUnit? selectedUnit;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineInspectorPanel(
              folderNode: testFolder,
              units: [unit1, unit2, unit3],
              onUnitSelected: (u) => selectedUnit = u,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header title and badges
      expect(find.text('Document Outline'), findsOneWidget);
      expect(find.text('3'), findsAtLeastNWidgets(1)); // 3 units badge

      // Verify all 3 titles are rendered
      expect(find.text('Introduction to Architecture'), findsOneWidget);
      expect(find.text('Design Philosophy'), findsOneWidget);
      expect(find.text('System Topology Diagram'), findsOneWidget);

      // Verify kind badges
      expect(find.text('DOC'), findsOneWidget);
      expect(find.text('H2'), findsOneWidget);
      expect(find.text('DRAW'), findsOneWidget);

      // Verify reorder banner is NOT visible in default navigation mode
      expect(find.textContaining('Reorder Active'), findsNothing);

      // Tap a tile: should invoke onUnitSelected
      await tester.tap(find.text('Design Philosophy'));
      expect(selectedUnit, equals(unit2));
    },
  );

  testWidgets(
    'OutlineInspectorPanel toggles Reorder Mode with whole tile touch target and preserves tap-to-scroll',
    (WidgetTester tester) async {
      AtomicUnit? selectedUnit;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineInspectorPanel(
              folderNode: testFolder,
              units: [unit1, unit2, unit3],
              onUnitSelected: (u) => selectedUnit = u,
              onUnitsReordered: (newUnits) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle Reorder Mode by clicking the header swap/reorder icon
      await tester.tap(find.byIcon(Icons.swap_vert_rounded));
      await tester.pumpAndSettle();

      // Verify Reorder banner and indicator appear
      expect(find.textContaining('Reorder Active'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(3));

      // Verify clicking any tile in Reorder Mode STILL scrolls to that position
      selectedUnit = null;
      await tester.tap(find.text('System Topology Diagram'));
      expect(selectedUnit, equals(unit3));

      // Click 'Done' to exit Reorder Mode
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify Reorder banner disappears and normal mode is restored
      expect(find.textContaining('Reorder Active'), findsNothing);
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);
    },
  );

  testWidgets(
    'OutlineInspectorPanel renders clean Document Outline header without tags tab',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineInspectorPanel(
              folderNode: testFolder,
              units: [unit1, unit2],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Document Outline header is present
      expect(find.text('Document Outline'), findsOneWidget);
      expect(find.text('2'), findsAtLeastNWidgets(1));

      // Verify Tags tab is NOT present in OutlineInspectorPanel
      expect(find.text('Tags'), findsNothing);
    },
  );

  testWidgets(
    'OutlineInspectorPanel search filter button toggles search bar and filters units',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineInspectorPanel(
              folderNode: testFolder,
              units: [unit1, unit2, unit3],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle search bar on
      await tester.tap(find.byKey(const Key('outline_search_toggle')));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      // Enter query 'Philosophy'
      await tester.enterText(find.byType(TextField), 'Philosophy');
      await tester.pumpAndSettle();

      // Only Design Philosophy should be visible
      expect(find.text('Design Philosophy'), findsOneWidget);
      expect(find.text('Introduction to Architecture'), findsNothing);
      expect(find.text('System Topology Diagram'), findsNothing);

      // Toggle search off
      await tester.tap(find.byKey(const Key('outline_search_toggle')));
      await tester.pumpAndSettle();

      // All units visible again
      expect(find.text('Introduction to Architecture'), findsOneWidget);
      expect(find.text('Design Philosophy'), findsOneWidget);
      expect(find.text('System Topology Diagram'), findsOneWidget);
    },
  );

  testWidgets(
    'OutlineInspectorPanel reorders without modal confirmation dialog',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineInspectorPanel(
              folderNode: testFolder,
              units: [unit1, unit2],
              onUnitsReordered: (newOrder) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to reorder mode
      await tester.tap(find.byIcon(Icons.swap_vert_rounded));
      await tester.pumpAndSettle();

      // Verify no AlertDialog exists before or during reordering
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'OutlineInspectorPanel filters sections and shows clean empty state when no match',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineInspectorPanel(
              folderNode: testFolder,
              units: [unit1, unit2, unit3],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byKey(const Key('outline_search_toggle')));
      await tester.pumpAndSettle();

      // Type query with no matches
      await tester.enterText(find.byType(TextField), 'nonexistent_section_xyz');
      await tester.pumpAndSettle();

      // Clean empty state
      expect(find.text('No matching sections found'), findsOneWidget);

      // Tap clear button 'x'
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // All units restored
      expect(find.text('Introduction to Architecture'), findsOneWidget);
      expect(find.text('Design Philosophy'), findsOneWidget);
      expect(find.text('System Topology Diagram'), findsOneWidget);
    },
  );
}
