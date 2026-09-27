import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/canvas/canvas.dart';
import 'package:noteflow/core/platform/vault_uri.dart';

import 'drawing/drawing.dart';

/// Renders an embedded drawing block inside a continuous notebook roll.
class DrawingBlockRenderer extends ConsumerStatefulWidget {
  final String drawingPath;
  final String? docDirectory;
  final double height;
  final VoidCallback? onOpenEditor;
  final void Function(String tagType)? onTag;

  const DrawingBlockRenderer({
    super.key,
    required this.drawingPath,
    this.docDirectory,
    this.height = 260,
    this.onOpenEditor,
    this.onTag,
  });

  @override
  ConsumerState<DrawingBlockRenderer> createState() =>
      _DrawingBlockRendererState();
}

class _DrawingBlockRendererState extends ConsumerState<DrawingBlockRenderer> {
  bool _hasElements = false;
  Uint8List? _pngBytes;
  (double, double)? _pngDimensions;
  StreamSubscription<String>? _saveSub;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadDrawing();
    _saveSub = DrawingService.instance.onFileSaved.listen((savedPath) {
      if (mounted && _matchesPath(savedPath)) {
        _loadDrawing();
      }
    });
  }

  @override
  void dispose() {
    _saveSub?.cancel();
    super.dispose();
  }

  bool _matchesPath(String savedPath) {
    var clean = widget.drawingPath;
    if (clean.startsWith('./')) clean = clean.substring(2);
    final fileName = clean.contains('/') ? clean.split('/').last : clean;
    return savedPath == clean ||
        savedPath.endsWith(clean) ||
        savedPath.endsWith(fileName) ||
        (widget.docDirectory != null &&
            savedPath.endsWith('${widget.docDirectory}/$clean'));
  }

  @override
  void didUpdateWidget(DrawingBlockRenderer old) {
    super.didUpdateWidget(old);
    if (old.drawingPath != widget.drawingPath ||
        old.docDirectory != widget.docDirectory) {
      _loadDrawing();
    }
  }

  /// Parse intrinsic width and height from PNG IHDR chunk (instant, zero-overhead).
  (double, double)? _parsePngDimensions(Uint8List bytes) {
    if (bytes.length < 24) return null;
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      final byteData = ByteData.sublistView(bytes);
      final width = byteData.getUint32(16).toDouble();
      final height = byteData.getUint32(20).toDouble();
      if (width > 0 && height > 0) {
        return (width, height);
      }
    }
    return null;
  }

  bool _checkHasElements(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      if (data is Map && data['elements'] is List) {
        final elements = data['elements'] as List;
        return elements.any((e) => e is Map && e['isDeleted'] != true);
      }
    } catch (_) {}
    return false;
  }

  Future<void> _loadDrawing() async {
    try {
      final manager = ref.read(vaultManagerProvider);
      var cleanPath = widget.drawingPath;
      if (cleanPath.startsWith('./')) cleanPath = cleanPath.substring(2);

      var uri = VaultUri(path: p.normalize(cleanPath));
      if (await manager.fileSystem?.exists(uri) != true) {
        if (widget.docDirectory != null && widget.docDirectory!.isNotEmpty) {
          final relPath = p.normalize('${widget.docDirectory}/$cleanPath');
          final relUri = VaultUri(path: relPath);
          if (await manager.fileSystem?.exists(relUri) == true) {
            uri = relUri;
            cleanPath = relPath;
          }
        }
      }

      // Try loading the PNG preview file first (.excalidraw.png)
      final pngUri = VaultUri(path: '$cleanPath.png');
      if (await manager.fileSystem?.exists(pngUri) == true) {
        final bytes = await manager.readFile(pngUri);
        if (bytes.isNotEmpty && mounted) {
          setState(() {
            _pngBytes = bytes;
            _pngDimensions = _parsePngDimensions(bytes);
          });
        }
      } else {
        // Also try reading PNG from disk directly via the vault root
        final rootPath = manager.rootDirectoryPath;
        if (rootPath != null) {
          var pngFile = File(p.join(rootPath, '$cleanPath.png'));
          if (!await pngFile.exists() &&
              widget.docDirectory != null &&
              widget.docDirectory!.isNotEmpty) {
            pngFile = File(
              p.join(rootPath, widget.docDirectory!, '$cleanPath.png'),
            );
          }
          if (await pngFile.exists()) {
            final bytes = await pngFile.readAsBytes();
            if (bytes.isNotEmpty && mounted) {
              setState(() {
                _pngBytes = bytes;
                _pngDimensions = _parsePngDimensions(bytes);
              });
            }
          }
        }
      }

      // Check whether the .excalidraw file contains elements
      if (await manager.fileSystem?.exists(uri) == true) {
        final bytes = await manager.readFile(uri);
        final jsonStr = utf8.decode(bytes);
        final hasElems = _checkHasElements(jsonStr);
        if (mounted) {
          setState(() {
            _hasElements = hasElems;
          });
        }
      } else {
        final rootPath = manager.rootDirectoryPath;
        if (rootPath != null) {
          var jsonFile = File(p.join(rootPath, cleanPath));
          if (!await jsonFile.exists() &&
              widget.docDirectory != null &&
              widget.docDirectory!.isNotEmpty) {
            jsonFile = File(p.join(rootPath, widget.docDirectory!, cleanPath));
          }
          if (await jsonFile.exists()) {
            final jsonStr = await jsonFile.readAsString();
            final hasElems = _checkHasElements(jsonStr);
            if (mounted) {
              setState(() {
                _hasElements = hasElems;
              });
            }
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loaded = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.drawingPath.contains('/')
        ? widget.drawingPath.split('/').last
        : widget.drawingPath;

    // Real PNG must have dimensions larger than 32x32 (the blank canvas export)
    final bool hasRealPng =
        _pngBytes != null &&
        _pngBytes!.isNotEmpty &&
        _pngDimensions != null &&
        (_pngDimensions!.$1 > 32 || _pngDimensions!.$2 > 32);

    final bool hasContent = _hasElements || hasRealPng;

    if (!_loaded) {
      return Container(
        height: 52,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
        ),
      );
    }

    // Compact placeholder for empty drawings: do not waste vertical space in reading view
    if (!hasContent) {
      return EmptyDrawingPlaceholder(
        fileName: fileName,
        onOpenEditor: widget.onOpenEditor,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Compute height from PNG aspect ratio if available
        double dynamicHeight = widget.height;
        if (hasRealPng) {
          final (pngW, pngH) = _pngDimensions!;
          dynamicHeight = (availableWidth * pngH / pngW).clamp(120.0, 750.0);
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Figma Header Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.gesture_rounded,
                      size: 16,
                      color: Color(0xFF34D399),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.onTag != null) ...[
                      DrawingTagMenuButton(onTag: widget.onTag),
                      const SizedBox(width: 8),
                    ],
                    if (widget.onOpenEditor != null)
                      InkWell(
                        onTap: widget.onOpenEditor,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Studio',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 13,
                                color: AppColors.textPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Drawing Canvas Viewport
              Container(
                height: dynamicHeight,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: hasRealPng
                      ? Image.memory(
                          _pngBytes!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderCard(fileName),
                        )
                      : _buildPlaceholderCard(fileName),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderCard(String fileName) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.brush_outlined,
            size: 32,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            fileName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          if (widget.onOpenEditor != null)
            TextButton.icon(
              onPressed: widget.onOpenEditor,
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Open in Drawing Editor'),
              style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
            ),
        ],
      ),
    );
  }
}
