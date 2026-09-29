import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:noteflow/core/notifications/notifications.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/domain/models.dart';

import '../blocks/block_renderer.dart';
import 'components/custom_tag_dialog.dart';
import 'document_roll_filter.dart';
import 'surface.dart';
import 'surface_block_dispatcher.dart';

export 'surface.dart';

/// Continuous scroll surface rendering all documents in a folder as a seamless dark stream,
/// with instant floating action toolbar appearing on text selection,
/// and full filter view banner/projection options.
class ContinuousFolderSurface extends StatefulWidget {
  final List<NotebookDocument> documents;
  final ScrollController scrollController;
  final Map<String, GlobalKey> blockKeys;
  final ScrollFilterMode filterMode;
  final String? activeTagFilter;
  final void Function(VaultUri uri)? onEditDocument;
  final void Function(String drawingPath)? onEditDrawing;
  final void Function(String selectedText, String tagType)? onTagText;
  final void Function(String selectedText)? onRemoveTag;
  final void Function(String selectedText, bool above)? onInsertDiagram;
  final VoidCallback? onClearFilter;
  final VoidCallback? onCopyTaggedRoll;
  final VoidCallback? onExportTaggedRoll;

  const ContinuousFolderSurface({
    super.key,
    required this.documents,
    required this.scrollController,
    required this.blockKeys,
    this.filterMode = ScrollFilterMode.all,
    this.activeTagFilter,
    this.onEditDocument,
    this.onEditDrawing,
    this.onTagText,
    this.onRemoveTag,
    this.onInsertDiagram,
    this.onClearFilter,
    this.onCopyTaggedRoll,
    this.onExportTaggedRoll,
  });

  @override
  State<ContinuousFolderSurface> createState() =>
      _ContinuousFolderSurfaceState();
}

class _ContinuousFolderSurfaceState extends State<ContinuousFolderSurface> {
  String? _selectedText;
  bool _contextMenuRendered = false;

  @override
  Widget build(BuildContext context) {
    _contextMenuRendered = false;
    if (widget.documents.isEmpty) {
      return const Center(
        child: Text(
          'This folder is empty.\nCreate notes to start your notebook stream.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, height: 1.6),
        ),
      );
    }

    final filteredDocs = DocumentRollFilter.filter(
      documents: widget.documents,
      filterMode: widget.filterMode,
      activeTagFilter: widget.activeTagFilter,
    );
    final totalMatchingBlocks = filteredDocs.fold<int>(
      0,
      (sum, doc) => sum + doc.blocks.length,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final hPadding = isMobile
            ? 14.0
            : (constraints.maxWidth < 800 ? 28.0 : 40.0);
        final vPadding = isMobile ? 16.0 : 24.0;

        return Container(
          color: AppColors.background,
          child: Stack(
            children: [
              SelectionArea(
                onSelectionChanged: (SelectedContent? content) {
                  final text = content?.plainText.trim() ?? '';
                  if (text.isNotEmpty && text != _selectedText) {
                    setState(() {
                      _selectedText = text;
                    });
                  } else if (text.isEmpty && _selectedText != null) {
                    setState(() {
                      _selectedText = null;
                    });
                  }
                },
                contextMenuBuilder: (context, selectableRegionState) {
                  final text = _selectedText;
                  if (text == null || text.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  _contextMenuRendered = true;

                  return TextSelectionToolbar(
                    anchorAbove:
                        selectableRegionState.contextMenuAnchors.primaryAnchor,
                    anchorBelow:
                        selectableRegionState
                            .contextMenuAnchors
                            .secondaryAnchor ??
                        selectableRegionState.contextMenuAnchors.primaryAnchor,
                    toolbarBuilder: (context, child) => child,
                    children: [
                      FloatingSelectionToolbar(
                        selectedText: text,
                        maxWidth: constraints.maxWidth,
                        onInsertDiagramAbove: () {
                          widget.onInsertDiagram?.call(text, true);
                          selectableRegionState.hideToolbar();
                          setState(() {
                            _selectedText = null;
                          });
                        },
                        onInsertDiagramBelow: () {
                          widget.onInsertDiagram?.call(text, false);
                          selectableRegionState.hideToolbar();
                          setState(() {
                            _selectedText = null;
                          });
                        },
                        onTagImportant: () {
                          widget.onTagText?.call(text, 'imp');
                          selectableRegionState.hideToolbar();
                          setState(() {
                            _selectedText = null;
                          });
                        },
                        onTagInfo: () {
                          widget.onTagText?.call(text, 'info');
                          selectableRegionState.hideToolbar();
                          setState(() {
                            _selectedText = null;
                          });
                        },
                        onCustomTag: () {
                          selectableRegionState.hideToolbar();
                          _showCustomTagDialog(text);
                        },
                        onCopy: () {
                          Clipboard.setData(ClipboardData(text: text));
                          selectableRegionState.hideToolbar();
                          setState(() {
                            _selectedText = null;
                          });
                        },
                        onViewTag: () {
                          _copyViewSnippet(text);
                          selectableRegionState.hideToolbar();
                          setState(() {
                            _selectedText = null;
                          });
                        },
                        onUntag: () {
                          widget.onRemoveTag?.call(text);
                          selectableRegionState.hideToolbar();
                          setState(() {
                            _selectedText = null;
                          });
                        },
                        onDismiss: () {
                          selectableRegionState.hideToolbar();
                          setState(() {
                            _selectedText = null;
                          });
                        },
                      ),
                    ],
                  );
                },
                child: ListView.builder(
                  controller: widget.scrollController,
                  // ignore: deprecated_member_use
                  cacheExtent: 10000,
                  padding: EdgeInsets.symmetric(
                    horizontal: hPadding,
                    vertical: vPadding,
                  ),
                  itemCount:
                      filteredDocs.length +
                      (widget.filterMode != ScrollFilterMode.all ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (widget.filterMode != ScrollFilterMode.all) {
                      if (index == 0) {
                        return TaggedRollBanner(
                          filterMode: widget.filterMode,
                          activeTagFilter: widget.activeTagFilter,
                          totalMatchingBlocks: totalMatchingBlocks,
                          totalDocs: filteredDocs.length,
                          availableWidth: constraints.maxWidth,
                          onCopyTaggedRoll: widget.onCopyTaggedRoll,
                          onExportTaggedRoll: widget.onExportTaggedRoll,
                          onClearFilter: widget.onClearFilter,
                        );
                      }
                      final doc = filteredDocs[index - 1];
                      return Container(
                        key: ValueKey('doc_container_${doc.uri.path}'),
                        child: _buildDocumentSection(context, doc, index > 1),
                      );
                    }

                    final doc = filteredDocs[index];
                    return Container(
                      key: ValueKey('doc_container_${doc.uri.path}'),
                      child: _buildDocumentSection(context, doc, index > 0),
                    );
                  },
                ),
              ),

              // Fallback for headless tests where contextMenuBuilder is not triggered by gestures
              if (_selectedText != null &&
                  _selectedText!.isNotEmpty &&
                  !_contextMenuRendered &&
                  (Theme.of(context).platform == TargetPlatform.linux))
                Positioned(
                  top: 8,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: FloatingSelectionToolbar(
                      selectedText: _selectedText!,
                      maxWidth: constraints.maxWidth,
                      onInsertDiagramAbove: () {
                        final text = _selectedText;
                        if (text != null && text.isNotEmpty) {
                          widget.onInsertDiagram?.call(text, true);
                          setState(() => _selectedText = null);
                        }
                      },
                      onInsertDiagramBelow: () {
                        final text = _selectedText;
                        if (text != null && text.isNotEmpty) {
                          widget.onInsertDiagram?.call(text, false);
                          setState(() => _selectedText = null);
                        }
                      },
                      onTagImportant: () {
                        final text = _selectedText;
                        if (text != null && text.isNotEmpty) {
                          widget.onTagText?.call(text, 'imp');
                          setState(() => _selectedText = null);
                        }
                      },
                      onTagInfo: () {
                        final text = _selectedText;
                        if (text != null && text.isNotEmpty) {
                          widget.onTagText?.call(text, 'info');
                          setState(() => _selectedText = null);
                        }
                      },
                      onCustomTag: () {
                        final text = _selectedText;
                        if (text != null && text.isNotEmpty) {
                          _showCustomTagDialog(text);
                        }
                      },
                      onCopy: () {
                        final text = _selectedText;
                        if (text != null && text.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: text));
                          setState(() => _selectedText = null);
                        }
                      },
                      onViewTag: () {
                        final text = _selectedText;
                        if (text != null && text.isNotEmpty) {
                          _copyViewSnippet(text);
                        }
                      },
                      onUntag: () {
                        final text = _selectedText;
                        if (text != null && text.isNotEmpty) {
                          widget.onRemoveTag?.call(text);
                          setState(() => _selectedText = null);
                        }
                      },
                      onDismiss: () => setState(() => _selectedText = null),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCustomTagDialog(String selectedText) async {
    final slug = await CustomTagDialog.show(context, selectedText);
    if (slug != null && slug.isNotEmpty) {
      widget.onTagText?.call(selectedText, slug);
      setState(() => _selectedText = null);
    }
  }

  Widget _buildDocumentSection(
    BuildContext context,
    NotebookDocument doc,
    bool showDivider,
  ) {
    final docKey =
        widget.blockKeys['doc_${doc.id}'] ??
        widget.blockKeys['doc_${doc.uri.path}'] ??
        widget.blockKeys['doc_header_${doc.uri.path}'];

    final docLanes = GutterLaneAllocator.computeLanes(
      doc.blocks,
      activeFilterTag: _activeFilterTag,
    );

    return Column(
      key: docKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider) ...[
          const SizedBox(height: 24),
          const Divider(
            height: 24,
            thickness: 1,
            color: AppColors.borderSubtle,
          ),
          const SizedBox(height: 8),
        ],

        // Document blocks with left gutter indicators and subtle edit icon on first block
        ...doc.blocks.asMap().entries.map((entry) {
          final index = entry.key;
          final block = entry.value;
          final prevBlock = index > 0 ? doc.blocks[index - 1] : null;
          final nextBlock = index < doc.blocks.length - 1
              ? doc.blocks[index + 1]
              : null;
          final key = widget.blockKeys[block.id];
          final isFirstBlock = index == 0;

          return Container(
            key: key,
            child: GutterBlockWrapper(
              block: block,
              prevBlock: prevBlock,
              nextBlock: nextBlock,
              activeFilterTag: _activeFilterTag,
              markLanes: docLanes[block.id],
              onEdit: isFirstBlock && widget.onEditDocument != null
                  ? () => widget.onEditDocument!(doc.uri)
                  : null,
              child: SurfaceBlockDispatcher.buildBlockWidget(
                block: block,
                docUri: doc.uri,
                filterMode: widget.filterMode,
                documents: widget.documents,
                blockKeys: widget.blockKeys,
                onEditDrawing: widget.onEditDrawing,
                onTagText: widget.onTagText,
                onRemoveTag: widget.onRemoveTag,
                onEditDocument: widget.onEditDocument,
              ),
            ),
          );
        }),
      ],
    );
  }

  String? get _activeFilterTag => switch (widget.filterMode) {
    ScrollFilterMode.importantOnly => 'imp',
    ScrollFilterMode.infoOnly => 'info',
    ScrollFilterMode.customTag => widget.activeTagFilter,
    _ => null,
  };

  void _copyViewSnippet(String selectedText) {
    // Find if the selection belongs to a tagged block across documents
    for (final doc in widget.documents) {
      for (final block in doc.blocks) {
        if (block.marks.isNotEmpty) {
          final blockText = block is TextBlock
              ? block.inlineContent.plainText
              : '';
          if (blockText.contains(selectedText) ||
              selectedText.contains(blockText)) {
            final mark = block.marks.first;
            final snippet = '@@view ${doc.uri.path}#${mark.id}';
            Clipboard.setData(ClipboardData(text: snippet));
            if (mounted) {
              AppNotification.showSuccess(
                context,
                'Directive "$snippet" copied to clipboard.',
                title: 'Transclusion Reference Copied',
              );
            }
            setState(() => _selectedText = null);
            return;
          }
        }
      }
    }

    final markId = 'mark_${DateTime.now().millisecondsSinceEpoch}';
    final snippet = '@@view #$markId';
    Clipboard.setData(ClipboardData(text: snippet));
    if (mounted) {
      AppNotification.showSuccess(
        context,
        'Directive "$snippet" copied to clipboard.',
        title: 'Transclusion Reference Copied',
      );
    }
    setState(() => _selectedText = null);
  }
}
