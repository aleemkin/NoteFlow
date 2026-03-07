import 'dart:async';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'vault_change.dart';
import 'vault_entry.dart';
import 'vault_file_system.dart';
import 'vault_uri.dart';
import 'write_precondition.dart';

/// In-memory implementation of [VaultFileSystem] for testing.
class MemoryVaultFileSystem implements VaultFileSystem {
  final Map<String, Uint8List> _files = {};
  final Set<String> _directories = {''};
  final StreamController<VaultChangeBatch> _changeController =
      StreamController<VaultChangeBatch>.broadcast();

  /// Seed the filesystem with initial content for testing.
  void seed(String path, String content) {
    seedBytes(path, Uint8List.fromList(content.codeUnits));
  }

  /// Seed the filesystem with raw binary bytes for testing.
  void seedBytes(String path, Uint8List bytes) {
    _files[path] = bytes;
    // Ensure parent directories exist
    var dir = p.posix.dirname(path);
    while (dir.isNotEmpty && dir != '.') {
      _directories.add(dir);
      dir = p.posix.dirname(dir);
    }
  }

  @override
  Future<List<VaultEntry>> listTree(VaultUri root) async {
    final entries = <VaultEntry>[];
    final prefix = root.isRoot ? '' : '${root.path}/';

    for (final dir in _directories) {
      if (dir.isEmpty) continue;
      if (root.isRoot || dir.startsWith(prefix)) {
        entries.add(
          VaultEntry(
            uri: VaultUri(path: dir),
            kind: VaultEntryKind.directory,
            modifiedAt: DateTime.now(),
          ),
        );
      }
    }

    for (final path in _files.keys) {
      if (root.isRoot || path.startsWith(prefix)) {
        entries.add(
          VaultEntry(
            uri: VaultUri(path: path),
            kind: VaultEntryKind.file,
            sizeBytes: _files[path]!.length,
            modifiedAt: DateTime.now(),
          ),
        );
      }
    }

    return entries;
  }

  @override
  Future<Uint8List> readBytes(VaultUri uri) async {
    final data = _files[uri.path];
    if (data == null) {
      throw StateError('File not found: ${uri.path}');
    }
    return Uint8List.fromList(data);
  }

  @override
  Future<void> writeBytes(
    VaultUri uri,
    Uint8List bytes,
    WritePrecondition precondition,
  ) async {
    switch (precondition) {
      case NoPrecondition():
        break;
      case MustNotExist():
        if (_files.containsKey(uri.path)) {
          throw StateError('File already exists: ${uri.path}');
        }
      case MustMatchHash():
        final existing = _files[uri.path];
        if (existing != null) {
          final hash = existing.length.toString();
          if (hash != precondition.expectedHash) {
            throw StateError('File hash mismatch');
          }
        }
    }

    _files[uri.path] = bytes;
    _emitChange(VaultChangeType.modified, uri);
  }

  @override
  Future<void> createDirectory(VaultUri uri) async {
    _directories.add(uri.path);
  }

  @override
  Future<void> move(VaultUri from, VaultUri to) async {
    if (_files.containsKey(from.path)) {
      _files[to.path] = _files.remove(from.path)!;
      _emitChange(VaultChangeType.moved, to);
    } else if (_directories.contains(from.path)) {
      _directories.remove(from.path);
      _directories.add(to.path);
      final fromPrefix = '${from.path}/';
      final toPrefix = '${to.path}/';
      final filesToMove = _files.keys
          .where((k) => k.startsWith(fromPrefix))
          .toList();
      for (final k in filesToMove) {
        final newKey = toPrefix + k.substring(fromPrefix.length);
        _files[newKey] = _files.remove(k)!;
      }
      final dirsToMove = _directories
          .where((d) => d.startsWith(fromPrefix))
          .toList();
      for (final d in dirsToMove) {
        _directories.remove(d);
        _directories.add(toPrefix + d.substring(fromPrefix.length));
      }
    }
  }

  @override
  Future<void> delete(VaultUri uri) async {
    _files.remove(uri.path);
    _directories.remove(uri.path);
    _emitChange(VaultChangeType.deleted, uri);
  }

  @override
  Stream<VaultChangeBatch> watch(VaultUri root) => _changeController.stream;

  @override
  Future<bool> exists(VaultUri uri) async {
    return _files.containsKey(uri.path) || _directories.contains(uri.path);
  }

  void _emitChange(VaultChangeType type, VaultUri uri) {
    _changeController.add(
      VaultChangeBatch(
        changes: [VaultChange(type: type, uri: uri, timestamp: DateTime.now())],
        timestamp: DateTime.now(),
      ),
    );
  }

  void dispose() {
    _changeController.close();
  }
}
