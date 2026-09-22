import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/features/search/presentation/search_widget.dart';

void main() {
  group('SearchWidget Tests', () {
    testWidgets('SearchWidget opens Spotlight dialog on tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: SearchWidget(onResultSelected: (_) {})),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Search notes...'), findsOneWidget);
      expect(find.text('Ctrl+K'), findsOneWidget);

      // Tap on search trigger
      await tester.tap(find.text('Search notes...'));
      await tester.pumpAndSettle();

      // Spotlight dialog should now be visible
      expect(find.byType(SpotlightSearchDialog), findsOneWidget);
      expect(find.text('Noteflow Spotlight'), findsOneWidget);
    });

    testWidgets('SearchWidget compact mode renders search icon button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SearchWidget(compact: true, onResultSelected: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}
