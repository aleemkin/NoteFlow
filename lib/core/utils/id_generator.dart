import 'package:uuid/uuid.dart';

import 'typedefs.dart';

/// Generates strongly-typed, prefixed UUIDv7 identifiers for all notebook entities.
class IdGenerator {
  static const _uuid = Uuid();
  const IdGenerator._();

  /// Generates a unique document ID with `doc_` prefix.
  static DocumentId documentId() => 'doc_${_uuid.v7()}';

  /// Generates a unique block ID with `blk_` prefix.
  static BlockId blockId() => 'blk_${_uuid.v7()}';

  /// Generates a unique semantic mark ID with `mark_` prefix.
  static MarkId markId() => 'mark_${_uuid.v7()}';

  /// Generates a unique vault ID with `vault_` prefix.
  static VaultId vaultId() => 'vault_${_uuid.v7()}';
}
