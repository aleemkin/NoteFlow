import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteflow/features/vault/vault.dart';
import 'package:noteflow/features/search/search.dart';

export 'package:noteflow/features/shell/controllers/controllers.dart';

/// Vault tree repository — manages the in-memory file tree.
final vaultTreeRepositoryProvider = ChangeNotifierProvider((ref) {
  return VaultTreeRepository();
});

/// Vault manager — single instance that owns the vault lifecycle.
final vaultManagerProvider = Provider((ref) {
  final treeRepo = ref.read(vaultTreeRepositoryProvider);
  return VaultManager(treeRepository: treeRepo);
});

/// Vault operations — create, rename, delete files/folders.
final vaultOperationsProvider = Provider((ref) {
  final manager = ref.read(vaultManagerProvider);
  return VaultOperationService(manager: manager);
});

/// Folder sequence service — manages note ordering in folders.
final folderSequenceServiceProvider = Provider((ref) {
  final manager = ref.read(vaultManagerProvider);
  return FolderSequenceService(manager: manager);
});

/// Search service — vault-wide text search.
final searchServiceProvider = Provider((ref) {
  final manager = ref.read(vaultManagerProvider);
  final treeRepo = ref.read(vaultTreeRepositoryProvider);
  return SearchService(vaultManager: manager, treeRepository: treeRepo);
});

/// Currently opened vault configuration.
final currentVaultProvider = StateProvider<VaultConfig?>((ref) => null);

/// Currently selected document path (vault-relative).
final currentDocumentPathProvider = StateProvider<String?>((ref) => null);
