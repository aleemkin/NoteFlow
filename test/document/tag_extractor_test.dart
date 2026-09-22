import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/features/document/document.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/features/render/render.dart';

void main() {
  group('Tagged Rolls & TagExtractor', () {
    test(
      'extractTags correctly aggregates built-in and custom marks across documents',
      () {
        const md1 = '''
# Note 1

@@imp #mark_1
Crucial security takeaway
@@

Normal text

@@info #mark_2
Reference to DB schema
@@
''';

        const md2 = '''
# Note 2

@@imp #mark_3
Another critical performance metric
@@

@@review #mark_4
Needs code review before merge
@@
''';

        final doc1 = DocumentParser.parse(
          bytes: Uint8List.fromList(utf8.encode(md1)),
          uri: const VaultUri(path: 'note1.md'),
        );
        final doc2 = DocumentParser.parse(
          bytes: Uint8List.fromList(utf8.encode(md2)),
          uri: const VaultUri(path: 'note2.md'),
        );

        final tags = TagExtractor.extractTags([doc1, doc2]);

        expect(tags.length, 3);
        // Sorted: imp first, info second, then custom tags
        expect(tags[0].slug, 'imp');
        expect(tags[0].count, 2);
        expect(tags[0].occurrences.length, 2);

        expect(tags[1].slug, 'info');
        expect(tags[1].count, 1);
        expect(tags[1].occurrences.first.docTitle, 'Note 1');

        expect(tags[2].slug, 'review');
        expect(tags[2].count, 1);
        expect(tags[2].occurrences.first.docTitle, 'Note 2');
      },
    );

    test(
      'generateRollMarkdown generates structured markdown with headers for imp roll',
      () {
        const md = '''
# Systems Architecture

@@imp #sec_1
Zero-trust authentication enforced at edge
@@

Regular background info

@@imp #sec_2
Failover replication in 3 regions
@@
''';

        final doc = DocumentParser.parse(
          bytes: Uint8List.fromList(utf8.encode(md)),
          uri: const VaultUri(path: 'arch.md'),
        );

        final rollMd = TagExtractor.generateRollMarkdown(
          docs: [doc],
          filterMode: ScrollFilterMode.importantOnly,
          folderName: 'Architecture',
        );

        expect(rollMd, contains('# Key Highlights'));
        expect(rollMd, contains('## 📄 Systems Architecture (`arch.md`)'));
        expect(rollMd, contains('@@imp #sec_1'));
        expect(rollMd, contains('Zero-trust authentication enforced at edge'));
        expect(rollMd, contains('@@imp #sec_2'));
        expect(rollMd, isNot(contains('Regular background info')));
      },
    );

    test('generateRollMarkdown handles custom tag filter', () {
      const md = '''
# API Specs

@@review #r1
Ensure endpoint returns 401 on missing token
@@

@@imp #i1
Rate limiting: 100 req/min
@@
''';

      final doc = DocumentParser.parse(
        bytes: Uint8List.fromList(utf8.encode(md)),
        uri: const VaultUri(path: 'api.md'),
      );

      final reviewRollMd = TagExtractor.generateRollMarkdown(
        docs: [doc],
        filterMode: ScrollFilterMode.customTag,
        activeTagFilter: 'review',
        folderName: 'Specs',
      );

      expect(reviewRollMd, contains('# Review Notes'));
      expect(reviewRollMd, contains('@@review #r1'));
      expect(
        reviewRollMd,
        contains('Ensure endpoint returns 401 on missing token'),
      );
      expect(reviewRollMd, isNot(contains('Rate limiting: 100 req/min')));
    });
  });
}
