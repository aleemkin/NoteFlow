import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:noteflow/core/platform/app_platform.dart';

/// Manages persistence of application state (such as the last opened vault path).
class VaultStateStorage {
  VaultStateStorage._();

  /// Optional in-memory override used for tests or headless environments.
  static String? testOverrideLastPath;

  /// Optional in-memory override for recent vault paths in tests.
  static List<String>? testOverrideRecentPaths;

  /// Whether persistent disk writes should be disabled (e.g. during unit tests).
  static bool disablePersistenceForTest = false;

  static File _getStateFile() {
    final baseDir = AppPlatform.getBaseConfigDirectory();
    return File(p.join(baseDir, 'noteflow', 'state.json'));
  }

  /// Returns the path to the previously opened local vault if it exists on disk.
  static Future<String?> getLastVaultPath() async {
    if (testOverrideLastPath != null) {
      return testOverrideLastPath;
    }
    if (disablePersistenceForTest) {
      return null;
    }

    try {
      final file = _getStateFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final path = json['lastVaultPath'] as String?;
        if (path != null && path.trim().isNotEmpty) {
          final dir = Directory(path.trim());
          if (await dir.exists()) {
            return dir.path;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Returns a list of recently opened vault paths that still exist on disk.
  static Future<List<String>> getRecentVaultPaths({int limit = 5}) async {
    if (testOverrideRecentPaths != null) {
      return testOverrideRecentPaths!;
    }
    if (disablePersistenceForTest) {
      return [];
    }

    try {
      final file = _getStateFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final rawList = json['recentVaults'] as List<dynamic>?;
        final list = <String>[];
        if (rawList != null) {
          for (final item in rawList) {
            if (item is String && item.trim().isNotEmpty) {
              final path = item.trim();
              if (await Directory(path).exists() && !list.contains(path)) {
                list.add(path);
              }
            }
          }
        }

        // Fallback to lastVaultPath if recentVaults is empty
        if (list.isEmpty) {
          final last = json['lastVaultPath'] as String?;
          if (last != null && last.trim().isNotEmpty) {
            final dir = Directory(last.trim());
            if (await dir.exists()) {
              list.add(dir.path);
            }
          }
        }

        return list.take(limit).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Saves the last opened vault path to disk for automatic recovery on next launch,
  /// and updates the list of recent vaults.
  static Future<void> saveLastVaultPath(String? path) async {
    if (disablePersistenceForTest) return;

    try {
      final file = _getStateFile();
      await file.parent.create(recursive: true);

      Map<String, dynamic> json = {};
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          json = jsonDecode(content) as Map<String, dynamic>;
        } catch (_) {}
      }

      final trimmed = path?.trim();
      json['lastVaultPath'] = trimmed;

      if (trimmed != null && trimmed.isNotEmpty) {
        final rawList =
            (json['recentVaults'] as List<dynamic>?)?.cast<String>().toList() ??
            [];
        rawList.remove(trimmed);
        rawList.insert(0, trimmed);
        json['recentVaults'] = rawList.take(10).toList();
      }

      await file.writeAsString(jsonEncode(json));
    } catch (_) {}
  }

  /// Removes a vault path from the recent vaults list.
  static Future<void> removeRecentVaultPath(String path) async {
    if (disablePersistenceForTest) return;

    try {
      final file = _getStateFile();
      if (!await file.exists()) return;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final rawList =
          (json['recentVaults'] as List<dynamic>?)?.cast<String>().toList() ??
          [];
      rawList.remove(path.trim());
      json['recentVaults'] = rawList;

      if (json['lastVaultPath'] == path.trim()) {
        json['lastVaultPath'] = rawList.isNotEmpty ? rawList.first : null;
      }

      await file.writeAsString(jsonEncode(json));
    } catch (_) {}
  }

  /// Clears all stored recent vault paths.
  static Future<void> clearRecentVaults() async {
    if (disablePersistenceForTest) return;

    try {
      final file = _getStateFile();
      if (!await file.exists()) return;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      json.remove('recentVaults');
      json['lastVaultPath'] = null;

      await file.writeAsString(jsonEncode(json));
    } catch (_) {}
  }
}
