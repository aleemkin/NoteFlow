#!/usr/bin/env bash
set -e

# Change to the directory of this script (project root)
cd "$(dirname "$0")"

# Ensure Excalidraw web bundle is built before launching Flutter
if [ ! -f "assets/excalidraw/index.html" ]; then
  echo "Excalidraw web bundle not found in assets/excalidraw/. Building now..."
  (cd web_excalidraw && npm install && npm run build)
fi

echo "Launching Noteflow in development mode..."
flutter run -d linux "$@"
