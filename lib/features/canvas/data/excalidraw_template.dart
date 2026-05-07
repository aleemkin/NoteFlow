/// Standard templates for creating Excalidraw vector diagram files.
class ExcalidrawTemplate {
  const ExcalidrawTemplate._();

  /// Standard empty Excalidraw diagram JSON content.
  static const String emptyScene = '''{
  "type": "excalidraw",
  "version": 2,
  "source": "noteflow",
  "elements": [],
  "appState": {
    "viewBackgroundColor": "#000000"
  }
}''';
}
