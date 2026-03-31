import 'dart:typed_data';
import 'dart:convert';

import 'package:noteflow/core/utils/utils.dart';
import 'package:noteflow/core/platform/platform.dart';

import 'vault_manager.dart';
import 'vault_scanner.dart';

/// High-level vault file/folder operations (create, rename, move, delete).
class VaultOperationService {
  final VaultManager manager;

  VaultOperationService({required this.manager});

  VaultFileSystem get _fs {
    final fs = manager.fileSystem;
    if (fs == null) throw StateError('No vault open');
    return fs;
  }

  /// Create a new Markdown note with frontmatter ID.
  Future<VaultUri> createNote({
    required String name,
    required VaultUri parentDir,
  }) async {
    final fileName = name.endsWith('.md') ? name : '$name.md';
    final uri = parentDir.isRoot
        ? VaultUri(path: fileName)
        : VaultUri(path: '${parentDir.path}/$fileName');

    final docId = IdGenerator.documentId();
    final content =
        '''---
kn:
  id: $docId
  schema: 1
---

# $name
''';

    await _fs.writeBytes(
      uri,
      Uint8List.fromList(utf8.encode(content)),
      const MustNotExist(),
    );

    await _rescan();
    return uri;
  }

  /// Create a new folder.
  Future<VaultUri> createFolder({
    required String name,
    required VaultUri parentDir,
  }) async {
    final uri = parentDir.isRoot
        ? VaultUri(path: name)
        : VaultUri(path: '${parentDir.path}/$name');

    await _fs.createDirectory(uri);
    await _rescan();
    return uri;
  }

  /// Rename a file or folder.
  Future<VaultUri> rename({
    required VaultUri uri,
    required String newName,
  }) async {
    final dir = uri.directory;
    final newPath = dir.isEmpty ? newName : '$dir/$newName';
    final newUri = VaultUri(path: newPath);

    await _fs.move(uri, newUri);
    await _rescan();
    return newUri;
  }

  /// Move a file or folder to a new parent directory.
  Future<VaultUri> move({
    required VaultUri uri,
    required VaultUri newParentDir,
  }) async {
    final name = uri.path.split('/').last;
    final newPath = newParentDir.isRoot ? name : '${newParentDir.path}/$name';
    if (newPath == uri.path) return uri;
    final newUri = VaultUri(path: newPath);

    await _fs.move(uri, newUri);
    await _rescan();
    return newUri;
  }

  /// Delete a file or folder.
  Future<void> delete(VaultUri uri) async {
    await _fs.delete(uri);
    await _rescan();
  }

  /// Save content to a file.
  Future<void> saveFile(VaultUri uri, String content) async {
    await _fs.writeBytes(
      uri,
      Uint8List.fromList(utf8.encode(content)),
      const NoPrecondition(),
    );
  }

  Future<void> _rescan() async {
    final vault = manager.currentVault;
    if (vault == null) return;
    final scanner = VaultScanner(fileSystem: _fs);
    final entries = await scanner.scanVault(const VaultUri(path: ''));
    manager.treeRepository.buildTree(
      entries,
      const VaultUri(path: ''),
      vault.displayName,
    );
  }
}
