import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/features/canvas/data/drawing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DrawingService Unit & Integration Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('drawing_service_test_');
      DrawingService.instance.setVaultRoot(tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('generates secure native scheme URLs', () {
      final editorUrl = DrawingService.instance.getEditorUrlFor(
        'diagrams/flow.excalidraw',
      );
      expect(
        editorUrl,
        equals('nview://excalidraw/index.html?path=diagrams%2Fflow.excalidraw'),
      );

      final readOnlyUrl = DrawingService.instance.getReadOnlyUrlFor(
        'diagrams/flow.excalidraw',
      );
      expect(
        readOnlyUrl,
        equals(
          'nview://excalidraw/index.html?path=diagrams%2Fflow.excalidraw&readonly=true&lockHorizontal=true',
        ),
      );
    });

    test('saves and loads drawing JSON file directly to vault disk', () async {
      const filePath = 'my_sketch.excalidraw';
      final mockData = jsonEncode({
        'type': 'excalidraw',
        'version': 2,
        'source': 'noteflow',
        'elements': [
          {
            'id': 'el1',
            'type': 'rectangle',
            'x': 50,
            'y': 50,
            'width': 100,
            'height': 80,
          },
        ],
      });

      final savedEvents = <String>[];
      final sub = DrawingService.instance.onFileSaved.listen(savedEvents.add);

      await DrawingService.instance.saveDrawingFile(filePath, mockData);

      // Verify file written to disk
      final fileOnDisk = File('${tempDir.path}/$filePath');
      expect(await fileOnDisk.exists(), isTrue);
      final diskContent = await fileOnDisk.readAsString();
      expect(diskContent, equals(mockData));

      // Verify loaded content matches
      final loadedContent = await DrawingService.instance.loadDrawingFile(
        filePath,
      );
      expect(loadedContent, equals(mockData));

      // Verify notification event fired
      expect(savedEvents, contains(filePath));

      await sub.cancel();
    });

    test('saves PNG preview bytes alongside excalidraw file', () async {
      const filePath = 'architecture.excalidraw';
      final mockPngBytes = [
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0,
        1,
        2,
        3,
      ];

      final savedEvents = <String>[];
      final sub = DrawingService.instance.onFileSaved.listen(savedEvents.add);

      await DrawingService.instance.savePreviewFile(filePath, mockPngBytes);

      final pngFileOnDisk = File('${tempDir.path}/$filePath.png');
      expect(await pngFileOnDisk.exists(), isTrue);
      final readBytes = await pngFileOnDisk.readAsBytes();
      expect(readBytes, equals(mockPngBytes));

      expect(savedEvents, contains(filePath));

      await sub.cancel();
    });
  });
}
