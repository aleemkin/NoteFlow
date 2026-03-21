import 'package:noteflow/core/platform/platform.dart';

class VaultScanner {
  final VaultFileSystem fileSystem;

  VaultScanner({required this.fileSystem});

  /// Scan the full vault tree from root.
  Future<List<VaultEntry>> scanVault(VaultUri root) async {
    return fileSystem.listTree(root);
  }
}
