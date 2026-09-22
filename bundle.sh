#!/usr/bin/env bash
set -e

# Change to the directory of this script (project root)
cd "$(dirname "$0")"

echo "=========================================================="
echo "  Building noteflow: Excalidraw + Flutter Desktop"
echo "=========================================================="

echo ""
echo "-> Step 1/3: Compiling Excalidraw Web Bundle..."
cd web_excalidraw
npm install
npm run build
cd ..

echo ""
echo "-> Step 2/3: Fetching Flutter Dependencies..."
flutter pub get

echo ""
echo "-> Step 3/3: Compiling Linux Release Application..."
flutter build linux --release

echo ""
echo "=========================================================="
echo "  BUILD SUCCESSFUL!"
echo ""
echo "  Standalone bundle created at:"
echo "    build/linux/x64/release/bundle/"
echo ""
echo "  To launch the standalone app:"
echo "    ./build/linux/x64/release/bundle/noteflow"
echo ""
echo "  To package as a portable archive:"
echo "    tar -czvf noteflow-linux-x64.tar.gz -C build/linux/x64/release/bundle ."
echo "=========================================================="
