import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_all/webview_all.dart';
import 'package:webview_all_android/webview_all_android.dart';

import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/features/canvas/data/drawing_service.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/core/notifications/notifications.dart';
import '../widgets/drawing_canvas_view.dart';
import '../widgets/drawing_editor_app_bar.dart';

/// Full-screen vector drawing editor hosting the REAL official Excalidraw engine
/// inside an embedded WebView, configured with a full-width canvas,
/// dynamic content bounds, and bidirectional local vault persistence.
class DrawingEditorScreen extends ConsumerStatefulWidget {
  final String drawingPath;
  final VoidCallback? onClose;
  final bool showAppBar;

  const DrawingEditorScreen({
    super.key,
    required this.drawingPath,
    this.onClose,
    this.showAppBar = true,
  });

  @override
  ConsumerState<DrawingEditorScreen> createState() =>
      _DrawingEditorScreenState();
}

class _DrawingEditorScreenState extends ConsumerState<DrawingEditorScreen> {
  WebViewController? _webController;
  bool _loading = true;
  bool _dirty = false;
  String? _errorMessage;
  Timer? _loadTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _initExcalidraw();
  }

  @override
  void didUpdateWidget(DrawingEditorScreen old) {
    super.didUpdateWidget(old);
    if (old.drawingPath != widget.drawingPath) {
      _dirty = false;
      _loadDrawingIntoWebView();
    }
  }

  Future<void> _initExcalidraw() async {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      _loadTimeoutTimer?.cancel();
      _loadTimeoutTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _loading) {
          setState(() => _loading = false);
        }
      });

      final manager = ref.read(vaultManagerProvider);
      if (manager.rootDirectoryPath != null) {
        DrawingService.instance.setVaultRoot(manager.rootDirectoryPath!);
      }

      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(const Color(0xFF000000));
      await controller.setOnConsoleMessage((JavaScriptConsoleMessage msg) {
        debugPrint('Excalidraw Console [${msg.level.name}]: ${msg.message}');
      });
      await controller.addJavaScriptChannel(
        'flutter_channel',
        onMessageReceived: (JavaScriptMessage msg) {
          _handleExcalidrawMessage(msg.message);
        },
      );
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              'Excalidraw WebResourceError: ${error.description} (code: ${error.errorCode})',
            );
          },
          onPageFinished: (url) {
            _onPageFinished();
          },
        ),
      );

      if (controller.platform is AndroidWebViewController) {
        final androidController =
            controller.platform as AndroidWebViewController;
        await androidController.setAllowFileAccess(true);
        await androidController.setAllowContentAccess(true);
        await androidController.setMediaPlaybackRequiresUserGesture(false);
        await androidController.setMixedContentMode(
          MixedContentMode.alwaysAllow,
        );
        await AndroidWebViewController.enableDebugging(true);
      }

      if (AppPlatform.isDesktop) {
        final editorUrl = DrawingService.instance.getEditorUrlFor(
          widget.drawingPath,
        );
        await controller.loadRequest(Uri.parse(editorUrl));
      } else {
        await controller.loadFlutterAsset('assets/excalidraw/index.html');
      }

      if (mounted) {
        setState(() {
          _webController = controller;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _onPageFinished() async {
    await _loadDrawingIntoWebView();
    if (mounted) {
      // Keep loading until READY/loaded or timeout after 1.5s
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _loading) {
          setState(() => _loading = false);
        }
      });
    }
  }

  Future<void> _loadDrawingIntoWebView() async {
    if (_webController == null) return;
    try {
      final manager = ref.read(vaultManagerProvider);
      var cleanPath = widget.drawingPath;
      if (cleanPath.startsWith('./')) cleanPath = cleanPath.substring(2);
      final uri = VaultUri(path: cleanPath);

      String? jsonContent;
      if (manager.fileSystem != null && await manager.fileSystem!.exists(uri)) {
        final bytes = await manager.readFile(uri);
        jsonContent = utf8.decode(bytes);
      } else {
        jsonContent = await DrawingService.instance.loadDrawingFile(cleanPath);
      }

      const defaultDrawingJson =
          '{"type":"excalidraw","version":2,"source":"noteflow","elements":[],"appState":{"viewBackgroundColor":"#000000"}}';
      final jsonToInject =
          (jsonContent != null && jsonContent.trim().isNotEmpty)
          ? jsonContent
          : defaultDrawingJson;
      final escapedPath = jsonEncode(cleanPath);
      final escapedJson = jsonEncode(jsonToInject);

      await _webController!.runJavaScript('''
        (function() {
          var p = $escapedPath;
          var j = $escapedJson;
          if (window.setFilePath) window.setFilePath(p);
          else window.__nview_filePath = p;
          if (window.loadScene) {
            window.loadScene(j, p);
          } else {
            window.__nview_pendingScene = { json: j, targetPath: p };
          }
        })();
      ''');
      if (mounted) {
        setState(() => _dirty = false);
      }
    } catch (e) {
      debugPrint('DrawingEditor loadDrawing error: $e');
    }
  }

  void _handleExcalidrawMessage(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'];

      if (type == 'READY' || type == 'REQUEST_LOAD') {
        _loadDrawingIntoWebView();
        if (mounted && _loading) {
          setState(() {
            _loading = false;
            _errorMessage = null;
          });
        }
        return;
      }

      if (type == 'ERROR') {
        final err =
            data['message'] as String? ?? 'Drawing engine encountered an error';
        debugPrint('Excalidraw Web runtime error: $err');
        if (mounted) {
          setState(() {
            _loading = false;
            _errorMessage = err;
          });
        }
        return;
      }

      if (type == 'SCENE_CHANGE') {
        if (!_dirty && mounted) {
          setState(() => _dirty = true);
        }
        return;
      }

      if (type == 'SAVE_DRAWING') {
        final filePath = data['filePath'] as String? ?? widget.drawingPath;
        final jsonContent = data['json'] as String?;
        if (jsonContent != null) {
          _saveDrawingToVault(filePath, jsonContent);
        }
        return;
      }

      if (type == 'SAVE_PREVIEW') {
        final filePath = data['filePath'] as String? ?? widget.drawingPath;
        final base64String = data['base64'] as String?;
        if (base64String != null) {
          _savePreviewToVault(filePath, base64String);
        }
        return;
      }

      if (type == 'SAVED') {
        if (mounted) {
          setState(() => _dirty = false);
        }
        return;
      }
    } catch (_) {}
  }

  Future<void> _saveDrawingToVault(String filePath, String jsonContent) async {
    try {
      final manager = ref.read(vaultManagerProvider);
      var cleanPath = filePath;
      if (cleanPath.startsWith('./')) cleanPath = cleanPath.substring(2);
      final uri = VaultUri(path: cleanPath);

      if (manager.fileSystem != null) {
        await manager.fileSystem!.writeBytes(
          uri,
          Uint8List.fromList(utf8.encode(jsonContent)),
          const NoPrecondition(),
        );
      } else {
        await DrawingService.instance.saveDrawingFile(filePath, jsonContent);
      }
      DrawingService.instance.notifyFileSaved(filePath);
      if (mounted) {
        setState(() => _dirty = false);
      }
    } catch (e) {
      debugPrint('Error saving drawing: $e');
    }
  }

  Future<void> _savePreviewToVault(String filePath, String base64String) async {
    try {
      final pngBytes = base64Decode(base64String);
      final manager = ref.read(vaultManagerProvider);
      var cleanPath = filePath;
      if (cleanPath.startsWith('./')) cleanPath = cleanPath.substring(2);
      final pngUri = VaultUri(path: '$cleanPath.png');

      if (manager.fileSystem != null) {
        await manager.fileSystem!.writeBytes(
          pngUri,
          pngBytes,
          const NoPrecondition(),
        );
      } else {
        await DrawingService.instance.savePreviewFile(filePath, pngBytes);
      }
      DrawingService.instance.notifyFileSaved(filePath);
    } catch (e) {
      debugPrint('Error saving preview: $e');
    }
  }

  Future<void> _save({bool showNotification = true}) async {
    try {
      // Trigger WebView Excalidraw save & PNG preview export
      await _webController?.runJavaScript(
        'if (window.saveSceneNow) { window.saveSceneNow(); }',
      );
      if (mounted) {
        setState(() => _dirty = false);
        if (showNotification) {
          AppNotification.showSuccess(
            context,
            'Drawing and preview snapshot saved to vault.',
            title: 'Drawing Saved',
          );
        }
      }
    } catch (e) {
      if (mounted && showNotification) {
        AppNotification.showError(
          context,
          'Unable to save drawing changes: $e',
          title: 'Save Failed',
        );
      }
    }
  }

  @override
  void dispose() {
    _loadTimeoutTimer?.cancel();
    if (_dirty) {
      try {
        _webController?.runJavaScript(
          'if (window.saveSceneNow) { window.saveSceneNow(); }',
        );
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.drawingPath.contains('/')
        ? widget.drawingPath.split('/').last
        : widget.drawingPath;

    final Widget canvasBody = DrawingCanvasView(
      webController: _webController,
      loading: _loading,
      errorMessage: _errorMessage,
      onRetry: () {
        setState(() {
          _loading = true;
          _errorMessage = null;
        });
        _initExcalidraw();
      },
    );

    final Widget content = widget.showAppBar
        ? Scaffold(
            backgroundColor: const Color(0xFF000000),
            appBar: DrawingEditorAppBar(
              fileName: fileName,
              isDirty: _dirty,
              onClose: widget.onClose != null
                  ? () async {
                      if (_dirty) await _save(showNotification: false);
                      widget.onClose?.call();
                    }
                  : null,
              onSave: () => _save(),
            ),
            body: canvasBody,
          )
        : canvasBody;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
            _save(),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () =>
            _save(),
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: widget.onClose == null,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (_dirty) await _save(showNotification: false);
            widget.onClose?.call();
          },
          child: content,
        ),
      ),
    );
  }
}
