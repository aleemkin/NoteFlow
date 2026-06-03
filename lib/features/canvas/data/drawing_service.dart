import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// A clean, zero-network service for managing Excalidraw drawing persistence
/// and live reload notifications, replacing the legacy local HTTP server.
class DrawingService {
  static DrawingService? _instance;
  static DrawingService get instance => _instance ??= DrawingService._();

  DrawingService._();

  String? _vaultRootPath;
  final StreamController<String> _fileSavedController =
      StreamController<String>.broadcast();

  /// Stream of file paths that were saved by Excalidraw, allowing widgets to reload in real-time.
  Stream<String> get onFileSaved => _fileSavedController.stream;

  /// Manually notifies listeners that a drawing file was saved.
  void notifyFileSaved(String filePath) {
    _fileSavedController.add(filePath);
  }

  /// Sets the active vault root path for file operations.
  void setVaultRoot(String vaultRoot) {
    _vaultRootPath = vaultRoot;
  }

  /// Returns the editor URL using the custom secure native scheme.
  String getEditorUrlFor(String filePath) {
    return 'nview://excalidraw/index.html?path=${Uri.encodeComponent(filePath)}';
  }

  /// Returns the read-only view URL using the custom secure native scheme.
  String getReadOnlyUrlFor(String filePath) {
    return 'nview://excalidraw/index.html?path=${Uri.encodeComponent(filePath)}&readonly=true&lockHorizontal=true';
  }

  /// Resolves a vault-relative or absolute file path to a local File object.
  File resolveFile(String filePath) {
    var clean = filePath;
    if (clean.startsWith('./')) clean = clean.substring(2);
    if (p.isAbsolute(clean)) return File(clean);
    if (_vaultRootPath != null && _vaultRootPath!.isNotEmpty) {
      final direct = File(p.join(_vaultRootPath!, clean));
      if (direct.existsSync()) return direct;

      try {
        final fileName = clean.contains('/') ? clean.split('/').last : clean;
        final dir = Directory(_vaultRootPath!);
        if (dir.existsSync()) {
          final entities = dir.listSync(recursive: true);
          for (final e in entities) {
            if (e is File &&
                (e.path.endsWith('/$clean') || e.path.endsWith('/$fileName'))) {
              return e;
            }
          }
        }
      } catch (_) {}

      return direct;
    }
    return File(p.join(Directory.current.path, clean));
  }

  /// Saves the .excalidraw JSON content directly to disk.
  Future<void> saveDrawingFile(String filePath, String jsonContent) async {
    final file = resolveFile(filePath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(jsonContent);
    notifyFileSaved(filePath);
  }

  /// Saves the PNG preview binary bytes alongside the .excalidraw file.
  Future<void> savePreviewFile(String filePath, List<int> pngBytes) async {
    final excalidrawFile = resolveFile(filePath);
    final pngPath = '${excalidrawFile.path}.png';
    final pngFile = File(pngPath);
    if (!await pngFile.parent.exists()) {
      await pngFile.parent.create(recursive: true);
    }
    await pngFile.writeAsBytes(pngBytes);
    notifyFileSaved(filePath);
  }

  /// Loads drawing JSON from disk, or returns null if not found.
  Future<String?> loadDrawingFile(String filePath) async {
    final file = resolveFile(filePath);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  /// Legacy compatibility stop method.
  Future<void> stop() async {}
}
