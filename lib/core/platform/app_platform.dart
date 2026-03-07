import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Platform abstraction for detecting desktop vs mobile runtime environments,
/// resolving cross-platform storage directories, and enabling test overrides.
class AppPlatform {
  AppPlatform._();

  /// Optional test override to simulate mobile environment in widget tests.
  static bool? overrideIsMobileForTest;

  /// Optional test override to simulate desktop environment in widget tests.
  static bool? overrideIsDesktopForTest;

  static String? _appDocumentsPath;
  static String? _appSupportPath;

  /// Initializes platform paths on startup (e.g. in main() or during first call).
  static Future<void> initializePaths() async {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      _appDocumentsPath = docDir.path;
    } catch (_) {}
    try {
      final supportDir = await getApplicationSupportDirectory();
      _appSupportPath = supportDir.path;
    } catch (_) {}
  }

  /// Returns the app documents directory path.
  static Future<String> getDocumentsDirectoryPath() async {
    if (_appDocumentsPath != null) return _appDocumentsPath!;
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return Directory.systemTemp.path;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      _appDocumentsPath = dir.path;
      return dir.path;
    } catch (_) {
      return getBaseDataDirectory();
    }
  }

  /// Returns the app support directory path.
  static Future<String> getSupportDirectoryPath() async {
    if (_appSupportPath != null) return _appSupportPath!;
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return Directory.systemTemp.path;
    }
    try {
      final dir = await getApplicationSupportDirectory();
      _appSupportPath = dir.path;
      return dir.path;
    } catch (_) {
      return getBaseDataDirectory();
    }
  }

  /// Returns the device's public/user Documents directory
  /// (e.g. /storage/emulated/0/Documents on Android, ~/Documents on Desktop/macOS/Linux).
  static Future<String> getDeviceDocumentsDirectory() async {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return Directory.systemTemp.path;
    }

    if (Platform.isAndroid) {
      const androidDocs = '/storage/emulated/0/Documents';
      final dir = Directory(androidDocs);
      if (dir.existsSync()) {
        return androidDocs;
      }
      try {
        final extDirs = await getExternalStorageDirectories(
          type: StorageDirectory.documents,
        );
        if (extDirs != null &&
            extDirs.isNotEmpty &&
            extDirs.first.existsSync()) {
          return extDirs.first.path;
        }
      } catch (_) {}
      const androidStorage = '/storage/emulated/0';
      if (Directory(androidStorage).existsSync()) {
        final docs = Directory(p.join(androidStorage, 'Documents'));
        if (!docs.existsSync()) {
          try {
            docs.createSync(recursive: true);
          } catch (_) {}
        }
        if (docs.existsSync()) return docs.path;
        return androidStorage;
      }
    }

    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      final docs = p.join(home, 'Documents');
      if (Directory(docs).existsSync()) {
        return docs;
      }
    }

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      return appDocDir.path;
    } catch (_) {
      return getBaseDataDirectory();
    }
  }

  /// Synchronous fallback for device documents directory
  static String getDeviceDocumentsDirectorySync() {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return Directory.systemTemp.path;
    }

    if (Platform.isAndroid) {
      const androidDocs = '/storage/emulated/0/Documents';
      if (Directory(androidDocs).existsSync()) {
        return androidDocs;
      }
      const androidStorage = '/storage/emulated/0';
      if (Directory(androidStorage).existsSync()) {
        return androidStorage;
      }
    }

    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      final docs = p.join(home, 'Documents');
      if (Directory(docs).existsSync()) {
        return docs;
      }
      return home;
    }

    return Directory.current.path;
  }

  /// Whether the current platform is a desktop operating system (Linux, macOS, Windows).
  static bool get isDesktop {
    if (overrideIsDesktopForTest != null) return overrideIsDesktopForTest!;
    if (overrideIsMobileForTest != null) return !overrideIsMobileForTest!;
    if (kIsWeb) return false;
    return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  }

  /// Whether the current platform is a mobile operating system (Android, iOS).
  static bool get isMobile {
    if (overrideIsMobileForTest != null) return overrideIsMobileForTest!;
    if (overrideIsDesktopForTest != null) return !overrideIsDesktopForTest!;
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Whether the current platform is Linux.
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Whether the current platform is Android.
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Whether the current platform is iOS.
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Whether the current platform is macOS.
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Whether the current platform is Windows.
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Whether the app is running in the browser.
  static bool get isWeb => kIsWeb;

  /// Resolves the base app data directory safely across desktop and mobile platforms.
  static String getBaseDataDirectory() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return Directory.systemTemp.path;
    }

    if (isAndroid || isIOS) {
      if (_appDocumentsPath != null && _appDocumentsPath!.isNotEmpty) {
        return _appDocumentsPath!;
      }
      if (_appSupportPath != null && _appSupportPath!.isNotEmpty) {
        return _appSupportPath!;
      }
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty && Directory(home).existsSync()) {
        return home;
      }
      return Directory.systemTemp.path;
    }

    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;

    if (isWindows) {
      return Platform.environment['APPDATA'] ?? home;
    } else if (isMacOS) {
      return p.join(home, 'Library', 'Application Support');
    } else {
      return Platform.environment['XDG_DATA_HOME'] ??
          p.join(home, '.local', 'share');
    }
  }

  /// Resolves the config directory for storing settings/state.
  static String getBaseConfigDirectory() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return Directory.systemTemp.path;
    }

    if (isAndroid || isIOS) {
      return getBaseDataDirectory();
    }

    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;

    if (isWindows) {
      return Platform.environment['APPDATA'] ?? home;
    } else if (isMacOS) {
      return p.join(home, 'Library', 'Application Support');
    } else {
      return Platform.environment['XDG_CONFIG_HOME'] ?? p.join(home, '.config');
    }
  }
}
