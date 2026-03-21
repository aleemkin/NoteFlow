import 'package:noteflow/core/platform/vault_uri.dart';

/// Supported types for inline item creation.
enum InlineCreateType { note, drawing, folder }

/// Active inline creation state tracking the type and target parent folder.
class InlineCreateState {
  final InlineCreateType type;
  final VaultUri parentDir;

  const InlineCreateState({required this.type, required this.parentDir});
}
