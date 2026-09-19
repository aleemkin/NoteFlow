import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/vault/vault.dart';

void main() {
  group('VaultTree Structure & Repository Tests', () {
    test('VaultTreeNode.sortedChildren keeps directories first', () {
      final parent = VaultTreeNode(
        uri: const VaultUri(path: 'folder'),
        name: 'folder',
        isDirectory: true,
        modifiedAt: DateTime.now(),
        children: [
          VaultTreeNode(
            uri: const VaultUri(path: 'folder/z_file.md'),
            name: 'z_file.md',
            isDirectory: false,
            isSupported: true,
            modifiedAt: DateTime.now(),
          ),
          VaultTreeNode(
            uri: const VaultUri(path: 'folder/sub'),
            name: 'sub',
            isDirectory: true,
            modifiedAt: DateTime.now(),
          ),
          VaultTreeNode(
            uri: const VaultUri(path: 'folder/a_file.md'),
            name: 'a_file.md',
            isDirectory: false,
            isSupported: true,
            modifiedAt: DateTime.now(),
          ),
        ],
      );

      final sorted = parent.sortedChildren;
      expect(sorted[0].name, 'sub');
      expect(sorted[1].name, 'a_file.md');
      expect(sorted[2].name, 'z_file.md');
    });

    test(
      'VaultTreeRepository.buildTree filters out hidden files and directories starting with .',
      () {
        final repo = VaultTreeRepository();
        final entries = [
          VaultEntry(
            uri: const VaultUri(path: 'normal_note.md'),
            kind: VaultEntryKind.file,
            modifiedAt: DateTime.now(),
          ),
          VaultEntry(
            uri: const VaultUri(path: '.kn/sequence.json'),
            kind: VaultEntryKind.file,
            modifiedAt: DateTime.now(),
          ),
          VaultEntry(
            uri: const VaultUri(path: '.git/config'),
            kind: VaultEntryKind.file,
            modifiedAt: DateTime.now(),
          ),
        ];

        repo.buildTree(entries, const VaultUri(path: ''), 'VaultRoot');
        final root = repo.root;

        expect(root, isNotNull);
        expect(root!.children.any((c) => c.name == 'normal_note.md'), isTrue);
        expect(root.children.any((c) => c.name.startsWith('.')), isFalse);
        expect(
          repo.allSupportedFiles.any((f) => f.uri.path.contains('.kn')),
          isFalse,
        );
      },
    );
  });
}
