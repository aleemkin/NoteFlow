import 'package:noteflow/core/utils/typedefs.dart';
import 'package:noteflow/core/platform/vault_uri.dart';

/// Configuration and identity for an opened vault.
final class VaultConfig {
  final VaultId id;
  final String displayName;
  final VaultUri rootUri;
  final String rootKind; // 'local' or 'saf'
  final DateTime openedAt;

  const VaultConfig({
    required this.id,
    required this.displayName,
    required this.rootUri,
    required this.rootKind,
    required this.openedAt,
  });
}
