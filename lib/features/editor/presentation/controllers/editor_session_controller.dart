import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/constants/view_mode.dart';
import 'package:noteflow/features/document/document.dart';

/// State of the editor and workspace panel visibility.
class EditorSessionState {
  final String? selectedFilePath;
  final ViewMode viewMode;
  final List<AtomicUnit> editDocUnits;
  final bool isLeftPanelOpen;
  final bool isRightPanelOpen;
  final bool isFullscreen;

  const EditorSessionState({
    this.selectedFilePath,
    this.viewMode = ViewMode.reading,
    this.editDocUnits = const [],
    this.isLeftPanelOpen = true,
    this.isRightPanelOpen = true,
    this.isFullscreen = false,
  });

  bool get isEditMode => viewMode == ViewMode.editor;
  bool get isReadingMode => viewMode == ViewMode.reading;

  EditorSessionState copyWith({
    String? Function()? selectedFilePath,
    ViewMode? viewMode,
    List<AtomicUnit>? editDocUnits,
    bool? isLeftPanelOpen,
    bool? isRightPanelOpen,
    bool? isFullscreen,
  }) {
    return EditorSessionState(
      selectedFilePath: selectedFilePath != null
          ? selectedFilePath()
          : this.selectedFilePath,
      viewMode: viewMode ?? this.viewMode,
      editDocUnits: editDocUnits ?? this.editDocUnits,
      isLeftPanelOpen: isLeftPanelOpen ?? this.isLeftPanelOpen,
      isRightPanelOpen: isRightPanelOpen ?? this.isRightPanelOpen,
      isFullscreen: isFullscreen ?? this.isFullscreen,
    );
  }
}

/// Controller managing editor state, active file selection, and panel toggling.
class EditorSessionController extends StateNotifier<EditorSessionState> {
  final Ref _ref;

  EditorSessionController(this._ref) : super(const EditorSessionState());

  /// Selects a file and optionally transitions to edit mode.
  void selectFile(String? path, {bool switchToEdit = false}) {
    _ref.read(currentDocumentPathProvider.notifier).state = path;
    state = state.copyWith(
      selectedFilePath: () => path,
      viewMode: switchToEdit ? ViewMode.editor : state.viewMode,
    );
    _syncEditDocUnits();
  }

  /// Switches to Edit Mode with an optional [filePath].
  void switchToEditMode({String? filePath}) {
    String? path = filePath ?? state.selectedFilePath;
    if (path == null) {
      final activeState = _ref.read(activeFolderControllerProvider);
      if (activeState.documents.isNotEmpty) {
        path = activeState.documents.first.uri.path;
      } else if (activeState.orderedFiles.isNotEmpty) {
        path = activeState.orderedFiles.first.uri.path;
      }
    }

    if (path != null) {
      _ref.read(currentDocumentPathProvider.notifier).state = path;
    }

    state = state.copyWith(
      selectedFilePath: () => path,
      viewMode: ViewMode.editor,
    );
    _syncEditDocUnits();
  }

  /// Switches back to Reading Mode.
  void switchToReadMode() {
    state = state.copyWith(viewMode: ViewMode.reading);
  }

  /// Alias for [switchToReadMode].
  void switchToReadingMode() => switchToReadMode();

  /// Sets the active view mode (reading vs editor).
  void setViewMode(ViewMode mode) {
    if (mode == ViewMode.reading) {
      switchToReadMode();
    } else {
      switchToEditMode();
    }
  }

  /// Updates atomic units for the document currently open in editor.
  void updateEditDocUnits(List<AtomicUnit> units) {
    state = state.copyWith(editDocUnits: units);
  }

  void toggleLeftPanel() {
    state = state.copyWith(isLeftPanelOpen: !state.isLeftPanelOpen);
  }

  void toggleRightPanel() {
    state = state.copyWith(isRightPanelOpen: !state.isRightPanelOpen);
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void _syncEditDocUnits() {
    final selected = state.selectedFilePath;
    if (selected == null) {
      state = state.copyWith(editDocUnits: []);
      return;
    }
    final activeState = _ref.read(activeFolderControllerProvider);
    final doc = activeState.documents.cast<NotebookDocument?>().firstWhere(
      (d) => d?.uri.path == selected,
      orElse: () => null,
    );
    if (doc != null) {
      final units = AtomicUnitParser.parseUnits(doc, doc.source.text);
      state = state.copyWith(editDocUnits: units);
    }
  }

  /// Resets state when vault is closed.
  void clear() {
    state = const EditorSessionState();
  }
}

/// Riverpod provider for [EditorSessionController].
final editorSessionControllerProvider =
    StateNotifierProvider<EditorSessionController, EditorSessionState>((ref) {
      return EditorSessionController(ref);
    });
