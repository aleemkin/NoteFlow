import 'dart:typed_data';
import 'package:path/path.dart' as p;

import 'package:noteflow/core/utils/utils.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/features/document/domain/models.dart';

import 'block_scanner.dart';
import 'frontmatter_parser.dart';
import 'markdown_adapter.dart';

/// Assembles a [NotebookDocument] from raw file bytes.
///
/// Pipeline: bytes → source → frontmatter → scan → blocks → document
class DocumentParser {
  DocumentParser._();

  static NotebookDocument parse({
    required Uint8List bytes,
    required VaultUri uri,
  }) {
    final source = DocumentSource.fromBytes(bytes);
    final text = source.text;

    // 1. Parse frontmatter
    final frontmatter = FrontmatterParser.parse(text);
    final documentId = frontmatter.documentId ?? IdGenerator.documentId();

    // 2. Scan blocks
    final scannedBlocks = BlockScanner.scan(text);

    // 3. Convert to DocumentBlock instances (flattening composite / directive blocks)
    final blocks = <DocumentBlock>[];
    for (final scanned in scannedBlocks) {
      final converted = _convertScannedBlock(scanned, uri);
      blocks.addAll(converted);
    }

    // 4. Extract title
    final title = _extractTitle(blocks, uri);

    return NotebookDocument(
      id: documentId,
      uri: uri,
      title: title,
      kind: DocumentKind.markdown,
      blocks: blocks,
      source: source,
    );
  }

  static List<DocumentBlock> _convertScannedBlock(
    ScannedBlock scanned,
    VaultUri docUri,
  ) {
    if (scanned.type == ScannedBlockType.frontmatter ||
        scanned.type == ScannedBlockType.blank) {
      return const [];
    }

    if (scanned.type == ScannedBlockType.markDirective) {
      return _buildMarkedBlocks(scanned, docUri);
    }

    if (scanned.type == ScannedBlockType.viewDirective) {
      return [_buildViewBlock(scanned)];
    }

    final singleBlock = _convertSingleBlock(scanned, docUri);
    return singleBlock != null ? [singleBlock] : const [];
  }

  static DocumentBlock? _convertSingleBlock(
    ScannedBlock scanned,
    VaultUri docUri,
  ) {
    return switch (scanned.type) {
      ScannedBlockType.frontmatter => null,
      ScannedBlockType.blank => null,
      ScannedBlockType.thematicBreak => ThematicBreakBlock(
        id: IdGenerator.blockId(),
        sourceRange: scanned.sourceRange,
      ),
      ScannedBlockType.heading => _buildHeading(scanned),
      ScannedBlockType.paragraph => _buildParagraph(scanned),
      ScannedBlockType.codeBlock => _buildCodeBlock(scanned),
      ScannedBlockType.blockquote => _buildBlockquote(scanned),
      ScannedBlockType.listItem => _buildListItem(scanned),
      ScannedBlockType.table => _buildTable(scanned),
      ScannedBlockType.drawingDirective => _buildDrawing(scanned, docUri),
      ScannedBlockType.viewDirective => _buildViewBlock(scanned),
      ScannedBlockType.markDirective => null, // Handled in _buildMarkedBlocks
      ScannedBlockType.infoReference => _buildInfoRef(scanned),
    };
  }

  static List<DocumentBlock> _buildMarkedBlocks(
    ScannedBlock scanned,
    VaultUri docUri,
  ) {
    final markType = scanned.attributes['markType'] ?? 'imp';
    final markId = scanned.attributes['id'] ?? IdGenerator.markId();

    final mark = SemanticMark(
      id: markId,
      type: markType,
      sourceRange: scanned.sourceRange,
      attrs: {
        if (scanned.attributes.containsKey('title'))
          'title': scanned.attributes['title'],
      },
    );

    final rawContent = scanned.content.trim();
    if (rawContent.isEmpty) return const [];

    // Scan inner blocks inside the directive content
    final innerScanned = BlockScanner.scan(rawContent);
    final validInner = innerScanned
        .where(
          (b) =>
              b.type != ScannedBlockType.blank &&
              b.type != ScannedBlockType.frontmatter,
        )
        .toList();

    if (validInner.isEmpty) {
      return [
        TextBlock(
          id: IdGenerator.blockId(),
          role: TextBlockRole.paragraph,
          inlineContent: MarkdownAdapter.parseInline(rawContent),
          sourceRange: scanned.sourceRange,
          marks: [mark],
        ),
      ];
    }

    final result = <DocumentBlock>[];
    for (final inner in validInner) {
      final innerBlocks = _convertScannedBlock(inner, docUri);
      for (final b in innerBlocks) {
        result.add(_attachMark(b, mark));
      }
    }

    return result;
  }

  static DocumentBlock _attachMark(DocumentBlock block, SemanticMark mark) {
    return switch (block) {
      TextBlock() => TextBlock(
        id: block.id,
        role: block.role,
        inlineContent: block.inlineContent,
        sourceRange: block.sourceRange,
        marks: [mark, ...block.marks],
        headingLevel: block.headingLevel,
        language: block.language,
        listNumber: block.listNumber,
        isTask: block.isTask,
        isChecked: block.isChecked,
      ),
      TableBlock() => TableBlock(
        id: block.id,
        headers: block.headers,
        alignments: block.alignments,
        rows: block.rows,
        sourceRange: block.sourceRange,
        marks: [mark, ...block.marks],
      ),
      ThematicBreakBlock() => ThematicBreakBlock(
        id: block.id,
        sourceRange: block.sourceRange,
        marks: [mark, ...block.marks],
      ),
      ViewBlock() => ViewBlock(
        id: block.id,
        markRef: block.markRef,
        docPath: block.docPath,
        sourceRange: block.sourceRange,
        marks: [mark, ...block.marks],
      ),
      DrawingBlock() => DrawingBlock(
        id: block.id,
        drawingUri: block.drawingUri,
        minHeight: block.minHeight,
        sourceRange: block.sourceRange,
        marks: [mark, ...block.marks],
      ),
    };
  }

  static TextBlock _buildHeading(ScannedBlock scanned) {
    final level = int.tryParse(scanned.attributes['level'] ?? '1') ?? 1;
    final role = switch (level) {
      1 => TextBlockRole.heading1,
      2 => TextBlockRole.heading2,
      3 => TextBlockRole.heading3,
      4 => TextBlockRole.heading4,
      5 => TextBlockRole.heading5,
      _ => TextBlockRole.heading6,
    };
    return TextBlock(
      id: IdGenerator.blockId(),
      role: role,
      inlineContent: MarkdownAdapter.parseInline(scanned.content),
      sourceRange: scanned.sourceRange,
      headingLevel: level,
    );
  }

  static TextBlock _buildParagraph(ScannedBlock scanned) {
    return TextBlock(
      id: IdGenerator.blockId(),
      role: TextBlockRole.paragraph,
      inlineContent: MarkdownAdapter.parseInline(scanned.content),
      sourceRange: scanned.sourceRange,
    );
  }

  static TextBlock _buildCodeBlock(ScannedBlock scanned) {
    return TextBlock(
      id: IdGenerator.blockId(),
      role: TextBlockRole.code,
      inlineContent: [InlineText(scanned.content)],
      sourceRange: scanned.sourceRange,
      language: scanned.attributes['language'],
    );
  }

  static TextBlock _buildBlockquote(ScannedBlock scanned) {
    return TextBlock(
      id: IdGenerator.blockId(),
      role: TextBlockRole.blockquote,
      inlineContent: MarkdownAdapter.parseInline(scanned.content),
      sourceRange: scanned.sourceRange,
    );
  }

  static TextBlock _buildListItem(ScannedBlock scanned) {
    return TextBlock(
      id: IdGenerator.blockId(),
      role: TextBlockRole.listItem,
      inlineContent: MarkdownAdapter.parseInline(scanned.content),
      sourceRange: scanned.sourceRange,
      listNumber: scanned.attributes['listNumber'],
      isTask: scanned.attributes['isTask'] == 'true',
      isChecked: scanned.attributes['isChecked'] == 'true',
    );
  }

  static TableBlock _buildTable(ScannedBlock scanned) {
    final lines = scanned.content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return TableBlock(id: IdGenerator.blockId(), headers: [], rows: []);
    }

    List<String> parseRow(String line) {
      var trimmed = line.trim();
      if (trimmed.startsWith('|')) {
        trimmed = trimmed.substring(1);
      }
      if (trimmed.endsWith('|')) {
        trimmed = trimmed.substring(0, trimmed.length - 1);
      }
      return trimmed.split('|').map((c) => c.trim()).toList();
    }

    final headers = parseRow(lines[0]);
    final alignments = <TableColumnAlign>[];

    if (lines.length > 1) {
      final sepCells = parseRow(lines[1]);
      for (final cell in sepCells) {
        if (cell.startsWith(':') && cell.endsWith(':')) {
          alignments.add(TableColumnAlign.center);
        } else if (cell.endsWith(':')) {
          alignments.add(TableColumnAlign.right);
        } else {
          alignments.add(TableColumnAlign.left);
        }
      }
    }

    final rows = <List<String>>[];
    for (var i = 2; i < lines.length; i++) {
      rows.add(parseRow(lines[i]));
    }

    return TableBlock(
      id: IdGenerator.blockId(),
      headers: headers,
      alignments: alignments,
      rows: rows,
      sourceRange: scanned.sourceRange,
    );
  }

  static ViewBlock _buildViewBlock(ScannedBlock scanned) {
    final markRef = scanned.attributes['ref'] ?? scanned.content.trim();
    final docPath = scanned.attributes['docPath'];
    final id = scanned.attributes['id'] ?? IdGenerator.blockId();

    return ViewBlock(
      id: id,
      markRef: markRef,
      docPath: docPath,
      sourceRange: scanned.sourceRange,
    );
  }

  static DrawingBlock _buildDrawing(ScannedBlock scanned, VaultUri docUri) {
    var rawPath = scanned.attributes['path'] ?? '';
    if (rawPath.isEmpty && scanned.content.isNotEmpty) {
      for (final line in scanned.content.split('\n')) {
        final t = line.trim();
        if (t.isNotEmpty &&
            !t.startsWith('{') &&
            !t.startsWith('@@') &&
            !t.startsWith('@/')) {
          rawPath = t;
          break;
        }
      }
    }

    var id = scanned.attributes['id'];
    if (id == null && scanned.content.isNotEmpty) {
      final idMatch = RegExp(r'#(\S+)').firstMatch(scanned.content);
      if (idMatch != null) {
        id = idMatch.group(1);
      }
    }
    id ??= IdGenerator.blockId();

    var minHeight = double.tryParse(scanned.attributes['minHeight'] ?? '');
    if (minHeight == null && scanned.content.isNotEmpty) {
      final mhMatch = RegExp(
        r'minHeight=(\d+(?:\.\d+)?)',
      ).firstMatch(scanned.content);
      if (mhMatch != null) {
        minHeight = double.tryParse(mhMatch.group(1)!);
      }
    }

    // Resolve drawing path relative to document
    String resolvedPath;
    if (rawPath.startsWith('/')) {
      resolvedPath = rawPath.substring(1);
    } else {
      final rel = rawPath.startsWith('./') ? rawPath.substring(2) : rawPath;
      if (docUri.directory.isNotEmpty) {
        resolvedPath = p.posix.normalize(p.posix.join(docUri.directory, rel));
      } else {
        resolvedPath = p.posix.normalize(rel);
      }
    }

    return DrawingBlock(
      id: id,
      drawingUri: VaultUri(path: resolvedPath),
      minHeight: minHeight,
      sourceRange: scanned.sourceRange,
    );
  }

  static TextBlock _buildInfoRef(ScannedBlock scanned) {
    return TextBlock(
      id: IdGenerator.blockId(),
      role: TextBlockRole.paragraph,
      inlineContent: [InlineText('📎 ${scanned.content}')],
      sourceRange: scanned.sourceRange,
    );
  }

  static String _extractTitle(List<DocumentBlock> blocks, VaultUri uri) {
    for (final block in blocks) {
      if (block is TextBlock && block.headingLevel != null) {
        return block.inlineContent.plainText;
      }
    }
    // Fallback to filename without extension
    final name = uri.fileName;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}
