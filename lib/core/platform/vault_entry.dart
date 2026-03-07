import 'package:equatable/equatable.dart';

import 'vault_uri.dart';

enum VaultEntryKind { file, directory }

/// Represents a file or directory discovered in the vault.
final class VaultEntry with Equatable {
  final VaultUri uri;
  final VaultEntryKind kind;
  final int sizeBytes;
  final DateTime modifiedAt;
  final String? contentHash;

  const VaultEntry({
    required this.uri,
    required this.kind,
    this.sizeBytes = 0,
    required this.modifiedAt,
    this.contentHash,
  });

  @override
  List<Object?> get props => [uri, kind, sizeBytes, modifiedAt, contentHash];
}
