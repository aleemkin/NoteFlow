import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import 'vault_change.dart';
import 'vault_entry.dart';
import 'vault_file_system.dart';
import 'vault_uri.dart';
import 'write_precondition.dart';

/// Linux filesystem implementation of [VaultFileSystem].
///
/// Uses dart:io for file operations and the `watcher` package
/// for filesystem change detection.
class LocalPathVaultFileSystem implements VaultFileSystem {
  final String rootPath;

  LocalPathVaultFileSystem({required this.rootPath});

  String _toAbsolute(VaultUri uri) {
    if (uri.isRoot) return rootPath;
    return p.join(rootPath, uri.path);
  }

  VaultUri _toVaultUri(String absolutePath) {
    final relative = p.relative(absolutePath, from: rootPath);
    final normalized = (relative == '.' || relative.isEmpty)
        ? ''
        : relative.replaceAll(r'\', '/');
    return VaultUri(path: normalized);
  }

  @override
  Future<List<VaultEntry>> listTree(VaultUri root) async {
    final dir = Directory(_toAbsolute(root));
    if (!dir.existsSync()) return [];

    final entries = <VaultEntry>[];
    try {
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        final stat = entity.statSync();
        final uri = _toVaultUri(entity.path);
        entries.add(
          VaultEntry(
            uri: uri,
            kind: entity is Directory
                ? VaultEntryKind.directory
                : VaultEntryKind.file,
            sizeBytes: stat.size,
            modifiedAt: stat.modified,
          ),
        );
      }
    } catch (_) {}
    return entries;
  }

  @override
  Future<Uint8List> readBytes(VaultUri uri) async {
    final file = File(_toAbsolute(uri));
    if (!file.existsSync()) return Uint8List(0);
    return file.readAsBytesSync();
  }

  @override
  Future<void> writeBytes(
    VaultUri uri,
    Uint8List bytes,
    WritePrecondition precondition,
  ) async {
    final filePath = _toAbsolute(uri);
    final file = File(filePath);

    switch (precondition) {
      case NoPrecondition():
        break;
      case MustNotExist():
        if (await file.exists()) {
          throw StateError('File already exists: ${uri.path}');
        }
      case MustMatchHash():
        if (await file.exists()) {
          final existing = await file.readAsBytes();
          final hash = existing.length.toString();
          if (hash != precondition.expectedHash) {
            throw StateError('File hash mismatch for: ${uri.path}');
          }
        }
    }

    // Atomic write: temp file -> rename
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final tempFile = File('$filePath.tmp');
    await tempFile.writeAsBytes(bytes, flush: true);
    await tempFile.rename(filePath);
  }

  @override
  Future<void> createDirectory(VaultUri uri) async {
    await Directory(_toAbsolute(uri)).create(recursive: true);
  }

  @override
  Future<void> move(VaultUri from, VaultUri to) async {
    final fromPath = _toAbsolute(from);
    final toPath = _toAbsolute(to);
    final type = await FileSystemEntity.type(fromPath);

    // Ensure target parent exists
    await Directory(p.dirname(toPath)).create(recursive: true);

    if (type == FileSystemEntityType.directory) {
      await Directory(fromPath).rename(toPath);
    } else {
      await File(fromPath).rename(toPath);
    }
  }

  @override
  Future<void> delete(VaultUri uri) async {
    final absPath = _toAbsolute(uri);
    final type = await FileSystemEntity.type(absPath);
    if (type == FileSystemEntityType.directory) {
      await Directory(absPath).delete(recursive: true);
    } else if (type != FileSystemEntityType.notFound) {
      await File(absPath).delete();
    }
  }

  /// Optional test flag to disable background directory watchers during widget tests
  /// so that recurring watcher timers do not cause pumpAndSettle timeouts.
  static bool disableWatcherForTest = false;

  @override
  Stream<VaultChangeBatch> watch(VaultUri root) {
    if (disableWatcherForTest) {
      return const Stream<VaultChangeBatch>.empty();
    }
    final watcher = DirectoryWatcher(_toAbsolute(root));
    return watcher.events.map((event) {
      final changeType = switch (event.type) {
        ChangeType.ADD => VaultChangeType.created,
        ChangeType.MODIFY => VaultChangeType.modified,
        ChangeType.REMOVE => VaultChangeType.deleted,
        _ => VaultChangeType.modified,
      };
      return VaultChangeBatch(
        changes: [
          VaultChange(
            type: changeType,
            uri: _toVaultUri(event.path),
            timestamp: DateTime.now(),
          ),
        ],
        timestamp: DateTime.now(),
      );
    });
  }

  @override
  Future<bool> exists(VaultUri uri) async {
    final absPath = _toAbsolute(uri);
    return File(absPath).existsSync() || Directory(absPath).existsSync();
  }
}
