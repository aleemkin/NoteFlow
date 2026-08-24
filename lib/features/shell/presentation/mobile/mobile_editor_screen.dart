import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/document.dart';
import 'package:noteflow/features/canvas/canvas.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/vault/presentation/dialogs/vault_dialogs.dart';
import 'package:noteflow/features/canvas/presentation/screens/drawing_editor_screen.dart';
import 'package:noteflow/features/editor/presentation/widgets/editor_components/editor.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';

import 'mobile_editor_accessory_bar.dart';

/// Mobile-first document editor tailored for Android touch screens.
///
/// Features:
/// - Single, clean mobile app bar with back navigation & auto-save status
/// - Segmented Edit / Preview toggle
/// - Keyboard-docked Markdown accessory toolbar (H1-H3, Bold, Lists, Diagrams)
/// - Auto-save with debouncing & dirty state tracking
/// - Seamless Excalidraw integration for `.excalidraw` drawings
class MobileEditorScreen extends ConsumerStatefulWidget {
  final String? documentPath;
  final VoidCallback? onClose;
  final void Function(String path)? onOpenDrawing;
  final VoidCallback? onOpenFiles;
  final VoidCallback? onCreateNote;

  const MobileEditorScreen({
    super.key,
    required this.documentPath,
    this.onClose,
    this.onOpenDrawing,
    this.onOpenFiles,
    this.onCreateNote,
  });

  @override
  ConsumerState<MobileEditorScreen> createState() => _MobileEditorScreenState();
}

class _MobileEditorScreenState extends ConsumerState<MobileEditorScreen> {
  late final PageController _pageController;
  NotebookDocument? _liveDocument;
  bool _loading = true;
  bool _dirty = false;
  String? _syntaxWarning;
  String _frontmatter = '';
  late TextEditingController _rawController;
  final FocusNode _editorFocus = FocusNode();
  Timer? _previewDebounce;
  Timer? _autoSaveDebounce;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _rawController = TextEditingController();
    if (widget.documentPath != null) {
      _loadDocument();
    } else {
      _loading = false;
    }
  }

  @override
  void didUpdateWidget(MobileEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentPath != widget.documentPath) {
      _autoSaveDebounce?.cancel();
      _previewDebounce?.cancel();
      if (_dirty && oldWidget.documentPath != null) {
        _flushSave(oldWidget.documentPath!, _rawController.text);
      }
      _dirty = false;
      _frontmatter = '';
      _syntaxWarning = null;
      if (widget.documentPath != null) {
        _loadDocument();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _rawController.dispose();
    _editorFocus.dispose();
    _previewDebounce?.cancel();
    _autoSaveDebounce?.cancel();
    if (_dirty && widget.documentPath != null) {
      _flushSave(widget.documentPath!, _rawController.text);
    }
    super.dispose();
  }

  Future<void> _loadDocument() async {
    setState(() => _loading = true);
    try {
      final manager = ref.read(vaultManagerProvider);
      final uri = VaultUri(path: widget.documentPath!);
      final bytes = await manager.readFile(uri);
      final rawText = utf8.decode(bytes);
      _frontmatter = FrontmatterParser.extractFrontmatter(rawText);
      final bodyText = FrontmatterParser.extractBody(rawText);
      final doc = DocumentParser.parse(bytes: bytes, uri: uri);
      final units = AtomicUnitParser.parseUnits(doc, bodyText);
      if (mounted) {
        setState(() {
          _liveDocument = doc;
          _rawController.text = bodyText;
          _syntaxWarning = EditorSyntaxValidator.validate(bodyText);
          _loading = false;
        });
        ref
            .read(editorSessionControllerProvider.notifier)
            .updateEditDocUnits(units);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onRawTextChanged(String text) {
    if (!_dirty) {
      setState(() => _dirty = true);
    }

    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted || widget.documentPath == null) return;
      final syntaxWarning = EditorSyntaxValidator.validate(text);
      try {
        final fullText = FrontmatterParser.combine(_frontmatter, text);
        final bytes = Uint8List.fromList(utf8.encode(fullText));
        final doc = DocumentParser.parse(
          bytes: bytes,
          uri: VaultUri(path: widget.documentPath!),
        );
        final units = AtomicUnitParser.parseUnits(doc, text);
        setState(() {
          _liveDocument = doc;
          _syntaxWarning = syntaxWarning;
        });
        ref
            .read(editorSessionControllerProvider.notifier)
            .updateEditDocUnits(units);
      } catch (_) {}
    });

    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted && _dirty && widget.documentPath != null) {
        _save();
      }
    });
  }

  Future<void> _save() async {
    if (widget.documentPath == null) return;
    try {
      final ops = ref.read(vaultOperationsProvider);
      final uri = VaultUri(path: widget.documentPath!);
      final fullText = FrontmatterParser.combine(
        _frontmatter,
        _rawController.text,
      );
      await ops.saveFile(uri, fullText);
      if (mounted) {
        setState(() {
          _dirty = false;
        });
      }
    } catch (_) {}
  }

  void _flushSave(String path, String text) {
    try {
      final ops = ref.read(vaultOperationsProvider);
      final fullText = FrontmatterParser.combine(_frontmatter, text);
      ops.saveFile(VaultUri(path: path), fullText);
    } catch (_) {}
  }

  void _parsePreviewNow() {
    if (widget.documentPath == null) return;
    final text = _rawController.text;
    final syntaxWarning = EditorSyntaxValidator.validate(text);
    try {
      final fullText = FrontmatterParser.combine(_frontmatter, text);
      final bytes = Uint8List.fromList(utf8.encode(fullText));
      final doc = DocumentParser.parse(
        bytes: bytes,
        uri: VaultUri(path: widget.documentPath!),
      );
      final units = AtomicUnitParser.parseUnits(doc, text);
      setState(() {
        _liveDocument = doc;
        _syntaxWarning = syntaxWarning;
      });
      ref
          .read(editorSessionControllerProvider.notifier)
          .updateEditDocUnits(units);
    } catch (_) {}
  }

  Future<void> _handleInsertDrawing() async {
    if (widget.documentPath == null) return;
    final parentDir = VaultUri(path: widget.documentPath!).directory;
    final name = await VaultDialogs.showInputDialog(
      context,
      'New Excalidraw Diagram',
      'Diagram name',
      'diagram_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (name == null || name.trim().isEmpty) return;
    final cleanName = name.trim().endsWith('.excalidraw')
        ? name.trim()
        : '${name.trim()}.excalidraw';

    final ops = ref.read(vaultOperationsProvider);
    final uri = parentDir.isEmpty
        ? VaultUri(path: cleanName)
        : VaultUri(path: '$parentDir/$cleanName');

    await ops.saveFile(uri, ExcalidrawTemplate.emptyScene);
    final drawId = 'draw_${DateTime.now().millisecondsSinceEpoch}';
    final directive =
        '\n@@drawing ./$cleanName #$drawId {minHeight=260}\n@@/drawing\n';

    final sel = _rawController.selection;
    final text = _rawController.text;
    final pos = sel.isValid ? sel.baseOffset : text.length;

    _rawController.text =
        text.substring(0, pos) + directive + text.substring(pos);
    _onRawTextChanged(_rawController.text);
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.documentPath;

    if (path == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No note selected',
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a file from the Files tab or create a new one to start writing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  if (widget.onOpenFiles != null)
                    FilledButton.icon(
                      onPressed: widget.onOpenFiles,
                      icon: const AppSvgIcon.folder(
                        color: AppColors.textMuted,
                        width: 18,
                        height: 18,
                      ),
                      label: const Text('Browse Files'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.surfaceCard,
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  if (widget.onCreateNote != null)
                    FilledButton.icon(
                      onPressed: widget.onCreateNote,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('New Note'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (path.endsWith('.excalidraw')) {
      return DrawingEditorScreen(
        drawingPath: path,
        showAppBar: false,
        onClose: widget.onClose,
      );
    }

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) {
          if (page == 1) {
            _parsePreviewNow();
          }
        },
        children: [
          Column(
            children: [
              MobileEditorAccessoryBar(
                controller: _rawController,
                focusNode: _editorFocus,
                onTextChanged: _onRawTextChanged,
                onInsertDrawing: _handleInsertDrawing,
              ),
              Expanded(
                child: EditorRawPane(
                  controller: _rawController,
                  focusNode: _editorFocus,
                  onChanged: _onRawTextChanged,
                ),
              ),
            ],
          ),
          EditorPreviewPane(
            document: _liveDocument,
            syntaxWarning: _syntaxWarning,
            onEditDrawing: widget.onOpenDrawing,
          ),
        ],
      ),
    );
  }
}
