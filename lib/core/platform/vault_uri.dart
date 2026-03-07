import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;

/// A vault-relative path identifier for files and directories.
///
/// Always uses normalized forward-slash separators regardless of operating system.
/// An empty path represents the vault root.
final class VaultUri with Equatable {
  /// The normalized vault-relative path string.
  final String path;

  /// Creates a [VaultUri] from a relative [path].
  const VaultUri({required this.path});

  /// Creates a [VaultUri] by joining multiple path [segments].
  factory VaultUri.fromParts(List<String> segments) {
    return VaultUri(path: segments.join('/'));
  }

  /// Returns `true` if this URI points to the root of the vault.
  bool get isRoot => path.isEmpty;

  /// The trailing file or directory name component.
  String get fileName => p.basename(path);

  /// The file extension (e.g., `.md`, `.excalidraw`), including the leading dot.
  String get extension => p.extension(path);

  /// The parent directory path, or an empty string if in the vault root.
  String get directory {
    final dir = p.dirname(path);
    return dir == '.' ? '' : dir;
  }

  @override
  List<Object?> get props => [path];

  @override
  String toString() => 'VaultUri($path)';
}
