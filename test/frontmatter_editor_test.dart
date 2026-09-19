import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/features/document/parsing/frontmatter_parser.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/shell/presentation/home_screen.dart';
import 'package:noteflow/features/editor/presentation/widgets/dual_pane_editor.dart';
import 'package:noteflow/features/vault/vault.dart';

void main() {
  group('FrontmatterParser extract and combine', () {
    test('extracts kn frontmatter block and body', () {
      const text = '''---
kn:
  id: doc_12345
  schema: 1
---

# My Note Title

Paragraph content here.''';

      final fm = FrontmatterParser.extractFrontmatter(text);
      final body = FrontmatterParser.extractBody(text);

      expect(fm, '''---
kn:
  id: doc_12345
  schema: 1
---''');
      expect(body, '''# My Note Title

Paragraph content here.''');

      final combined = FrontmatterParser.combine(fm, body);
      expect(combined, text);
    });

    test('handles text without frontmatter', () {
      const text = '''# Hello World

Some regular markdown.''';

      final fm = FrontmatterParser.extractFrontmatter(text);
      final body = FrontmatterParser.extractBody(text);

      expect(fm, isEmpty);
      expect(body, text);
      expect(FrontmatterParser.combine(fm, body), text);
    });

    test('handles empty body after frontmatter', () {
      const text = '''---
kn:
  id: doc_999
  schema: 1
---''';

      final fm = FrontmatterParser.extractFrontmatter(text);
      final body = FrontmatterParser.extractBody(text);

      expect(fm, text);
      expect(body, isEmpty);
      expect(FrontmatterParser.combine(fm, body), '$text\n');
    });

    test('handles text without blank line after closing delimiter', () {
      const text = '''---
kn:
  id: doc_111
  schema: 1
---
# Direct Heading''';

      final fm = FrontmatterParser.extractFrontmatter(text);
      final body = FrontmatterParser.extractBody(text);

      expect(fm, '''---
kn:
  id: doc_111
  schema: 1
---''');
      expect(body, '# Direct Heading');
    });

    test('preserves horizontal rule dividers in body text', () {
      const text = '''---
kn:
  id: doc_hr_test
  schema: 1
---

# Section 1

Some text above hr.

---

# Section 2

Some text below hr.''';

      final fm = FrontmatterParser.extractFrontmatter(text);
      final body = FrontmatterParser.extractBody(text);

      expect(fm, contains('id: doc_hr_test'));
      expect(body, contains('# Section 1'));
      expect(body, contains('---'));
      expect(body, contains('# Section 2'));

      final combined = FrontmatterParser.combine(fm, body);
      expect(combined, text);
    });

    test('handles CRLF windows newlines gracefully', () {
      const text =
          "---\r\nkn:\r\n  id: doc_crlf\r\n  schema: 1\r\n---\r\n\r\n# CRLF Heading\r\nBody text";

      final fm = FrontmatterParser.extractFrontmatter(text);
      final body = FrontmatterParser.extractBody(text);

      expect(fm, contains('id: doc_crlf'));
      expect(body, contains('# CRLF Heading'));
    });
  });

  group('Editor frontmatter hiding tests', () {
    setUp(() {
      AppPlatform.overrideIsMobileForTest = false;
      VaultStateStorage.disablePersistenceForTest = true;
      VaultStateStorage.testOverrideLastPath = null;
      LocalPathVaultFileSystem.disableWatcherForTest = true;
    });

    tearDown(() {
      AppPlatform.overrideIsMobileForTest = null;
      VaultStateStorage.disablePersistenceForTest = false;
    });

    testWidgets(
      'DualPaneEditor hides kn frontmatter from raw editor view and preserves on save',
      (tester) async {
        const rawFileContent = '''---
kn:
  id: doc_test_001
  schema: 1
---

# User Note Title

Body of the note.''';

        final fs = MemoryVaultFileSystem();
        fs.seed('note1.md', rawFileContent);
        final treeRepo = VaultTreeRepository();
        final manager = VaultManager(treeRepository: treeRepo);
        await manager.openCustomFileSystem(fs, 'Test Vault');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              vaultTreeRepositoryProvider.overrideWith((ref) => treeRepo),
              vaultManagerProvider.overrideWith((ref) => manager),
              currentVaultProvider.overrideWith((ref) => manager.currentVault),
            ],
            child: const MaterialApp(
              home: Scaffold(body: DualPaneEditor(documentPath: 'note1.md')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // TextField in editor should contain only body, NOT the frontmatter
        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.controller?.text, isNot(contains('kn:')));
        expect(textField.controller?.text, isNot(contains('doc_test_001')));
        expect(textField.controller?.text, isNot(contains('schema: 1')));
        expect(textField.controller?.text, contains('# User Note Title'));
        expect(textField.controller?.text, contains('Body of the note.'));

        // Edit the text
        await tester.enterText(
          textFieldFinder,
          '# Updated Title\n\nNew content.',
        );
        await tester.pump(
          const Duration(milliseconds: 700),
        ); // wait for auto-save debounce

        // Verify file on disk still contains the kn frontmatter!
        final savedBytes = await manager.readFile(VaultUri(path: 'note1.md'));
        final savedText = utf8.decode(savedBytes);
        expect(savedText, contains('kn:'));
        expect(savedText, contains('id: doc_test_001'));
        expect(savedText, contains('schema: 1'));
        expect(savedText, contains('# Updated Title'));
        expect(savedText, contains('New content.'));
      },
    );

    testWidgets(
      'MobileEditorScreen hides kn frontmatter from raw editor and preserves on save',
      (tester) async {
        AppPlatform.overrideIsMobileForTest = true;

        const rawFileContent = '''---
kn:
  id: doc_mobile_002
  schema: 1
---

# Mobile Note Title

Touch writing content.''';

        final fs = MemoryVaultFileSystem();
        fs.seed('mobile_note.md', rawFileContent);
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
            child: const MaterialApp(
              home: Scaffold(
                body: MobileEditorScreen(documentPath: 'mobile_note.md'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.controller?.text, isNot(contains('kn:')));
        expect(textField.controller?.text, isNot(contains('doc_mobile_002')));
        expect(textField.controller?.text, contains('# Mobile Note Title'));

        // Edit text in mobile editor
        await tester.enterText(
          textFieldFinder,
          '# Edited Mobile Note\n\nSaved content.',
        );
        await tester.pump(
          const Duration(milliseconds: 900),
        ); // wait for auto-save debounce

        final savedBytes = await manager.readFile(
          VaultUri(path: 'mobile_note.md'),
        );
        final savedText = utf8.decode(savedBytes);
        expect(savedText, contains('kn:'));
        expect(savedText, contains('id: doc_mobile_002'));
        expect(savedText, contains('# Edited Mobile Note'));
      },
    );
  });

  group('Vault opening destination test', () {
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

    testWidgets('Opening sample vault opens in Notes tab, not Editor tab', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())),
      );
      await tester.pumpAndSettle();

      // Tap Explore Sample Vault
      expect(find.text('Explore Sample Vault'), findsOneWidget);
      await tester.tap(find.text('Explore Sample Vault'));
      await tester.pumpAndSettle();

      // Must open in Notes tab (MobileReadingScreen), NOT in Editor tab
      expect(find.byType(MobileReadingScreen), findsOneWidget);
      expect(find.byType(MobileEditorScreen), findsNothing);
    });
  });
}
