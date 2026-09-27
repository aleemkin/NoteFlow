import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/core/platform/vault_change.dart';
import 'package:noteflow/features/document/domain/models.dart';
import 'package:noteflow/features/document/parsing/document_parser.dart';
import 'package:noteflow/features/knowledge/data/link_resolver.dart';
import 'package:noteflow/features/vault/domain/vault_tree_node.dart';

import 'blockquote_renderer.dart';
import 'code_block_renderer.dart';
import 'drawing_block_renderer.dart';
import 'heading_block_renderer.dart';
import 'list_item_renderer.dart';
import 'paragraph_block_renderer.dart';
import 'table_block_renderer.dart';
import 'thematic_break_renderer.dart';

/// Renders a transclusion preview of a referenced tagged block.
///
/// Displays the referenced block content inside a dashed-border container
/// with a provenance link showing the source document path.
/// If content is not pre-resolved and [docPath] is provided, resolves the
/// referenced note on demand asynchronously from the vault.
class ViewBlockRenderer extends ConsumerStatefulWidget {
  /// The mark ID being referenced.
  final String markRef;

  /// Optional document path for cross-document references.
  final String? docPath;

  /// Optional directory of the host document, used to resolve relative paths.
  final String? docDirectory;

  /// The semantic mark type (e.g. 'imp', 'info', 'todo') if resolved.
  final String? markType;

  /// The resolved block content widgets to display inside the transclusion container.
  /// If null, an unresolved placeholder is shown or resolved asynchronously.
  final Widget? resolvedContent;

  /// Callback when the provenance link is tapped.
  final VoidCallback? onNavigateToSource;

  const ViewBlockRenderer({
    super.key,
    required this.markRef,
    this.docPath,
    this.docDirectory,
    this.markType,
    this.resolvedContent,
    this.onNavigateToSource,
  });

  @override
  ConsumerState<ViewBlockRenderer> createState() => _ViewBlockRendererState();
}

class _ViewBlockRendererState extends ConsumerState<ViewBlockRenderer> {
  Widget? _asyncResolvedWidget;
  String? _asyncMarkType;
  bool _isLoading = false;
  StreamSubscription<VaultChangeBatch>? _changeSub;
  VaultUri? _resolvedUri;

  @override
  void initState() {
    super.initState();
    if (widget.resolvedContent == null && widget.docPath != null) {
      _resolveAsync();
    }
    _setupWatcher();
  }

  void _setupWatcher() {
    try {
      final manager = ref.read(vaultManagerProvider);
      _changeSub = manager.onFileChanges.listen((batch) {
        if (!mounted || widget.resolvedContent != null) return;
        final targetPath = _resolvedUri?.path ?? widget.docPath;
        if (targetPath != null) {
          final changed = batch.changes.any(
            (c) =>
                c.uri.path == targetPath ||
                c.uri.path.endsWith(targetPath) ||
                (widget.docDirectory != null &&
                    c.uri.path.endsWith(
                      '${widget.docDirectory}/$targetPath',
                    )),
          );
          if (changed) {
            _resolveAsync();
          }
        }
      });
    } catch (_) {
      // Ignored: Missing ProviderScope in unit tests or uninitialized vault manager
    }
  }

  @override
  void didUpdateWidget(ViewBlockRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resolvedContent != null) {
      if (_asyncResolvedWidget != null || _asyncMarkType != null) {
        setState(() {
          _asyncResolvedWidget = null;
          _asyncMarkType = null;
          _isLoading = false;
        });
      }
    } else if (widget.docPath != null &&
        (oldWidget.docPath != widget.docPath ||
            oldWidget.markRef != widget.markRef ||
            oldWidget.docDirectory != widget.docDirectory ||
            oldWidget.resolvedContent != null)) {
      _resolveAsync();
    }
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    super.dispose();
  }

  Future<void> _resolveAsync() async {
    if (widget.docPath == null) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final manager = ref.read(vaultManagerProvider);
      var cleanPath = widget.docPath!.trim();
      if (cleanPath.startsWith('./')) cleanPath = cleanPath.substring(2);
      while (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }

      VaultUri? targetUri;
      final directUri = VaultUri(path: p.normalize(cleanPath));
      if (await manager.fileSystem?.exists(directUri) == true) {
        targetUri = directUri;
      } else if (widget.docDirectory != null &&
          widget.docDirectory!.isNotEmpty) {
        final relUri = VaultUri(
          path: p.normalize('${widget.docDirectory}/$cleanPath'),
        );
        if (await manager.fileSystem?.exists(relUri) == true) {
          targetUri = relUri;
        }
      }

      if (targetUri == null) {
        final files = manager.treeRepository.allSupportedFiles;
        final match = files.cast<VaultTreeNode?>().firstWhere(
              (f) =>
                  f != null &&
                  (f.uri.path == cleanPath || f.uri.path.endsWith(cleanPath)),
              orElse: () => null,
            );
        if (match != null) {
          targetUri = match.uri;
        }
      }

      targetUri ??= directUri;

      final bytes = await manager.readFile(targetUri);
      final doc = DocumentParser.parse(bytes: bytes, uri: targetUri);
      final resolution = LinkResolver.resolveMarkRef(
        markRef: widget.markRef,
        docPath: targetUri.path,
        currentDoc: doc,
        allDocs: [doc],
      );

      if (mounted) {
        if (resolution != null) {
          setState(() {
            _resolvedUri = targetUri;
            _asyncMarkType = resolution.mark.type;
            if (resolution.block is! ViewBlock) {
              _asyncResolvedWidget = _buildBlockWidget(
                resolution.block,
                targetUri!,
              );
            }
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {
      // Ignored: ProviderScope absent or file I/O error
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  static Color _badgeColor(String type) => switch (type.toLowerCase()) {
    'imp' || 'important' => AppColors.markImportant,
    'info' => AppColors.markInfo,
    'todo' => AppColors.secondary,
    'review' => AppColors.accent,
    'question' => AppColors.markImportant,
    'architecture' => AppColors.accent,
    'decision' => AppColors.primary,
    _ => AppColors.markTag,
  };

  static Widget _buildBlockWidget(DocumentBlock block, VaultUri docUri) {
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
        docDirectory: docUri.directory,
        height: block.minHeight ?? 260,
      ),
      ViewBlock() => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final effectiveContent = widget.resolvedContent ?? _asyncResolvedWidget;
    final effectiveMarkType = widget.markType ?? _asyncMarkType;
    final accentColor = effectiveMarkType != null
        ? _badgeColor(effectiveMarkType)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color:
                accentColor?.withValues(alpha: 0.35) ?? AppColors.borderSubtle,
          ),
          borderRadius: BorderRadius.circular(8.0),
          color: AppColors.surfaceCard.withValues(alpha: 0.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Provenance header
            InkWell(
              onTap: widget.onNavigateToSource,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7.0),
                topRight: Radius.circular(7.0),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7.0),
                    topRight: Radius.circular(7.0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      size: 13,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.docPath != null
                            ? '${widget.docPath}#${widget.markRef}'
                            : '#${widget.markRef}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    if (effectiveMarkType != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        effectiveMarkType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: accentColor,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (widget.onNavigateToSource != null)
                      const Tooltip(
                        message: 'Jump to original tagged block',
                        child: Icon(
                          Icons.open_in_new,
                          size: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Content area
            if (effectiveContent != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14.0, 8.0, 14.0, 12.0),
                child: effectiveContent,
              )
            else if (_isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 10.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Resolving #${widget.markRef}...',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14.0, 12.0, 14.0, 12.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Referenced mark #${widget.markRef} not found',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
