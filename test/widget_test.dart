import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/app/notebook_app.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/vault/vault.dart';

void main() {
  testWidgets(
    'App starts into welcome screen when no past vault exists, opens sample vault, and closes vault',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      VaultStateStorage.testOverrideLastPath = null;
      VaultStateStorage.disablePersistenceForTest = true;
      LocalPathVaultFileSystem.disableWatcherForTest = true;

      await tester.pumpWidget(const ProviderScope(child: NotebookApp()));
      await tester.pumpAndSettle();

      // 1. On fresh launch with no past vault, First / Welcome Screen is displayed
      expect(find.text('Noteflow'), findsAtLeastNWidgets(1));
      expect(find.text('Explore Sample Vault'), findsOneWidget);
      expect(find.text('Choose Folder'), findsOneWidget);
      // Notebook WindowChrome controls must NOT be present
      expect(find.text('Search...'), findsNothing);

      // 2. Tapping "Explore Sample Vault" unpacks and opens the sample vault on disk
      await tester.tap(find.text('Explore Sample Vault'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify notebook interface is loaded with full WindowChrome
      expect(find.text('Sample Vault'), findsWidgets);
      expect(find.textContaining('Welcome to noteflow'), findsWidgets);
      expect(find.text('Search...'), findsOneWidget);

      // 3. Opening the vault menu and selecting "Close Vault" returns to the First / Welcome Screen
      await tester.tap(find.byTooltip('Menu & Vault Options'));
      await tester.pumpAndSettle();

      expect(find.text('Close Vault'), findsOneWidget);
      await tester.tap(find.text('Close Vault'));
      await tester.pumpAndSettle();

      // Verify returned to First / Welcome Screen
      expect(find.text('Explore Sample Vault'), findsOneWidget);
      expect(find.text('Search...'), findsNothing);
    },
  );
}
