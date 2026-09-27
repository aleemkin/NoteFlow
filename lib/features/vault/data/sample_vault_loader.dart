import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'package:noteflow/core/platform/platform.dart';

/// Loads sample vault files into a normal folder on disk or into a [MemoryVaultFileSystem]
/// from external assets on disk or from the Flutter [AssetBundle].
///
/// Supports tailored sample vaults for both desktop and mobile platforms.
class SampleVaultLoader {
  SampleVaultLoader._();

  /// Version tracking to automatically unpack upgraded sample files when updated.
  static const int currentSampleVaultVersion = 3;

  /// Relative file paths included in the desktop sample vault.
  static const List<String> desktopFiles = [
    '01_Welcome_to_noteflow.md',
    '02_Keyboard_Shortcuts_and_Navigation.md',
    '03_Markdown_and_Tag_Directives.md',
    '04_Starting_Your_Own_Vault.md',
    '01_Guides/Continuous_Reading_Workflow.md',
    '01_Guides/Dual_Pane_Split_Editor.md',
    '01_Guides/Outline_and_Drag_Reorder.md',
    '01_Guides/Topic_Filtering_and_Export.md',
    '02_Architecture/System_Architecture.md',
    '02_Architecture/system_architecture.excalidraw',
    '02_Architecture/system_architecture.excalidraw.png',
    '03_Projects/Product_Roadmap.md',
    '03_Projects/Sprint_Planning.md',
    '.kn/sequences.json',
  ];

  /// Relative file paths included in the mobile sample vault.
  static const List<String> mobileFiles = [
    '01_Welcome_to_noteflow.md',
    '02_Mobile_Gesture_and_Touch_Guide.md',
    '03_Mobile_Writing_and_Tags.md',
    '01_Daily_Notes/Today_Focus.md',
    '01_Daily_Notes/Meeting_and_Ideas.md',
    '02_Drawings/Mobile_Diagram_Workflow.md',
    '02_Drawings/mobile_workflow.excalidraw',
    '02_Drawings/mobile_workflow.excalidraw.png',
    '03_Guides/Continuous_Reading_on_Mobile.md',
    '03_Guides/Managing_Vaults_on_Device.md',
    '.kn/sequences.json',
  ];

  /// Backward-compatible alias for existing tests and callers.
  static List<String> get sampleFiles => desktopFiles;

  /// Resolves the destination directory on disk where the Sample Vault is located.
  static Future<String> resolveSampleVaultDir({
    String? customTargetDir,
    bool? isMobile,
  }) async {
    if (customTargetDir != null && customTargetDir.isNotEmpty) {
      return customTargetDir;
    }

    final mobile = isMobile ?? AppPlatform.isMobile;

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return p.join(
        Directory.systemTemp.path,
        'noteflow_test',
        mobile ? 'Sample Vault Mobile' : 'Sample Vault',
      );
    }

    if (mobile) {
      final docDir = await AppPlatform.getDocumentsDirectoryPath();
      return p.join(docDir, 'Sample Vault');
    }

    final baseDir = AppPlatform.getBaseDataDirectory();
    return p.join(baseDir, 'noteflow', 'Sample Vault');
  }

  /// Ensures that the Sample Vault is unpacked into a standard local directory on disk.
  /// Unpacks sample vault files if they are missing or outdated.
  /// Returns the absolute path to the unpacked directory.
  static Future<String> ensureSampleVaultOnDisk({
    AssetBundle? bundle,
    String? customTargetDir,
    bool? isMobile,
    bool forceOverwrite = false,
    void Function(String message, double? progress)? onProgress,
  }) async {
    final mobile = isMobile ?? AppPlatform.isMobile;
    final targetDir = await resolveSampleVaultDir(
      customTargetDir: customTargetDir,
      isMobile: mobile,
    );
    final filesToUnpack = mobile ? mobileFiles : desktopFiles;
    final platformSubdir = mobile ? 'mobile' : 'desktop';
    final assetBundle = bundle ?? rootBundle;

    // Check version to see if existing sample vault needs upgrade
    final versionFile = File(p.join(targetDir, '.kn', 'sample_version'));
    bool isOutdated = false;
    if (versionFile.existsSync()) {
      try {
        final version = int.tryParse(versionFile.readAsStringSync().trim()) ?? 0;
        isOutdated = version < currentSampleVaultVersion;
      } catch (_) {
        isOutdated = true;
      }
    } else {
      isOutdated = true;
    }
    final shouldOverwrite = forceOverwrite || isOutdated;

    onProgress?.call(
      'Initializing ${mobile ? 'Mobile' : 'Desktop'} sample workspace...',
      0.0,
    );

    for (int i = 0; i < filesToUnpack.length; i++) {
      final relativePath = filesToUnpack[i];
      final destFile = File(p.join(targetDir, relativePath));

      final progress = (i + 1) / (filesToUnpack.length + 1);
      final fileName = p.basename(relativePath);
      onProgress?.call('Saving $fileName...', progress);

      // Overwrite if forced/outdated, file doesn't exist, or it is a corrupt/dummy PNG file
      final needsWrite =
          shouldOverwrite ||
          !destFile.existsSync() ||
          destFile.lengthSync() == 0 ||
          (relativePath.endsWith('.png') && destFile.lengthSync() <= 50);

      if (!needsWrite) continue;

      Uint8List? bytes;

      // 1. Try reading raw bytes from platform-specific disk assets (assets/sample_vault/desktop or mobile)
      try {
        final diskSource = File(
          p.join(
            Directory.current.path,
            'assets',
            'sample_vault',
            platformSubdir,
            relativePath,
          ),
        );
        if (diskSource.existsSync()) {
          bytes = diskSource.readAsBytesSync();
        }
      } catch (_) {}

      // 2. Try loading raw bytes from Flutter AssetBundle
      if (bytes == null) {
        try {
          final byteData = await assetBundle.load(
            'assets/sample_vault/$platformSubdir/$relativePath',
          );
          bytes = byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          );
        } catch (e) {
          debugPrint(
            'Notice: Failed to load asset sample_vault/$platformSubdir/$relativePath from bundle: $e',
          );
        }
      }

      if (bytes != null) {
        try {
          if (!destFile.parent.existsSync()) {
            destFile.parent.createSync(recursive: true);
          }
          destFile.writeAsBytesSync(bytes, flush: true);
        } catch (e) {
          debugPrint('Error writing sample file $relativePath: $e');
        }
      }
    }

    // Persist current version tag
    try {
      if (!versionFile.parent.existsSync()) {
        versionFile.parent.createSync(recursive: true);
      }
      versionFile.writeAsStringSync('$currentSampleVaultVersion', flush: true);
    } catch (_) {}

    onProgress?.call('Finalizing sample workspace...', 1.0);
    return targetDir;
  }

  /// Populates an in-memory [MemoryVaultFileSystem] with all sample vault files.
  static Future<void> loadInto(
    MemoryVaultFileSystem fs, {
    AssetBundle? bundle,
    bool? isMobile,
  }) async {
    final mobile = isMobile ?? AppPlatform.isMobile;
    final filesToUnpack = mobile ? mobileFiles : desktopFiles;
    final platformSubdir = mobile ? 'mobile' : 'desktop';
    final assetBundle = bundle ?? rootBundle;

    for (final relativePath in filesToUnpack) {
      Uint8List? bytes;

      try {
        final diskPath = p.join(
          Directory.current.path,
          'assets',
          'sample_vault',
          platformSubdir,
          relativePath,
        );
        final file = File(diskPath);
        if (file.existsSync()) {
          bytes = file.readAsBytesSync();
        }
      } catch (_) {}

      if (bytes == null) {
        try {
          final byteData = await assetBundle.load(
            'assets/sample_vault/$platformSubdir/$relativePath',
          );
          bytes = byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          );
        } catch (_) {}
      }

      if (bytes != null) {
        fs.seedBytes(relativePath, bytes);
      }
    }
  }
}
