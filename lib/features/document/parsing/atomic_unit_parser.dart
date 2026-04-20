import 'package:noteflow/features/document/domain/models.dart';
import 'package:noteflow/features/document/parsing/block_scanner.dart';
import 'frontmatter_parser.dart';

/// Parses documents into atomic units (file, heading, drawing, section)
/// and handles atomic content redistribution across raw markdown files.
class AtomicUnitParser {
  AtomicUnitParser._();

  /// Parse a document's raw text into discrete atomic units.
  static List<AtomicUnit> parseUnits(NotebookDocument doc, String rawText) {
    final scannedBlocks = BlockScanner.scan(rawText);
    final units = <AtomicUnit>[];

    // Filter out frontmatter and trailing blank blocks
    final contentBlocks = scannedBlocks
        .where((b) => b.type != ScannedBlockType.frontmatter)
        .toList();
    if (contentBlocks.isEmpty) {
      if (rawText.trim().isNotEmpty) {
        units.add(
          AtomicUnit(
            id: 'unit_${doc.id}_0',
            docUri: doc.uri,
            title: doc.title,
            kind: AtomicUnitKind.document,
            rawMarkdown: rawText.trim(),
            targetBlockId: 'doc_header_${doc.uri.path}',
          ),
        );
      }
      return units;
    }

    var currentUnitBlocks = <ScannedBlock>[];
    AtomicUnitKind currentKind = AtomicUnitKind.section;
    String currentTitle = doc.title;
    int currentHeadingLevel = 0;
    String? currentDrawingPath;
    String currentTargetBlockId = 'doc_header_${doc.uri.path}';

    void flushUnit() {
      if (currentUnitBlocks.isEmpty) return;
      final startOff = currentUnitBlocks.first.sourceRange.startOffset;
      final endOff = currentUnitBlocks.last.sourceRange.endOffset;
      final rawChunk = rawText.substring(
        startOff.clamp(0, rawText.length),
        endOff.clamp(0, rawText.length),
      );

      if (rawChunk.trim().isNotEmpty) {
        units.add(
          AtomicUnit(
            id: 'unit_${doc.id}_${units.length}',
            docUri: doc.uri,
            title: currentTitle,
            kind: currentKind,
            headingLevel: currentHeadingLevel,
            rawMarkdown: rawChunk,
            drawingPath: currentDrawingPath,
            targetBlockId: currentTargetBlockId,
          ),
        );
      }
      currentUnitBlocks = [];
    }

    for (var i = 0; i < contentBlocks.length; i++) {
      final block = contentBlocks[i];

      if (block.type == ScannedBlockType.heading) {
        flushUnit();
        final level = int.tryParse(block.attributes['level'] ?? '1') ?? 1;
        currentKind = level == 1 && units.isEmpty
            ? AtomicUnitKind.document
            : AtomicUnitKind.heading;
        currentTitle = block.content.trim();
        currentHeadingLevel = level;
        currentDrawingPath = null;
        currentTargetBlockId = 'heading_${doc.uri.path}_$i';
        currentUnitBlocks.add(block);
      } else if (block.type == ScannedBlockType.drawingDirective) {
        flushUnit();
        currentKind = AtomicUnitKind.drawing;
        final path = block.attributes['path'] ?? 'untitled.excalidraw';
        currentDrawingPath = path;
        final name = path.contains('/') ? path.split('/').last : path;
        currentTitle = 'Diagram: $name';
        currentHeadingLevel = 0;
        currentTargetBlockId =
            block.attributes['id'] ?? 'draw_${doc.uri.path}_$i';
        currentUnitBlocks.add(block);
        flushUnit(); // Drawing directive is an isolated atomic unit
      } else {
        if (currentUnitBlocks.isEmpty) {
          currentKind = AtomicUnitKind.section;
          currentTitle = block.content.split('\n').first;
          if (currentTitle.length > 40) {
            currentTitle = '${currentTitle.substring(0, 37)}...';
          }
          currentHeadingLevel = 0;
          currentDrawingPath = null;
          currentTargetBlockId = 'section_${doc.uri.path}_$i';
        }
        currentUnitBlocks.add(block);
      }
    }

    flushUnit();
    return units;
  }

  /// Parse atomic units for all documents in a folder.
  static List<AtomicUnit> parseFolderUnits(List<NotebookDocument> docs) {
    final allUnits = <AtomicUnit>[];
    for (final doc in docs) {
      final docUnits = parseUnits(doc, doc.source.text);
      allUnits.addAll(docUnits);
    }
    return allUnits;
  }

  /// Extract frontmatter text from a raw markdown file if present.
  static String extractFrontmatter(String rawText) {
    return FrontmatterParser.extractFrontmatter(rawText);
  }

  /// Redistributes a reordered list of atomic units back into file contents.
  /// Returns a map of `filePath -> newContent` (or `filePath -> null` for deleted files).
  static Map<String, String?> redistributeUnitsToFileContents({
    required List<AtomicUnit> units,
    required List<String> originalFilePaths,
    required Map<String, String> originalFrontmatters,
  }) {
    final result = <String, String?>{};
    if (originalFilePaths.isEmpty) return result;

    if (units.isEmpty) {
      for (final f in originalFilePaths) {
        result[f] = null;
      }
      return result;
    }

    final fileUnitsMap = <String, List<AtomicUnit>>{};
    for (final f in originalFilePaths) {
      fileUnitsMap[f] = [];
    }

    // 1. Identify each file's primary anchor unit
    final fileAnchorMap = <String, String>{};
    for (final f in originalFilePaths) {
      AtomicUnit? fallback;
      AtomicUnit? nonDrawing;
      AtomicUnit? primary;

      for (final u in units) {
        if (u.docUri.path == f) {
          fallback ??= u;
          if (u.kind != AtomicUnitKind.drawing) {
            nonDrawing ??= u;
          }
          if (u.kind == AtomicUnitKind.document || u.headingLevel == 1) {
            primary = u;
            break;
          }
        }
      }

      final docUnit = primary ?? nonDrawing ?? fallback;
      if (docUnit != null) {
        fileAnchorMap[f] = docUnit.id;
      }
    }

    var currentFileIdx = 0;

    for (var i = 0; i < units.length; i++) {
      final unit = units[i];

      // Check if we reached the start of the next file
      if (currentFileIdx < originalFilePaths.length - 1) {
        final nextFile = originalFilePaths[currentFileIdx + 1];
        final nextAnchorId = fileAnchorMap[nextFile];

        // If unit matches next file's anchor, and current file has no further units after i
        if (nextAnchorId != null && unit.id == nextAnchorId) {
          final currentFile = originalFilePaths[currentFileIdx];
          final hasLaterFromCurrent = units
              .skip(i)
              .any((u) => u.docUri.path == currentFile);
          if (!hasLaterFromCurrent) {
            currentFileIdx++;
          }
        }
      }

      final activeFile = originalFilePaths[currentFileIdx];
      fileUnitsMap[activeFile]!.add(unit);
    }

    // 2. Assemble file contents
    for (final filePath in originalFilePaths) {
      final assigned = fileUnitsMap[filePath] ?? [];
      if (assigned.isEmpty) {
        // Edge case: No content remains in this file -> mark for deletion
        result[filePath] = null;
      } else {
        final buffer = StringBuffer();
        final fm = originalFrontmatters[filePath] ?? '';
        if (fm.trim().isNotEmpty) {
          buffer.writeln(fm.trim());
          buffer.writeln();
        }
        for (var j = 0; j < assigned.length; j++) {
          final content = assigned[j].rawMarkdown.trim();
          if (content.isNotEmpty) {
            buffer.writeln(content);
            if (j < assigned.length - 1) {
              buffer.writeln();
            }
          }
        }
        result[filePath] = buffer.toString();
      }
    }

    return result;
  }
}
