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
import 'editor_components/editor.dart';

export 'editor_components/editor.dart';

/// Side-by-side parallel editor: Raw Editor (left) + Live Interactive Preview (right) with Markdown formatting tools.
class DualPaneEditor extends ConsumerStatefulWidget {
  final String documentPath;
  final VoidCallback? onClose;
  final VoidCallback? onSaved;
  final void Function(String path)? onOpenDrawing;
  final void Function(List<AtomicUnit> units)? onUnitsChanged;

  const DualPaneEditor({
    super.key,
    required this.documentPath,
    this.onClose,
    this.onSaved,
    this.onOpenDrawing,
    this.onUnitsChanged,
  });

  @override
  ConsumerState<DualPaneEditor> createState() => DualPaneEditorState();
}

class DualPaneEditorState extends ConsumerState<DualPaneEditor> {
  NotebookDocument? _liveDocument;
  bool _loading = true;
  String? _error;
  bool _dirty = false;
  bool _isSaving = false;
  String? _saveError;
  String? _syntaxWarning;
  String _frontmatter = '';
  late TextEditingController _rawController;
  final FocusNode _editorFocus = FocusNode();
  Timer? _previewDebounce;
  Timer? _autoSaveDebounce;
  StreamSubscription<VaultChangeBatch>? _fileChangeSub;
  double _splitRatio = 0.5; // Split view ratio

  @override
  void initState() {
    super.initState();
    _rawController = TextEditingController();
    _loadDocument();
    _fileChangeSub = ref
        .read(vaultManagerProvider)
        .onFileChanges
        .listen(_onExternalFileChange);
  }

  void _onExternalFileChange(VaultChangeBatch batch) {
    if (_dirty || _isSaving) return; // Keep user's active uncommitted edits or while saving
    final affectsThisDoc = batch.changes.any(
      (c) =>
          c.uri.path == widget.documentPath &&
          c.type == VaultChangeType.modified,
    );
    if (affectsThisDoc && mounted) {
      _loadDocument(isExternalReload: true);
    }
  }

  @override
  void didUpdateWidget(DualPaneEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentPath != widget.documentPath) {
      _autoSaveDebounce?.cancel();
      _previewDebounce?.cancel();
      if (_dirty) {
        _flushSave(oldWidget.documentPath, _rawController.text);
      }
      _dirty = false;
      _frontmatter = '';
      _saveError = null;
      _syntaxWarning = null;
      _loadDocument();
    }
  }

  @override
  void dispose() {
    _fileChangeSub?.cancel();
    _rawController.dispose();
    _editorFocus.dispose();
    _previewDebounce?.cancel();
    _autoSaveDebounce?.cancel();
    if (_dirty) {
      _flushSave(widget.documentPath, _rawController.text);
    }
    super.dispose();
  }

  Future<void> _loadDocument({bool isExternalReload = false}) async {
    if (!isExternalReload) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final manager = ref.read(vaultManagerProvider);
      final uri = VaultUri(path: widget.documentPath);
      final bytes = await manager.readFile(uri);
      final rawText = utf8.decode(bytes);
      final frontmatter = FrontmatterParser.extractFrontmatter(rawText);
      final bodyText = FrontmatterParser.extractBody(rawText);

      // If this is an external reload and the body text has not changed,
      // ignore it to prevent resetting controller state, focus, or cursor.
      if (isExternalReload && _rawController.text == bodyText) {
        _frontmatter = frontmatter;
        return;
      }

      final doc = DocumentParser.parse(bytes: bytes, uri: uri);
      final units = AtomicUnitParser.parseUnits(doc, bodyText);
      if (mounted) {
        final currentSelection = _rawController.selection;
        final clampedBase = currentSelection.isValid
            ? currentSelection.baseOffset.clamp(0, bodyText.length)
            : bodyText.length;
        final clampedExtent = currentSelection.isValid
            ? currentSelection.extentOffset.clamp(0, bodyText.length)
            : bodyText.length;

        setState(() {
          _liveDocument = doc;
          _frontmatter = frontmatter;
          _rawController.value = TextEditingValue(
            text: bodyText,
            selection: TextSelection(
              baseOffset: clampedBase,
              extentOffset: clampedExtent,
            ),
          );
          _syntaxWarning = EditorSyntaxValidator.validate(bodyText);
          _loading = false;
        });
        widget.onUnitsChanged?.call(units);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _onRawTextChanged(String text) {
    if (!_dirty) {
      setState(() {
        _dirty = true;
        _saveError = null;
      });
    }

    // 1. Check syntax and update live preview (150ms debounce)
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      final syntaxWarning = EditorSyntaxValidator.validate(text);
      try {
        final fullText = FrontmatterParser.combine(_frontmatter, text);
        final bytes = Uint8List.fromList(utf8.encode(fullText));
        final doc = DocumentParser.parse(
          bytes: bytes,
          uri: VaultUri(path: widget.documentPath),
        );
        final units = AtomicUnitParser.parseUnits(doc, text);
        setState(() {
          _liveDocument = doc;
          _syntaxWarning = syntaxWarning;
        });
        widget.onUnitsChanged?.call(units);
      } catch (e) {
        setState(() {
          _syntaxWarning = syntaxWarning ?? 'Syntax error: $e';
        });
      }
    });

    // 2. Debounced auto-save (600ms debounce)
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _autoSave();
    });
  }

  /// Automatically saves the document to disk, handling file I/O errors properly.
  Future<void> _autoSave() async {
    if (!_dirty || widget.documentPath.isEmpty) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final text = _rawController.text;
    final fullText = FrontmatterParser.combine(_frontmatter, text);
    try {
      final ops = ref.read(vaultOperationsProvider);
      await ops.saveFile(VaultUri(path: widget.documentPath), fullText);
      if (mounted) {
        setState(() {
          if (_rawController.text == text) {
            _dirty = false;
          }
          _isSaving = false;
          _saveError = null;
        });
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = 'Save failed: $e';
        });
      }
    }
  }

  void _flushSave([String? path, String? content]) {
    final targetPath = path ?? widget.documentPath;
    final targetContent = content ?? _rawController.text;
    if (targetPath.isEmpty) return;
    try {
      final ops = ref.read(vaultOperationsProvider);
      final fullContent = FrontmatterParser.combine(
        _frontmatter,
        targetContent,
      );
      ops.saveFile(VaultUri(path: targetPath), fullContent);
      widget.onSaved?.call();
    } catch (_) {}
  }

  /// Jumps the editor cursor and viewport to the specified atomic unit / heading.
  void jumpToUnit(AtomicUnit unit) {
    final text = _rawController.text;
    int targetOffset = -1;

    if (unit.targetBlockId.isNotEmpty) {
      final tagIdx = text.indexOf('#${unit.targetBlockId}');
      if (tagIdx != -1) {
        targetOffset = tagIdx;
      }
    }

    if (targetOffset == -1 && unit.title.isNotEmpty) {
      final headingRegex = RegExp(
        '^#{1,6}\\s+${RegExp.escape(unit.title)}',
        multiLine: true,
      );
      final match = headingRegex.firstMatch(text);
      if (match != null) {
        targetOffset = match.start;
      }
    }

    if (targetOffset != -1) {
      _rawController.selection = TextSelection(
        baseOffset: targetOffset,
        extentOffset: (targetOffset + unit.title.length).clamp(0, text.length),
      );
      _editorFocus.requestFocus();
    }
  }

  /// Reorganizes sections within the active markdown note in response to outline reordering.
  void applyReorderedUnits(List<AtomicUnit> newUnits) {
    final buffer = StringBuffer();
    for (var i = 0; i < newUnits.length; i++) {
      final u = newUnits[i];
      buffer.writeln(u.rawMarkdown.trim());
      if (i < newUnits.length - 1) buffer.writeln();
    }
    _rawController.text = buffer.toString();
    _onRawTextChanged(_rawController.text);
  }

  void _wrapSelection(String prefix, [String suffix = '']) =>
      EditorFormattingActions.wrapSelection(
        controller: _rawController,
        focusNode: _editorFocus,
        onTextChanged: _onRawTextChanged,
        prefix: prefix,
        suffix: suffix,
      );

  void _applyTagTemplate([String tagType = 'tag']) =>
      EditorFormattingActions.applyTagTemplate(
        controller: _rawController,
        focusNode: _editorFocus,
        onTextChanged: _onRawTextChanged,
        tagType: tagType,
      );

  void _insertTable() => EditorFormattingActions.insertTable(
    controller: _rawController,
    focusNode: _editorFocus,
    onTextChanged: _onRawTextChanged,
  );

  void _insertLink() => EditorFormattingActions.insertLink(
    controller: _rawController,
    focusNode: _editorFocus,
    onTextChanged: _onRawTextChanged,
  );

  void _insertImage() => EditorFormattingActions.insertImage(
    controller: _rawController,
    focusNode: _editorFocus,
    onTextChanged: _onRawTextChanged,
  );

  void _insertHorizontalRule() => EditorFormattingActions.insertHorizontalRule(
    controller: _rawController,
    focusNode: _editorFocus,
    onTextChanged: _onRawTextChanged,
  );

  void _insertDrawingDirective() async {
    final nameController = TextEditingController(text: 'diagram_1.excalidraw');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert Drawing Diagram'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Diagram file name',
            hintText: 'diagram_1.excalidraw',
          ),
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: const Text('Insert'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      var rawName = name.trim();
      if (rawName.startsWith('./')) rawName = rawName.substring(2);
      final cleanName = rawName.endsWith('.excalidraw')
          ? rawName
          : '$rawName.excalidraw';
      final drawId = 'draw_${DateTime.now().millisecondsSinceEpoch}';
      final directive =
          '\n@@drawing ./$cleanName #$drawId {minHeight=260}\n@@/drawing\n';

      final sel = _rawController.selection;
      final text = _rawController.text;
      final pos = sel.isValid ? sel.baseOffset : text.length;

      _rawController.text =
          text.substring(0, pos) + directive + text.substring(pos);
      _onRawTextChanged(_rawController.text);

      try {
        final ops = ref.read(vaultOperationsProvider);
        final docUri = VaultUri(path: widget.documentPath);
        final drawUri = docUri.directory.isEmpty
            ? VaultUri(path: cleanName)
            : VaultUri(path: '${docUri.directory}/$cleanName');
        await ops.saveFile(drawUri, ExcalidrawTemplate.emptyScene);
      } catch (_) {}
    }
  }

  void _insertViewDirective() => EditorFormattingActions.insertViewDirective(
    controller: _rawController,
    focusNode: _editorFocus,
    onTextChanged: _onRawTextChanged,
  );

  int get _wordCount {
    final text = _rawController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Text(
          'Error loading document: $_error',
          style: const TextStyle(color: AppColors.markDanger),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: EditorKeyboardShortcuts.buildBindings(
        onSave: _autoSave,
        onBold: () => _wrapSelection('**', '**'),
        onItalic: () => _wrapSelection('*', '*'),
        onInsertLink: _insertLink,
        onTagImp: () => _applyTagTemplate('imp'),
        onTagInfo: () => _applyTagTemplate('info'),
        onTagTodo: () => _applyTagTemplate('todo'),
        onTagReview: () => _applyTagTemplate('review'),
        onInsertDrawing: _insertDrawingDirective,
      ),
      child: Focus(
        autofocus: true,
        child: Material(
          color: AppColors.background,
          child: Column(
            children: [
              // Top Editor Toolbar
              EditorToolbar(
                documentPath: widget.documentPath,
                documentTitle: _liveDocument?.title,
                wordCount: _wordCount,
                isSaving: _isSaving,
                isDirty: _dirty,
                saveError: _saveError,
                syntaxWarning: _syntaxWarning,
                onClose: widget.onClose,
                onWrapSelection: _wrapSelection,
                onApplyTagTemplate: _applyTagTemplate,
                onInsertTable: _insertTable,
                onInsertLink: _insertLink,
                onInsertImage: _insertImage,
                onInsertHorizontalRule: _insertHorizontalRule,
                onInsertDrawingDirective: _insertDrawingDirective,
                onInsertViewDirective: _insertViewDirective,
                onAutoSave: _autoSave,
              ),
              const Divider(height: 1),

              // Editor Body: Always Split Layout (Raw Editor + Draggable Split Divider + Synchronized Preview)
              Expanded(
                child: EditorSplitLayout(
                  splitRatio: _splitRatio,
                  onSplitRatioChanged: (newRatio) {
                    setState(() {
                      _splitRatio = newRatio;
                    });
                  },
                  controller: _rawController,
                  focusNode: _editorFocus,
                  onChanged: _onRawTextChanged,
                  document: _liveDocument,
                  syntaxWarning: _syntaxWarning,
                  onEditDrawing: widget.onOpenDrawing,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
