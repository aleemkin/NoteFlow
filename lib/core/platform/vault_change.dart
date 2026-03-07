import 'vault_uri.dart';

enum VaultChangeType { created, modified, deleted, moved }

/// A single filesystem change event in the vault.
final class VaultChange {
  final VaultChangeType type;
  final VaultUri uri;
  final VaultUri? previousUri;
  final DateTime timestamp;

  const VaultChange({
    required this.type,
    required this.uri,
    this.previousUri,
    required this.timestamp,
  });
}

/// A batch of filesystem changes received together.
final class VaultChangeBatch {
  final List<VaultChange> changes;
  final DateTime timestamp;

  const VaultChangeBatch({required this.changes, required this.timestamp});
}
