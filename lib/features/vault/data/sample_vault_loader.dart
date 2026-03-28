import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'package:noteflow/core/platform/platform.dart';

/// Loads sample vault files into a normal folder on disk or into a [MemoryVaultFileSystem]
/// from external assets on disk or from the Flutter [AssetBundle].
class SampleVaultLoader {
  SampleVaultLoader._();

  /// Relative file paths included in the sample vault.
  static const List<String> sampleFiles = [
    '01_Welcome_to_noteflow.md',
    '02_Quick_Start_and_Shortcuts.md',
    '03_Starting_Your_Own_Vault.md',
    '01_Guides/Continuous_Reading.md',
    '01_Guides/Split_Editor_Workflow.md',
    '01_Guides/Document_Outline_and_Reorder.md',
    '02_Architecture/System_Architecture.md',
    '02_Architecture/system_architecture.excalidraw',
    '02_Architecture/system_architecture.excalidraw.png',
    '.kn/sequences.json',
  ];

  /// Resolves the destination directory on disk where the Sample Vault is located.
  static Future<String> resolveSampleVaultDir({String? customTargetDir}) async {
    if (customTargetDir != null && customTargetDir.isNotEmpty) {
      return customTargetDir;
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return p.join(Directory.systemTemp.path, 'noteflow_test', 'Sample Vault');
    }

    if (AppPlatform.isMobile) {
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
    bool forceOverwrite = false,
  }) async {
    final targetDir = await resolveSampleVaultDir(
      customTargetDir: customTargetDir,
    );
    final assetBundle = bundle ?? rootBundle;

    for (final relativePath in sampleFiles) {
      final destFile = File(p.join(targetDir, relativePath));

      // Overwrite if forced, file doesn't exist, or it is a corrupt/dummy PNG file
      final needsWrite =
          forceOverwrite ||
          !destFile.existsSync() ||
          destFile.lengthSync() == 0 ||
          (relativePath.endsWith('.png') && destFile.lengthSync() <= 50);

      if (!needsWrite) continue;

      Uint8List? bytes;

      // 1. Try reading raw bytes from local disk assets
      try {
        final diskSource = File(
          p.join(
            Directory.current.path,
            'assets',
            'sample_vault',
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
            'assets/sample_vault/$relativePath',
          );
          bytes = byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          );
        } catch (e) {
          debugPrint(
            'Notice: Failed to load asset sample_vault/$relativePath from bundle: $e',
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

    return targetDir;
  }

  /// Populates an in-memory [MemoryVaultFileSystem] with all sample vault files.
  static Future<void> loadInto(
    MemoryVaultFileSystem fs, {
    AssetBundle? bundle,
  }) async {
    final assetBundle = bundle ?? rootBundle;

    for (final relativePath in sampleFiles) {
      Uint8List? bytes;

      try {
        final diskPath = p.join(
          Directory.current.path,
          'assets',
          'sample_vault',
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
            'assets/sample_vault/$relativePath',
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
