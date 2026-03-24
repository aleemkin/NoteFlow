import 'dart:convert';
import 'dart:typed_data';

import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/vault/data/vault_manager.dart';
import 'package:noteflow/features/vault/domain/vault_tree_node.dart';

/// Manages ordered sequences of documents within folders.
///
/// Order is persisted in `.kn/sequences.json` in the vault root.
/// If no custom sequence exists for a folder, fallback to alphabetical.
class FolderSequenceService {
  final VaultManager manager;

  FolderSequenceService({required this.manager});

  VaultFileSystem get _fs {
    final fs = manager.fileSystem;
    if (fs == null) throw StateError('No vault open');
    return fs;
  }

  static const _sequenceFileUri = VaultUri(path: '.kn/sequences.json');

  static String _normalize(String p) {
    return p
        .trim()
        .replaceAll(r'\', '/')
        .replaceAll(RegExp(r'^/+'), '')
        .replaceAll(RegExp(r'/+$'), '');
  }

  /// Load custom ordering for a specific folder path.
  Future<List<String>> getSequence(String folderPath) async {
    final key = _normalize(folderPath);
    final sequences = await _loadAllSequences();
    final list = sequences[key] ?? [];
    return list.map(_normalize).toList();
  }

  /// Save custom ordering for a folder path.
  Future<void> setSequence(String folderPath, List<String> orderedPaths) async {
    final key = _normalize(folderPath);
    final sequences = await _loadAllSequences();
    sequences[key] = orderedPaths.map(_normalize).toList();
    await _saveAllSequences(sequences);
  }

  /// Append a newly created file to the very end of the folder sequence.
  Future<void> appendToFileSequence(String folderPath, String filePath) async {
    final key = _normalize(folderPath);
    final normFile = _normalize(filePath);
    final sequences = await _loadAllSequences();
    final current = (sequences[key] ?? []).map(_normalize).toList();
    if (!current.contains(normFile)) {
      current.add(normFile);
      sequences[key] = current;
      await _saveAllSequences(sequences);
    }
  }

  /// Return sorted children for a folder node, applying any custom sequence.
  Future<List<VaultTreeNode>> getOrderedFolderFiles(
    VaultTreeNode folderNode,
  ) async {
    final customOrder = await getSequence(folderNode.uri.path);
    // Get all supported files in this folder (excluding directories and drawing snapshots)
    final files = folderNode.children
        .where(
          (c) =>
              !c.isDirectory &&
              c.isSupported &&
              !VaultTreeNode.isDrawingSnapshot(c.uri.path),
        )
        .toList();

    if (customOrder.isEmpty) {
      // Natural alphabetical order
      files.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return files;
    }

    // Build an O(1) index lookup map for custom ordering
    final orderMap = {
      for (var i = 0; i < customOrder.length; i++) customOrder[i]: i,
    };

    // Sort by custom sequence index
    files.sort((a, b) {
      final normA = _normalize(a.uri.path);
      final normB = _normalize(b.uri.path);
      final idxA = orderMap[normA] ?? -1;
      final idxB = orderMap[normB] ?? -1;
      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
      if (idxA != -1) return -1;
      if (idxB != -1) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return files;
  }

  Future<Map<String, List<String>>> _loadAllSequences() async {
    try {
      if (await _fs.exists(_sequenceFileUri)) {
        final bytes = await _fs.readBytes(_sequenceFileUri);
        final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        return json.map((k, v) => MapEntry(k, (v as List).cast<String>()));
      }
    } catch (_) {}
    return {};
  }

  Future<void> _saveAllSequences(Map<String, List<String>> sequences) async {
    final content = const JsonEncoder.withIndent('  ').convert(sequences);
    await _fs.writeBytes(
      _sequenceFileUri,
      Uint8List.fromList(utf8.encode(content)),
      const NoPrecondition(),
    );
  }
}
