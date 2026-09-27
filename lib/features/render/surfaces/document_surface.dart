import 'package:flutter/material.dart';

import 'package:noteflow/features/document/domain/models.dart';

import '../blocks/block_renderer.dart';
import 'package:noteflow/features/knowledge/data/link_resolver.dart';

/// Renders a single [NotebookDocument] as a scrollable pure dark view with clean typography.
class DocumentSurface extends StatelessWidget {
  /// The document to render.
  final NotebookDocument document;

  /// Callback when the user taps to edit an embedded drawing.
  final void Function(String path)? onEditDrawing;

  /// Custom padding if specified, otherwise adapts per device.
  final EdgeInsetsGeometry? padding;

  /// Creates a [DocumentSurface] instance.
  const DocumentSurface({
    super.key,
    required this.document,
    this.onEditDrawing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final docLanes = GutterLaneAllocator.computeLanes(document.blocks);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        final resolvedPadding =
            padding ??
            EdgeInsets.symmetric(
              horizontal: isMobile ? 14.0 : (isTablet ? 28.0 : 48.0),
              vertical: isMobile ? 16.0 : (isTablet ? 24.0 : 36.0),
            );

        return Container(
          color: Theme.of(
            context,
          ).scaffoldBackgroundColor, // Pure black background
          child: SelectionArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: resolvedPadding,
                  sliver: SliverList.builder(
                    itemCount: document.blocks.length,
                    itemBuilder: (context, index) {
                      final block = document.blocks[index];
                      final prevBlock = index > 0
                          ? document.blocks[index - 1]
                          : null;
                      final nextBlock = index < document.blocks.length - 1
                          ? document.blocks[index + 1]
                          : null;
                      return GutterBlockWrapper(
                        block: block,
                        prevBlock: prevBlock,
                        nextBlock: nextBlock,
                        markLanes: docLanes[block.id],
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildBlockWidget(block),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockWidget(DocumentBlock block) {
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
      ),
      DrawingBlock() => DrawingBlockRenderer(
        drawingPath: block.drawingUri.path,
        docDirectory: document.uri.directory,
        height: block.minHeight ?? 260,
        onOpenEditor: onEditDrawing != null
            ? () => onEditDrawing!(block.drawingUri.path)
            : null,
      ),
      ViewBlock() => _buildViewBlock(block),
    };
  }

  Widget _buildViewBlock(ViewBlock block) {
    final resolution = LinkResolver.resolveMarkRef(
      markRef: block.markRef,
      docPath: block.docPath,
      currentDoc: document,
      allDocs: [document],
    );

    Widget? resolvedWidget;
    String? markType;
    if (resolution != null) {
      markType = resolution.mark.type;
      if (resolution.block is! ViewBlock) {
        resolvedWidget = _buildBlockWidget(resolution.block);
      }
    }

    return ViewBlockRenderer(
      markRef: block.markRef,
      docPath: block.docPath,
      docDirectory: document.uri.directory,
      markType: markType,
      resolvedContent: resolvedWidget,
    );
  }
}
