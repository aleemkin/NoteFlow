# noteflow

A fast, local-first knowledge notebook combining seamless Markdown editing with embedded, official Excalidraw diagrams.

---

## Key Features

- **Continuous Notebook Roll (Reading View)**: Read through all notes in a folder as a continuous, unified stream with smooth scrolling.
- **Embedded Excalidraw Diagrams**: Diagrams embedded via `@@drawing` directives render with pixel-perfect Virgil/Excalifont sketchy typography and auto-scaled aspect ratios.
- **Official Excalidraw Editor**: Built with the official `@excalidraw/excalidraw` React engine, featuring hand-drawn shapes, arrows, text binding, dark mode, roughness options, and keyboard shortcuts.
- **Instant Floating Action Toolbar**: Select any text in the reading view to instantly insert diagrams above/below, tag as Important (`@@imp`), Reference (`@@info`), or apply custom tags.
- **Local-First & Offline**: All files, notes (`.md`), and drawings (`.excalidraw`, `.excalidraw.png`) live in plain files on your local drive. No cloud login required.
- **Zero-Network Native Protocol (`nview://`)**: Native WebKit C++ custom URI scheme handler streams the bundled Excalidraw web app directly in memory—no local HTTP daemon, no open TCP ports, 100% offline.

---

## Architecture Overview

```
noteflow/
├── lib/
│   ├── src/
│   │   ├── app/           # Riverpod providers, theme, routing
│   │   ├── document/      # Document AST model & Markdown parser
│   │   ├── drawing/       # Zero-network DrawingService & scene models
│   │   ├── platform/      # Vault URI & file system abstraction
│   │   ├── render/        # Continuous roll surface & block renderers
│   │   └── ui/            # Screens, tree sidebar, properties panels
│   └── main.dart          # Flutter entrypoint
├── linux/
│   └── runner/
│       └── my_application.cc  # WebKit custom scheme handler (nview://)
├── web_excalidraw/        # React + Vite source for the official Excalidraw engine
│   ├── src/
│   │   ├── App.jsx        # Excalidraw wrapper, REST sync & PNG preview exporter
│   │   └── main.jsx
│   ├── copy-fonts.js      # Cross-platform font copier for Excalifont/Virgil fonts
│   ├── package.json
│   └── vite.config.js     # Builds bundle into assets/excalidraw/
└── assets/
    └── excalidraw/        # Built web bundle (gitignored, see EXCALIDRAW_GUIDE.md)
```

> 📖 For an in-depth explanation of the custom native scheme, font bundling, and developer workflow, see the **[Excalidraw Integration Guide](EXCALIDRAW_GUIDE.md)**.

---

## Prerequisites

1. **Flutter SDK**: Dart 3.12+ and Flutter 3.24+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
2. **Node.js & npm**: Node 18+ and npm 9+ ([Install Node.js](https://nodejs.org/))
3. **Linux Desktop Dependencies** (Ubuntu/Debian):
   ```bash
   sudo apt update
   sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev libwebkit2gtk-4.1-dev
   ```
   *(Fedora: `sudo dnf install clang cmake ninja-build gtk3-devel webkit2gtk4.1-devel`)*

---

## Quick Start (Run in Development)

You can launch `noteflow` immediately using the included helper script (which builds the Excalidraw web bundle if missing, fetches dependencies, and starts Flutter):

```bash
./run.sh
```

Or run manually:

```bash
# 1. Build the Excalidraw web bundle
cd web_excalidraw && npm install && npm run build && cd ..

# 2. Get Flutter packages
flutter pub get

# 3. Launch with Flutter
flutter run -d linux
```

---

## Bundling & Packaging for Release

To compile a standalone, high-performance desktop release bundle that can run on any compatible Linux system without needing Flutter or Node.js installed:

### Automated Bundling (Single Command)

```bash
./bundle.sh
```

### Manual Step-by-Step Bundling

```bash
# Step 1: Compile the production Excalidraw web bundle
cd web_excalidraw
npm install
npm run build
cd ..

# Step 2: Install Flutter dependencies
flutter pub get

# Step 3: Build the standalone Linux binary bundle
flutter build linux --release
```

### Output Bundle Structure

The compiled standalone application is output to:
```
build/linux/x64/release/bundle/
├── noteflow                       # Main executable binary
├── data/
│   ├── flutter_assets/          # Bundled assets (including assets/excalidraw/)
│   └── icudtl.dat               # ICU localization data
└── lib/
    ├── libflutter_linux_gtk.so  # Flutter GTK engine library
    └── libwindow_manager_plugin.so
```

### Running the Bundled Application

To launch your compiled release app:

```bash
./build/linux/x64/release/bundle/noteflow
```

### Creating a Distributable Archive (.tar.gz)

To create a portable distribution package ready to share:

```bash
tar -czvf noteflow-linux-x64.tar.gz -C build/linux/x64/release/bundle .
```
Users can extract this archive anywhere and double-click or run `./noteflow`.

---

## Usage Guide

### Opening a Vault
- Click **Open Vault** on the welcome screen to select any local folder containing Markdown files and diagrams.
- The sidebar displays your folder hierarchy, notes, and diagrams.

### Reading View vs. Editor View
- **Reading View (Notebook Roll)**: Renders all notes in the current folder continuously. Embedded drawings display as high-resolution raster previews with exact aspect ratio scaling, free of scroll interference.
- **Editor View**: Double-click any note to open the Markdown editor, or click the **Open in Drawing Editor** icon (`↗`) on any diagram card to open full-screen Excalidraw.

### Keyboard Shortcuts in Drawing Editor
- <kbd>Ctrl</kbd> + <kbd>S</kbd> (or <kbd>Cmd</kbd> + <kbd>S</kbd>): Immediately save drawing to disk and update reading view preview.
- Auto-save: Changes are automatically saved after 1.5 seconds of inactivity.

### Markdown Directives Supported

```markdown
# My Note

Here is an important point:
@@imp
This will be highlighted with an accent bar and filtered in Key Highlights view.
@@

Reference notes:
@@info
Helpful reference link or formula.
@@

Embedded Excalidraw diagram:
@@drawing ./architecture.excalidraw
@@

Single-line shorthand:
@@imp> This line is marked as important.

Cross-vault transclusion (preview a tagged block from another note):
@@view #mark-id
@@view notes/meeting.md#key-insight
```

---

## Development & Testing

### Running Tests
```bash
# Run all unit and widget tests:
flutter test

# Run DrawingService unit tests:
flutter test test/drawing_service_test.dart
```

### Static Analysis
```bash
flutter analyze
```

### Modifying the Excalidraw Integration
The Excalidraw source is located in `web_excalidraw/src/App.jsx`. Whenever you make changes:
```bash
cd web_excalidraw
npm run build
cd ..
```
The newly built bundle is placed in `assets/excalidraw/` (gitignored). See [EXCALIDRAW_GUIDE.md](EXCALIDRAW_GUIDE.md) for full architecture details and development workflow.
