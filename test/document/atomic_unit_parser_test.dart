import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/features/document/document.dart';
import 'package:noteflow/core/platform/vault_uri.dart';

void main() {
  group('AtomicUnitParser Tests', () {
    test(
      'parseUnits extracts headings, drawings, and sections with raw markdown',
      () {
        const text = '''---
kn:
  id: doc1
---

# Title One
Introductory text.

@@drawing ./diagram_1.excalidraw #draw1 {minHeight=260}
@@

## Section Two
Content under section two.
''';

        final doc = DocumentParser.parse(
          bytes: Uint8List.fromList(utf8.encode(text)),
          uri: const VaultUri(path: 'note1.md'),
        );

        final units = AtomicUnitParser.parseUnits(doc, text);
        expect(units.length, 3);

        expect(units[0].kind, AtomicUnitKind.document);
        expect(units[0].title, 'Title One');
        expect(
          units[0].rawMarkdown,
          contains('# Title One\nIntroductory text.'),
        );

        expect(units[1].kind, AtomicUnitKind.drawing);
        expect(units[1].title, 'Diagram: diagram_1.excalidraw');
        expect(
          units[1].rawMarkdown,
          contains('@@drawing ./diagram_1.excalidraw'),
        );

        expect(units[2].kind, AtomicUnitKind.heading);
        expect(units[2].title, 'Section Two');
        expect(units[2].headingLevel, 2);
        expect(
          units[2].rawMarkdown,
          contains('## Section Two\nContent under section two.'),
        );
      },
    );

    test(
      'redistributeUnitsToFileContents moves bottom-most unit to top of first file',
      () {
        const doc1Text = '# Doc 1\nContent 1';
        const doc2Text =
            '## Section 2\nContent 2\n\n@@drawing ./bottom_diagram.excalidraw #d2\n@@';

        final doc1 = DocumentParser.parse(
          bytes: Uint8List.fromList(utf8.encode(doc1Text)),
          uri: const VaultUri(path: 'doc1.md'),
        );
        final doc2 = DocumentParser.parse(
          bytes: Uint8List.fromList(utf8.encode(doc2Text)),
          uri: const VaultUri(path: 'doc2.md'),
        );

        final units = AtomicUnitParser.parseFolderUnits([doc1, doc2]);
        // units: [0: Doc 1, 1: Section 2, 2: bottom_diagram]
        expect(units.length, 3);
        expect(units.last.title, 'Diagram: bottom_diagram.excalidraw');

        // Move bottom-most unit (index 2) to the very top (index 0)
        final reordered = [units[2], units[0], units[1]];

        final fileContents = AtomicUnitParser.redistributeUnitsToFileContents(
          units: reordered,
          originalFilePaths: ['doc1.md', 'doc2.md'],
          originalFrontmatters: {'doc1.md': '', 'doc2.md': ''},
        );

        // doc1.md should now have the diagram at top + Doc 1
        expect(
          fileContents['doc1.md'],
          contains('@@drawing ./bottom_diagram.excalidraw'),
        );
        expect(fileContents['doc1.md'], contains('# Doc 1\nContent 1'));

        // doc2.md should only have Section 2 (diagram removed)
        expect(fileContents['doc2.md'], contains('## Section 2\nContent 2'));
        expect(fileContents['doc2.md'], isNot(contains('bottom_diagram')));
      },
    );

    test(
      'redistributeUnitsToFileContents prioritizes previous file last section when moved in between',
      () {
        final uA = const AtomicUnit(
          id: '1',
          docUri: VaultUri(path: 'file1.md'),
          title: 'A',
          kind: AtomicUnitKind.heading,
          rawMarkdown: '## A',
          targetBlockId: 't1',
        );
        final uB = const AtomicUnit(
          id: '2',
          docUri: VaultUri(path: 'file1.md'),
          title: 'B',
          kind: AtomicUnitKind.heading,
          rawMarkdown: '## B',
          targetBlockId: 't2',
        );
        final uX = const AtomicUnit(
          id: '3',
          docUri: VaultUri(path: 'file2.md'),
          title: 'X',
          kind: AtomicUnitKind.drawing,
          rawMarkdown: '@@drawing ./diag.excalidraw\n@@',
          targetBlockId: 't3',
        );
        final uC = const AtomicUnit(
          id: '4',
          docUri: VaultUri(path: 'file2.md'),
          title: 'C',
          kind: AtomicUnitKind.heading,
          rawMarkdown: '## C',
          targetBlockId: 't4',
        );

        // Reordered list where X is placed between B (last of file1) and C (first of file2)
        final reordered = [uA, uB, uX, uC];

        final fileContents = AtomicUnitParser.redistributeUnitsToFileContents(
          units: reordered,
          originalFilePaths: ['file1.md', 'file2.md'],
          originalFrontmatters: {'file1.md': '', 'file2.md': ''},
        );

        // X should be added to file1.md (previous file)
        expect(fileContents['file1.md'], contains('## A'));
        expect(fileContents['file1.md'], contains('## B'));
        expect(
          fileContents['file1.md'],
          contains('@@drawing ./diag.excalidraw'),
        );

        // file2.md should only contain C
        expect(fileContents['file2.md'], contains('## C'));
        expect(fileContents['file2.md'], isNot(contains('diag.excalidraw')));
      },
    );

    test(
      'redistributeUnitsToFileContents marks empty files for deletion when all content moved',
      () {
        final uA = const AtomicUnit(
          id: '1',
          docUri: VaultUri(path: 'file1.md'),
          title: 'Doc 1 Title',
          kind: AtomicUnitKind.document,
          headingLevel: 1,
          rawMarkdown: '# Doc 1 Title',
          targetBlockId: 't1',
        );
        final uC = const AtomicUnit(
          id: '3',
          docUri: VaultUri(path: 'file1.md'),
          title: 'C',
          kind: AtomicUnitKind.heading,
          headingLevel: 2,
          rawMarkdown: '## C',
          targetBlockId: 't3',
        );
        final uB = const AtomicUnit(
          id: '2',
          docUri: VaultUri(path: 'file2.md'),
          title: 'B',
          kind: AtomicUnitKind.heading,
          headingLevel: 2,
          rawMarkdown: '## B',
          targetBlockId: 't2',
        );

        // uB (from file2) moved in between uA and uC in file1
        final reordered = [uA, uB, uC];

        final fileContents = AtomicUnitParser.redistributeUnitsToFileContents(
          units: reordered,
          originalFilePaths: ['file1.md', 'file2.md'],
          originalFrontmatters: {'file1.md': '', 'file2.md': ''},
        );

        expect(fileContents['file1.md'], contains('# Doc 1 Title'));
        expect(fileContents['file1.md'], contains('## B'));
        expect(fileContents['file1.md'], contains('## C'));

        // file2.md has 0 remaining units -> null (delete)
        expect(fileContents['file2.md'], isNull);
      },
    );
  });
}
