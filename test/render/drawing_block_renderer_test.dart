import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/render/render.dart';
import 'package:noteflow/features/vault/vault.dart';

void main() {
  group('DrawingBlockRenderer Tests', () {
    testWidgets(
      'DrawingBlockRenderer renders compact card for empty diagram and triggers tap callback',
      (WidgetTester tester) async {
        final fs = MemoryVaultFileSystem();
        fs.seed(
          'diagram.excalidraw',
          '{"type":"excalidraw","version":2,"elements":[]}',
        );
        final treeRepo = VaultTreeRepository();
        final manager = VaultManager(treeRepository: treeRepo);
        await manager.openCustomFileSystem(fs, 'Test Vault');

        bool opened = false;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              vaultTreeRepositoryProvider.overrideWith((ref) => treeRepo),
              vaultManagerProvider.overrideWith((ref) => manager),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: DrawingBlockRenderer(
                  drawingPath: 'diagram.excalidraw',
                  onOpenEditor: () {
                    opened = true;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('diagram.excalidraw'), findsOneWidget);
        expect(find.text('Empty diagram • Tap to open editor'), findsOneWidget);
        expect(find.text('Draw'), findsOneWidget);

        final size = tester.getSize(find.byType(DrawingBlockRenderer));
        expect(size.height, lessThan(100.0));

        await tester.tap(find.text('diagram.excalidraw'));
        await tester.pumpAndSettle();
        expect(opened, isTrue);
      },
    );
  });
}
