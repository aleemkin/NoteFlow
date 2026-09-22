import 'package:flutter/material.dart';
import 'package:noteflow/features/vault/data/vault_state_storage.dart';

/// Reusable mixin providing recent vault loading, removal, and clearing capabilities.
mixin RecentVaultsMixin<T extends StatefulWidget> on State<T> {
  List<String> recentVaults = [];
  bool loadingRecents = true;

  @override
  void initState() {
    super.initState();
    loadRecentVaults();
  }

  /// Loads recent vault paths from persistent storage.
  Future<void> loadRecentVaults({int limit = 10}) async {
    try {
      final recents = await VaultStateStorage.getRecentVaultPaths(limit: limit);
      if (mounted) {
        setState(() {
          recentVaults = recents;
          loadingRecents = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => loadingRecents = false);
      }
    }
  }

  /// Removes a vault path from recent storage and updates UI state.
  Future<void> removeRecentVault(String path) async {
    await VaultStateStorage.removeRecentVaultPath(path);
    if (mounted) {
      setState(() {
        recentVaults.remove(path);
      });
    }
  }

  /// Clears all recent vault paths from storage and resets state.
  Future<void> clearAllRecentVaults() async {
    await VaultStateStorage.clearRecentVaults();
    if (mounted) {
      setState(() {
        recentVaults.clear();
      });
    }
  }
}
