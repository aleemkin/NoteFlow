import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/features/document/document.dart';
import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/render/render.dart';
import 'package:noteflow/features/vault/vault.dart';

/// State of the currently active folder and its continuous reading roll.
class ActiveFolderState {
  final VaultTreeNode? activeFolder;
  final List<VaultTreeNode> orderedFiles;
  final List<NotebookDocument> documents;
  final List<AtomicUnit> atomicUnits;
  final List<TagSummary> tagSummaries;
  final ScrollFilterMode filterMode;
  final String? customTagFilter;
  final bool isLoading;
  final String? error;

  const ActiveFolderState({
    this.activeFolder,
    this.orderedFiles = const [],
    this.documents = const [],
    this.atomicUnits = const [],
    this.tagSummaries = const [],
    this.filterMode = ScrollFilterMode.all,
    this.customTagFilter,
    this.isLoading = false,
    this.error,
  });

  bool get isEmpty => documents.isEmpty && orderedFiles.isEmpty;

  ActiveFolderState copyWith({
    VaultTreeNode? Function()? activeFolder,
    List<VaultTreeNode>? orderedFiles,
    List<NotebookDocument>? documents,
    List<AtomicUnit>? atomicUnits,
    List<TagSummary>? tagSummaries,
    ScrollFilterMode? filterMode,
    String? Function()? customTagFilter,
    bool? isLoading,
    String? Function()? error,
  }) {
    return ActiveFolderState(
      activeFolder: activeFolder != null ? activeFolder() : this.activeFolder,
      orderedFiles: orderedFiles ?? this.orderedFiles,
      documents: documents ?? this.documents,
      atomicUnits: atomicUnits ?? this.atomicUnits,
      tagSummaries: tagSummaries ?? this.tagSummaries,
      filterMode: filterMode ?? this.filterMode,
      customTagFilter: customTagFilter != null
          ? customTagFilter()
          : this.customTagFilter,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

/// Controller managing active folder documents, continuous scroll roll, tags, and file watching.
class ActiveFolderController extends StateNotifier<ActiveFolderState> {
  final Ref _ref;
  StreamSubscription<VaultChangeBatch>? _fileChangeSub;
  Timer? _fileChangeDebounce;

  ActiveFolderController(this._ref) : super(const ActiveFolderState()) {
    final manager = _ref.read(vaultManagerProvider);
    _fileChangeSub = manager.onFileChanges.listen(_onExternalFileChanges);
  }

  @override
  void dispose() {
    _fileChangeSub?.cancel();
    _fileChangeDebounce?.cancel();
    super.dispose();
  }

  void _onExternalFileChanges(VaultChangeBatch batch) {
    final currentFolder = state.activeFolder;
    if (currentFolder == null) return;

    final activeDir = currentFolder.uri.path;
    final affectsActiveFolder = batch.changes.any((c) {
      final changeDir = c.uri.directory;
      final isSequence =
          c.uri.fileName == 'sequences.json' ||
          c.uri.fileName == 'sequence.json';
      final isDisplayedDoc = state.documents.any(
        (doc) => doc.uri.path == c.uri.path,
      );
      return changeDir == activeDir || isDisplayedDoc || isSequence;
    });

    if (affectsActiveFolder) {
      _fileChangeDebounce?.cancel();
      _fileChangeDebounce = Timer(const Duration(milliseconds: 200), () {
        if (state.activeFolder != null) {
          loadFolder(state.activeFolder!);
        }
      });
    }
  }

  /// Loads and parses all documents in the given [folderNode] in custom sequence order.
  Future<void> loadFolder(VaultTreeNode folderNode) async {
    final isChangingFolder = state.activeFolder?.uri != folderNode.uri;
    state = state.copyWith(
      activeFolder: () => folderNode,
      isLoading: true,
      error: () => null,
      documents: isChangingFolder ? [] : state.documents,
      atomicUnits: isChangingFolder ? [] : state.atomicUnits,
      tagSummaries: isChangingFolder ? [] : state.tagSummaries,
    );

    try {
      final manager = _ref.read(vaultManagerProvider);
      final treeRepo = _ref.read(vaultTreeRepositoryProvider);
      final sequenceService = _ref.read(folderSequenceServiceProvider);

      final currentFolderNode = treeRepo.findNode(folderNode.uri) ?? folderNode;
      final files = await sequenceService.getOrderedFolderFiles(
        currentFolderNode,
      );

      final docs = <NotebookDocument>[];
      for (final file in files) {
        if (!file.uri.path.endsWith('.md')) continue;
        try {
          final bytes = await manager.readFile(file.uri);
          final doc = DocumentParser.parse(bytes: bytes, uri: file.uri);
          docs.add(doc);
        } catch (_) {}
      }

      final atomicUnits = AtomicUnitParser.parseFolderUnits(docs);
      final tagSummaries = TagExtractor.extractTags(docs);

      state = state.copyWith(
        activeFolder: () => currentFolderNode,
        orderedFiles: files,
        documents: docs,
        atomicUnits: atomicUnits,
        tagSummaries: tagSummaries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: () => e.toString());
    }
  }

  /// Refreshes the currently active folder.
  Future<void> refresh() async {
    if (state.activeFolder != null) {
      await loadFolder(state.activeFolder!);
    }
  }

  /// Sets the active filter for the continuous reading stream.
  void setFilter(ScrollFilterMode mode, [String? tag]) {
    state = state.copyWith(filterMode: mode, customTagFilter: () => tag);
  }

  /// Clears active filters, returning to the full continuous reading stream.
  void clearFilter() {
    state = state.copyWith(
      filterMode: ScrollFilterMode.all,
      customTagFilter: () => null,
    );
  }

  /// Clears all folder state when closing a vault.
  void clear() {
    state = const ActiveFolderState();
  }
}

/// Riverpod provider for [ActiveFolderController].
final activeFolderControllerProvider =
    StateNotifierProvider<ActiveFolderController, ActiveFolderState>((ref) {
      return ActiveFolderController(ref);
    });
