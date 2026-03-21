import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'package:noteflow/core/platform/platform.dart';

import '../domain/vault_tree_node.dart';

/// Manages the reactive in-memory vault filesystem hierarchy tree.
///
/// Notifies listeners when the tree is rebuilt or modified.
class VaultTreeRepository extends ChangeNotifier {
  VaultTreeNode? _root;

  /// The root node of the vault tree, or `null` if no vault is loaded.
  VaultTreeNode? get root => _root;

  /// Builds the complete hierarchical tree from a flat list of scanned [entries].
  void buildTree(List<VaultEntry> entries, VaultUri rootUri, String rootName) {
    // Group entries by parent directory
    final dirChildren = <String, List<VaultEntry>>{};
    final dirs = <String>{''};

    for (final entry in entries) {
      final segments = entry.uri.path.split('/');
      // Filter out hidden files and internal application directories (e.g. .kn, .git, .DS_Store)
      // Filter out internal drawing snapshots saved in PNG (e.g. .excalidraw.png)
      if (VaultTreeNode.isDrawingSnapshot(entry.uri.path)) continue;

      final parent = p.posix.dirname(entry.uri.path);
      final parentKey = parent == '.' ? '' : parent;
      dirChildren.putIfAbsent(parentKey, () => []).add(entry);
      if (entry.kind == VaultEntryKind.directory) {
        dirs.add(entry.uri.path);
      }
    }

    // Recursively build tree
    VaultTreeNode buildNode(String dirPath, String name) {
      final childEntries = dirChildren[dirPath] ?? [];
      final childNodes = <VaultTreeNode>[];

      for (final entry in childEntries) {
        if (entry.kind == VaultEntryKind.directory) {
          childNodes.add(
            buildNode(entry.uri.path, p.posix.basename(entry.uri.path)),
          );
        } else {
          childNodes.add(
            VaultTreeNode(
              uri: entry.uri,
              name: p.posix.basename(entry.uri.path),
              isDirectory: false,
              isSupported: VaultTreeNode.isSupportedFile(entry.uri.path),
              sizeBytes: entry.sizeBytes,
              modifiedAt: entry.modifiedAt,
            ),
          );
        }
      }

      return VaultTreeNode(
        uri: VaultUri(path: dirPath),
        name: name,
        isDirectory: true,
        modifiedAt: DateTime.now(),
        children: childNodes,
      );
    }

    _root = buildNode('', rootName);
    notifyListeners();
  }

  /// Explicitly sets the root tree node (useful for testing and instant tree updates).
  void setRoot(VaultTreeNode node) {
    _root = node;
    notifyListeners();
  }

  /// Returns all supported documents in the tree as a flat list.
  List<VaultTreeNode> get allSupportedFiles {
    final result = <VaultTreeNode>[];
    void collect(VaultTreeNode node) {
      if (!node.isDirectory && node.isSupported) {
        result.add(node);
      }
      for (final child in node.children) {
        collect(child);
      }
    }

    if (_root != null) collect(_root!);
    return result;
  }

  /// Finds a specific [VaultTreeNode] matching [uri], or `null` if not found.
  VaultTreeNode? findNode(VaultUri uri) {
    VaultTreeNode? search(VaultTreeNode node) {
      if (node.uri == uri) return node;
      for (final child in node.children) {
        final found = search(child);
        if (found != null) return found;
      }
      return null;
    }

    return _root != null ? search(_root!) : null;
  }
}
