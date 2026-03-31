import 'package:noteflow/core/platform/vault_uri.dart';

/// An immutable node in the vault filesystem hierarchy tree.
final class VaultTreeNode {
  /// Vault-relative URI of this file or directory.
  final VaultUri uri;

  /// Display name of the file or directory.
  final String name;

  /// Whether this node represents a directory.
  final bool isDirectory;

  /// Whether this node represents a supported editable notebook file (`.md` or `.excalidraw`).
  final bool isSupported;

  /// File size in bytes.
  final int sizeBytes;

  /// Last modification timestamp.
  final DateTime modifiedAt;

  /// Sub-nodes contained within this directory node.
  final List<VaultTreeNode> children;

  /// Creates a [VaultTreeNode] instance.
  const VaultTreeNode({
    required this.uri,
    required this.name,
    required this.isDirectory,
    this.isSupported = false,
    this.sizeBytes = 0,
    required this.modifiedAt,
    this.children = const [],
  });

  /// Checks whether a given [path] represents a drawing snapshot preview image (e.g. `.excalidraw.png`).
  static bool isDrawingSnapshot(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.excalidraw.png') ||
        lower.endsWith('.drawing.png') ||
        (lower.endsWith('.png') && lower.contains('.excalidraw'));
  }

  /// Checks whether a given [path] represents a supported document format (`.md` or `.excalidraw`).
  static bool isSupportedFile(String path) {
    if (isDrawingSnapshot(path)) return false;
    final lower = path.toLowerCase();
    return lower.endsWith('.md') || lower.endsWith('.excalidraw');
  }

  /// Returns children sorted with directories first, followed by alphabetical order.
  List<VaultTreeNode> get sortedChildren {
    final sorted = List<VaultTreeNode>.from(children);
    sorted.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }
}
