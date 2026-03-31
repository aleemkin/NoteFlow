import 'package:flutter/foundation.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import '../../domain/vault_tree_types.dart';

/// Controller to trigger actions on [VaultTreeWidget] imperatively.
class VaultTreeController extends ChangeNotifier {
  void Function(InlineCreateType type, [VaultUri? targetDir])?
  _startCreateCallback;

  final Set<String> expandedPaths = {};
  VaultUri? selectedFolderUri;

  void attach({
    required void Function(InlineCreateType type, [VaultUri? targetDir])
    onStartCreate,
  }) {
    _startCreateCallback = onStartCreate;
  }

  void detach() {
    _startCreateCallback = null;
  }

  void startCreate(InlineCreateType type, [VaultUri? targetDir]) {
    _startCreateCallback?.call(type, targetDir);
  }
}
