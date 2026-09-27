import 'dart:async';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'package:noteflow/features/canvas/data/drawing_service.dart';
import 'package:noteflow/core/utils/utils.dart';
import 'package:noteflow/core/platform/platform.dart';

import 'sample_vault_loader.dart';
import '../domain/vault_config.dart';
import 'vault_scanner.dart';
import '../domain/vault_tree_node.dart';
import 'vault_tree_repository.dart';

/// High-level vault lifecycle manager.
///
/// Owns opening, scanning, reading, and watching the active vault workspace.
class VaultManager {
  VaultConfig? _currentVault;
  VaultFileSystem? _fileSystem;
  final VaultTreeRepository treeRepository;
  StreamSubscription<VaultChangeBatch>? _watchSubscription;
  final StreamController<VaultChangeBatch> _fileChangeController =
      StreamController<VaultChangeBatch>.broadcast();

  /// Stream of file system changes emitted by the active vault watcher.
  Stream<VaultChangeBatch> get onFileChanges => _fileChangeController.stream;

  /// Creates a [VaultManager] configured with [treeRepository].
  VaultManager({required this.treeRepository});

  /// The active [VaultConfig], or `null` if no vault is currently loaded.
  VaultConfig? get currentVault => _currentVault;

  /// Whether a vault is currently opened.
  bool get isOpen => _currentVault != null;

  /// The underlying [VaultFileSystem] for the active vault.
  VaultFileSystem? get fileSystem => _fileSystem;

  /// Returns the absolute filesystem directory root path of the active vault if local.
  String? get rootDirectoryPath {
    final fs = _fileSystem;
    if (fs is LocalPathVaultFileSystem) {
      return fs.rootPath;
    }
    return null;
  }

  /// Opens a local file-system vault at [path] and builds the folder tree.
  Future<void> openLocalVault(String path, {String? customDisplayName}) async {
    await close();
    final fs = LocalPathVaultFileSystem(rootPath: path);
    _fileSystem = fs;
    DrawingService.instance.setVaultRoot(path);
    final id = IdGenerator.vaultId();
    final name = customDisplayName ?? p.basename(path);

    _currentVault = VaultConfig(
      id: id,
      displayName: name,
      rootUri: const VaultUri(path: ''),
      rootKind: 'local',
      openedAt: DateTime.now(),
    );

    // Scan and build tree
    final scanner = VaultScanner(fileSystem: fs);
    final entries = await scanner.scanVault(const VaultUri(path: ''));
    treeRepository.buildTree(entries, const VaultUri(path: ''), name);

    // Start watching for changes
    _watchSubscription = fs.watch(const VaultUri(path: '')).listen(_onChanges);
  }

  /// Opens a vault using a custom [VaultFileSystem] (e.g., [MemoryVaultFileSystem]).
  Future<void> openCustomFileSystem(
    VaultFileSystem fs,
    String displayName,
  ) async {
    await close();
    _fileSystem = fs;
    if (fs is LocalPathVaultFileSystem) {
      DrawingService.instance.setVaultRoot(fs.rootPath);
    }
    final id = IdGenerator.vaultId();

    _currentVault = VaultConfig(
      id: id,
      displayName: displayName,
      rootUri: const VaultUri(path: ''),
      rootKind: 'memory',
      openedAt: DateTime.now(),
    );

    final scanner = VaultScanner(fileSystem: fs);
    final entries = await scanner.scanVault(const VaultUri(path: ''));
    treeRepository.buildTree(entries, const VaultUri(path: ''), displayName);

    _watchSubscription = fs.watch(const VaultUri(path: '')).listen(_onChanges);
  }

  /// Opens a rich, interactive sample vault as a standard local folder on disk.
  Future<void> openSampleVault({
    bool? isMobile,
    void Function(String message, double? progress)? onProgress,
  }) async {
    final samplePath = await SampleVaultLoader.ensureSampleVaultOnDisk(
      isMobile: isMobile,
      onProgress: onProgress,
    );
    onProgress?.call('Scanning notebook files...', null);
    await openLocalVault(samplePath, customDisplayName: 'Sample Vault');
  }

  /// Reads raw bytes for the file located at [uri].
  Future<Uint8List> readFile(VaultUri uri) async {
    if (_fileSystem == null) throw StateError('No vault open');
    return _fileSystem!.readBytes(uri);
  }

  /// Closes the active vault, canceling filesystem watchers and clearing state.
  Future<void> close() async {
    final sub = _watchSubscription;
    _watchSubscription = null;
    _currentVault = null;
    _fileSystem = null;
    await sub?.cancel();
  }

  void dispose() {
    _watchSubscription?.cancel();
    _watchSubscription = null;
    _fileChangeController.close();
  }

  Future<void> _onChanges(VaultChangeBatch batch) async {
    // 1. If any file or directory was created, deleted, or moved, refresh tree repository
    // (Ignore internal drawing snapshot PNG files so preview saves don't cause redundant rebuilds)
    final hasStructureChange = batch.changes.any(
      (c) =>
          (c.type == VaultChangeType.created ||
              c.type == VaultChangeType.deleted ||
              c.type == VaultChangeType.moved) &&
          !VaultTreeNode.isDrawingSnapshot(c.uri.path),
    );
    if (hasStructureChange && _fileSystem != null) {
      try {
        final scanner = VaultScanner(fileSystem: _fileSystem!);
        final entries = await scanner.scanVault(const VaultUri(path: ''));
        treeRepository.buildTree(
          entries,
          const VaultUri(path: ''),
          _currentVault?.displayName ?? 'Vault',
        );
      } catch (_) {}
    }

    // 2. Broadcast change batch to all listeners (HomeScreen, DualPaneEditor, etc.)
    if (!_fileChangeController.isClosed) {
      _fileChangeController.add(batch);
    }
  }
}
