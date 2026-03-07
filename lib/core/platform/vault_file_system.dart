import 'dart:typed_data';

import 'vault_change.dart';
import 'vault_entry.dart';
import 'vault_uri.dart';
import 'write_precondition.dart';

/// Platform abstraction for vault filesystem operations.
///
/// Implementations handle Linux local paths, Android SAF,
/// and in-memory test filesystems.
abstract interface class VaultFileSystem {
  Future<List<VaultEntry>> listTree(VaultUri root);
  Future<Uint8List> readBytes(VaultUri uri);
  Future<void> writeBytes(
    VaultUri uri,
    Uint8List bytes,
    WritePrecondition precondition,
  );
  Future<void> createDirectory(VaultUri uri);
  Future<void> move(VaultUri from, VaultUri to);
  Future<void> delete(VaultUri uri);
  Stream<VaultChangeBatch> watch(VaultUri root);
  Future<bool> exists(VaultUri uri);
}
