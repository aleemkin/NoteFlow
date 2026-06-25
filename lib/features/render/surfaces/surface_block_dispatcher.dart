import 'package:flutter/material.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/domain/models.dart';
import 'package:noteflow/features/knowledge/data/link_resolver.dart';
import '../blocks/block_renderer.dart';
import 'scroll_filter_mode.dart';

/// Dispatches [DocumentBlock] models to their corresponding block renderers.
class SurfaceBlockDispatcher {
  SurfaceBlockDispatcher._();

  /// Builds a rendered widget corresponding to [block] within [docUri].
  static Widget buildBlockWidget({
    required DocumentBlock block,
    required VaultUri docUri,
    required ScrollFilterMode filterMode,
    required List<NotebookDocument> documents,
    required Map<String, GlobalKey> blockKeys,
    void Function(String drawingPath)? onEditDrawing,
    void Function(String selectedText, String tagType)? onTagText,
    void Function(String selectedText)? onRemoveTag,
    void Function(VaultUri uri)? onEditDocument,
  }) {
    final isFiltered = filterMode != ScrollFilterMode.all;

    return switch (block) {
      ThematicBreakBlock() => const ThematicBreakRenderer(),
      TableBlock() => TableBlockRenderer(table: block),
      TextBlock(role: TextBlockRole.heading1) => HeadingBlockRenderer(
        inlineContent: block.inlineContent,
        text: block.inlineContent.plainText,
        level: 1,
      ),
      TextBlock(role: TextBlockRole.heading2) => HeadingBlockRenderer(
        inlineContent: block.inlineContent,
        text: block.inlineContent.plainText,
        level: 2,
      ),
      TextBlock(role: TextBlockRole.heading3) => HeadingBlockRenderer(
        inlineContent: block.inlineContent,
        text: block.inlineContent.plainText,
        level: 3,
      ),
      TextBlock(role: TextBlockRole.heading4) => HeadingBlockRenderer(
        inlineContent: block.inlineContent,
        text: block.inlineContent.plainText,
        level: 4,
      ),
      TextBlock(role: TextBlockRole.heading5) => HeadingBlockRenderer(
        inlineContent: block.inlineContent,
        text: block.inlineContent.plainText,
        level: 5,
      ),
      TextBlock(role: TextBlockRole.heading6) => HeadingBlockRenderer(
        inlineContent: block.inlineContent,
        text: block.inlineContent.plainText,
        level: 6,
      ),
      TextBlock(role: TextBlockRole.code) => CodeBlockRenderer(
        code: block.inlineContent.plainText,
        language: block.language,
      ),
      TextBlock(role: TextBlockRole.blockquote) => BlockquoteRenderer(
        inlineContent: block.inlineContent,
        text: block.inlineContent.plainText,
      ),
      TextBlock(role: TextBlockRole.listItem) => ListItemRenderer(
        inlineContent: block.inlineContent,
        text: block.inlineContent.plainText,
        listNumber: block.listNumber,
        isTask: block.isTask,
        isChecked: block.isChecked,
      ),
      TextBlock() => ParagraphBlockRenderer(
        inlineContent: block.inlineContent,
        text: block.inlineContent.plainText,
        isMarked: block.marks.isNotEmpty,
        markType: block.marks.isNotEmpty ? block.marks.first.type : null,
        highlightMark: isFiltered || block.marks.isNotEmpty,
      ),
      DrawingBlock() => DrawingBlockRenderer(
        drawingPath: block.drawingUri.path,
        docDirectory: docUri.directory,
        height: block.minHeight ?? 260,
        onOpenEditor: () => onEditDrawing?.call(block.drawingUri.path),
        onTag: (tagType) {
          if (tagType == '__remove__') {
            onRemoveTag?.call(block.drawingUri.fileName);
          } else {
            onTagText?.call(block.drawingUri.fileName, tagType);
          }
        },
      ),
      ViewBlock() => buildViewBlock(
        block: block,
        docUri: docUri,
        filterMode: filterMode,
        documents: documents,
        blockKeys: blockKeys,
        onEditDrawing: onEditDrawing,
        onTagText: onTagText,
        onRemoveTag: onRemoveTag,
        onEditDocument: onEditDocument,
      ),
    };
  }

  /// Resolves transclusion for a [ViewBlock] using [LinkResolver] and builds its renderer.
  static Widget buildViewBlock({
    required ViewBlock block,
    required VaultUri docUri,
    required ScrollFilterMode filterMode,
    required List<NotebookDocument> documents,
    required Map<String, GlobalKey> blockKeys,
    void Function(String drawingPath)? onEditDrawing,
    void Function(String selectedText, String tagType)? onTagText,
    void Function(String selectedText)? onRemoveTag,
    void Function(VaultUri uri)? onEditDocument,
  }) {
    final currentDoc = documents.cast<NotebookDocument?>().firstWhere(
      (d) => d?.uri == docUri,
      orElse: () => documents.isNotEmpty ? documents.first : null,
    );

    final resolution = LinkResolver.resolveMarkRef(
      markRef: block.markRef,
      docPath: block.docPath,
      currentDoc: currentDoc,
      allDocs: documents,
    );

    Widget? resolvedWidget;
    VoidCallback? onNavigate;
    String? markType;

    if (resolution != null) {
      markType = resolution.mark.type;
      if (resolution.block is! ViewBlock) {
        resolvedWidget = buildBlockWidget(
          block: resolution.block,
          docUri: resolution.sourceDoc.uri,
          filterMode: filterMode,
          documents: documents,
          blockKeys: blockKeys,
          onEditDrawing: onEditDrawing,
          onTagText: onTagText,
          onRemoveTag: onRemoveTag,
          onEditDocument: onEditDocument,
        );
      } else {
        resolvedWidget = const Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            'Recursive transclusion not supported',
            style: TextStyle(
              fontSize: 12.0,
              fontStyle: FontStyle.italic,
              color: AppColors.textMuted,
            ),
          ),
        );
      }

      onNavigate = () {
        final key =
            blockKeys[resolution.block.id] ??
            blockKeys['doc_${resolution.sourceDoc.uri.path}'] ??
            blockKeys['doc_header_${resolution.sourceDoc.uri.path}'];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        } else if (onEditDocument != null) {
          onEditDocument(resolution.sourceDoc.uri);
        }
      };
    }

    final displayDocPath =
        block.docPath ??
        (resolution != null && resolution.sourceDoc.uri != docUri
            ? resolution.sourceDoc.uri.path
            : null);

    return ViewBlockRenderer(
      markRef: block.markRef,
      docPath: displayDocPath,
      markType: markType,
      resolvedContent: resolvedWidget,
      onNavigateToSource: onNavigate,
    );
  }
}
