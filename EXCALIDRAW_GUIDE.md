# Excalidraw Integration Guide & Architecture

This guide explains how **Excalidraw** is integrated into **noteflow**, why the compiled assets are excluded from version control, and how to build, maintain, and extend the drawing subsystem.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Why We Exclude Built Assets from Git](#why-we-exclude-built-assets-from-git)
3. [How web_excalidraw Was Created & What Parts Were Altered](#how-web_excalidraw-was-created--what-parts-were-altered)
4. [The `nview://` Custom Protocol (Zero-Network Architecture)](#the-nview-custom-protocol-zero-network-architecture)
5. [Building the Excalidraw Web Bundle](#building-the-excalidraw-web-bundle)
6. [Data Flow & Persistence](#data-flow--persistence)
7. [Offline Typography & Font Bundling](#offline-typography--font-bundling)
8. [Cross-Platform Implementation](#cross-platform-implementation)
9. [Troubleshooting & FAQs](#troubleshooting--faqs)

---

## Architecture Overview

Rather than creating a simplified Flutter vector canvas, `noteflow` integrates the **official `@excalidraw/excalidraw` React engine** in a sandboxed, hardware-accelerated desktop WebView. This ensures 100% feature parity with Excalidraw—including freehand drawing, curved arrows, text binding, multi-element alignment, library items, themes, and official font styling.

```
noteflow/
├── web_excalidraw/                  # ⚛️ Source code of the Excalidraw React application
│   ├── src/
│   │   ├── App.jsx                  # Main wrapper: scene loader, schema migration & autosave
│   │   ├── main.jsx                 # React root
│   │   └── index.css                # Canvas viewport styling & dark mode overrides
│   ├── copy-fonts.js                # Build script copying offline fonts from node_modules
│   ├── vite.config.js               # Bundler configuration (outputs to assets/excalidraw/)
│   └── package.json                 # Dependencies: react, @excalidraw/excalidraw, vite
├── assets/
│   └── excalidraw/                  # 📦 Generated production bundle (GITIGNORED)
│       ├── .gitkeep                 # Preserves folder in Git
│       ├── index.html               # Entrypoint loaded by desktop WebView
│       ├── assets/                  # Minified JavaScript & CSS bundles
│       └── fonts/                   # Bundled Virgil, Excalifont & monospace font assets
├── linux/
│   └── runner/
│       └── my_application.cc        # 🐧 C++ WebKit custom scheme handler (nview://)
├── lib/src/drawing/
│   ├── drawing_service.dart         # Flutter service managing drawing lifecycle & save events
│   └── excalidraw_file_model.dart   # File paths, names, and JSON scene structures
└── lib/src/ui/screens/
    └── drawing_editor_screen.dart   # Full-screen Flutter WebView container
```

---

## Why We Exclude Built Assets from Git

The compiled bundle in `assets/excalidraw/` contains minified JavaScript chunks (~2-3 MB), source maps, and pre-packaged font binaries.

We keep this directory in `.gitignore` because:
1. **Clean Git History**: Committing generated bundles leads to noisy diffs with thousands of changed lines on every minor UI or React tweak.
2. **Reproducible Builds**: The bundle is deterministic and built directly from `web_excalidraw/` source code using standard `npm run build`.
3. **Packaging Transparency**: Developers can inspect, modify, and rebuild the React wrapper with modern developer tools (Vite, HMR) without git repo bloat.

The folder structure is retained in git using `assets/excalidraw/.gitkeep`.

---

## How web_excalidraw Was Created & What Parts Were Altered

The `web_excalidraw/` directory is a standalone Vite + React application engineered specifically to run inside `noteflow`'s desktop WebKit WebView.

### 1. Project Initialization & Dependencies
The wrapper was bootstrapped from a minimalist React template:
```bash
npm create vite@latest web_excalidraw -- --template react
```

#### Dependencies Added:
- `@excalidraw/excalidraw` (`^0.18.1`): Official Excalidraw canvas component and utility engine.
- `react` & `react-dom` (`^19.0.0`): Core React rendering engine.
- `@vitejs/plugin-react` & `vite` (`^6.2.0`): Fast bundler with Rollup tree-shaking.

---

### 2. Bundler & Asset Pipeline Configuration

#### `vite.config.js`:
The default Vite configuration was altered to package the app as a zero-server, offline bundle:
1. **Relative Path Resolution (`base: './'`)**:
   Standard Vite web apps assume root hosting (`/`). Setting `base: './'` ensures all script, stylesheet, and font imports use relative paths (`./assets/...`), allowing direct execution under `nview://excalidraw/index.html`.
2. **Global Polyfill (`define: { 'process.env': {} }`)**:
   `@excalidraw/excalidraw` references `process.env` internally. Without this define replacement, the browser engine throws `ReferenceError: process is not defined` on startup.
3. **Target Output Directory (`outDir: '../assets/excalidraw'`)**:
   Configures the build output directly into Flutter's asset directory using a portable relative path.
4. **Preserve Assets (`emptyOutDir: false`)**:
   Prevents Vite from wiping `.gitkeep` or existing font assets during clean builds.

#### `copy-fonts.js` (Offline Typography Pipeline):
Excalidraw normally downloads font files dynamically from third-party CDNs. To ensure completely offline capability:
- A custom Node script (`copy-fonts.js`) locates the official `@excalidraw/excalidraw/dist/prod/fonts` directory inside `node_modules` and copies all 9 font families (`Virgil`, `Excalifont`, `Cascadia`, `ComicShanns`, `Xiaolai`, `Assistant`, etc.) directly into `assets/excalidraw/fonts/`.
- This script is chained into the build command in `package.json`:
  ```json
  "scripts": {
    "build": "vite build && node copy-fonts.js"
  }
  ```

---

### 3. Customizations in `src/App.jsx`

The default React entrypoint was completely redesigned to act as a bridge between the Flutter host process and the Excalidraw canvas.

#### A. URL Query Parameter Routing
Rather than hardcoding file paths, `App.jsx` parses query parameters from the window location:
- `path`: The absolute path of the `.excalidraw` file being edited.
- `readonly=true` / `mode=view`: Disables editing capabilities and locks the drawing into a read-only viewport.
- `lockHorizontal=true`: Constrains horizontal scrolling to keep diagrams aligned with markdown columns.

#### B. Bi-Directional Flutter WebKit Bridge
Communication occurs over WebKit's native JavaScript message channel (`window.flutter_channel.postMessage`):
- **Messages Sent to Flutter**:
  - `REQUEST_LOAD`: Dispatched on startup asking Flutter to read the drawing JSON from disk.
  - `SAVE_DRAWING`: Dispatched on changes/save containing the updated JSON elements, app state, and files.
  - `SAVE_PREVIEW`: Dispatched alongside `SAVE_DRAWING` containing a high-resolution 2x PNG base64 string.
  - `HEIGHT_CHANGE` & `SCENE_CHANGE`: Transmits bounding box dimensions (`calculateContentBounds`) so Flutter can dynamically size the viewport.
  - `READY`: Signals that the canvas API has initialized.
- **Global API Hooks Exposed to Flutter**:
  - `window.saveSceneNow()`: Allows Flutter (e.g. before closing a tab, during app shutdown, or on window focus loss) to trigger an immediate save.
  - `window.loadScene(json)`: Allows Flutter to inject new scene data without reloading the WebView.

#### C. Element Schema Migration via `restoreElements`
Hand-crafted `.excalidraw` files, sample vaults, or older diagrams may lack element UUIDs, bounding dimensions, or newer schema fields.
In `loadSceneFromJson()`:
```javascript
const rawElements = parsed.elements || [];
const elements = restoreElements(rawElements, null);
```
Piping raw elements through Excalidraw's `restoreElements` sanitizes the data structure, preventing runtime crashes and blank-screen freezes.

#### D. Dual Persistence & Synchronized 2x PNG Preview Generation
Every save operation produces both:
1. The `.excalidraw` JSON file (vector data for lossless editing).
2. The `.excalidraw.png` raster preview file (rendered at 2x scale with dark background using `exportToBlob`).
This preview is rendered directly inside `ReadingView` continuous roll without having to initialize a heavy WebView instance for each diagram.

#### E. Debounced Auto-Save & Manual Shortcuts
- **1.5s Debounce**: Canvas modifications trigger a 1.5-second debounce timer before saving to avoid excessive disk I/O during active sketching.
- **Load Gatekeeper (`isLoadedRef`)**: Prevents `onChange` from firing during the initial mount phase, ensuring an empty canvas state never accidentally overwrites an existing file on disk.
- **Keyboard Shortcuts**: Captures <kbd>Ctrl+S</kbd> / <kbd>Cmd+S</kbd> to flush pending changes immediately.

#### F. Dark Obsidian Styling & UI Stripping
- **Theme**: Fixed to `theme="dark"` with Obsidian-like dark canvas background (`#000000` / `#12161c`).
- **UI Chrome Stripping**:
  ```javascript
  UIOptions={{
    canvasActions: {
      loadScene: false,
      saveToActiveFile: false,
      saveAsImage: false,
      theme: false,
    },
    welcomeScreen: false,
  }}
  ```
  This removes the Excalidraw cloud menu, open file dialogs, canvas image export buttons, and welcome overlays so that `noteflow`'s native menus and shortcuts govern all file I/O and UI actions.

---

## The `nview://` Custom Protocol (Zero-Network Architecture)

Earlier versions ran a local HTTP daemon (`localhost:8080`) on an open TCP socket. This introduced several problems:
- Firewall alerts or port binding collisions if port 8080 was in use.
- Latency and security concerns with local socket loops.
- Potential race conditions when launching the editor before the socket bound.

### How `nview://` Solves This:
`noteflow` implements a **native custom URI scheme** (`nview://`) directly registered on the operating system's browser engine (WebKit on Linux).

1. The Flutter WebView navigates to:
   ```
   nview://excalidraw/index.html?path=<url_encoded_path>&readonly=false
   ```
2. In `linux/runner/my_application.cc`, the WebKit request handler intercepts all `nview://` traffic:
   ```cpp
   static void on_nview_scheme_request(WebKitURISchemeRequest* request, gpointer user_data) {
     const gchar* assets_dir = static_cast<const gchar*>(user_data);
     const gchar* req_path = webkit_uri_scheme_request_get_path(request);
     // Streams file directly from local Flutter asset bundle in C++ memory
     ...
     webkit_uri_scheme_request_finish(request, stream, -1, mime_type);
   }
   ```
3. **Zero Network, Zero Ports**:
   - Bytes are streamed directly from disk / memory into the WebKit DOM.
   - Operates 100% offline with zero open ports or sockets.
   - Near-instant cold start and page loading.

---

## Building the Excalidraw Web Bundle

When cloning the repository or after modifying files in `web_excalidraw/`, build the production bundle:

### 1. Prerequisites
- **Node.js**: v18.0.0 or higher
- **npm**: v9.0.0 or higher

Check your installation:
```bash
node -v
npm -v
```

### 2. Install Dependencies
```bash
cd web_excalidraw
npm install
```

### 3. Build Production Bundle
```bash
npm run build
```

This single command:
1. Compiles and tree-shakes React, `@excalidraw/excalidraw`, and icons into `assets/excalidraw/assets/`.
2. Runs `copy-fonts.js` to extract all 9 official font families into `assets/excalidraw/fonts/`.
3. Inlines and hashes all asset references relative to `./` for direct local bundle loading.

### 4. Verify Built Assets
Confirm the output directory exists:
```bash
ls -la ../assets/excalidraw/
# Should show index.html, assets/, and fonts/
```

### 5. Running the Application in Development
You can run the app with Flutter hot reload:
```bash
# Using automated launcher (auto-builds web bundle if missing):
./run.sh

# Or manually:
cd ..
flutter pub get
flutter run -d linux
```

### 6. Bundling & Packaging the Standalone Release Application
To produce a standalone distribution package containing the Flutter binary, compiled Excalidraw assets, and shared libraries:

```bash
# Automated single-command release bundling:
./bundle.sh

# Or manually:
flutter build linux --release
```

The standalone application is generated at:
```
build/linux/x64/release/bundle/noteflow
```
Run the compiled binary directly without any Flutter or Node dependencies:
```bash
./build/linux/x64/release/bundle/noteflow
```

To create a portable tarball to distribute:
```bash
tar -czvf noteflow-linux-x64.tar.gz -C build/linux/x64/release/bundle .
```

---

## Data Flow & Persistence

### 1. Opening an Existing Diagram
1. User clicks on a diagram card or selects an `.excalidraw` file in the sidebar.
2. Flutter loads `DrawingEditorScreen` with `nview://excalidraw/index.html?path=...`.
3. React's `App.jsx` reads the `path` query parameter and requests the file contents.
4. **Schema Migration via `restoreElements`**:
   To prevent blank screens or crashes from older/hand-crafted diagrams, `App.jsx` pipes all elements through Excalidraw's official `restoreElements()` helper:
   ```javascript
   import { restoreElements } from "@excalidraw/excalidraw";
   const cleanElements = restoreElements(rawJson.elements ?? [], null);
   ```

### 2. Saving Changes
1. **Debounced Auto-Save**: Any canvas interaction triggers a 1.5-second debounce.
2. **Keyboard Shortcut**: Pressing <kbd>Ctrl</kbd> + <kbd>S</kbd> (or <kbd>Cmd</kbd> + <kbd>S</kbd>) saves immediately.
3. **Dual Persistence**:
   - `.excalidraw`: The raw JSON elements, app state, and file metadata are saved to disk.
   - `.excalidraw.png`: A high-resolution 2x raster preview is automatically generated using `@excalidraw/excalidraw`'s `exportToBlob`.
4. **Live Stream Notification**:
   - `DrawingService.instance.notifyFileSaved(filePath)` broadcasts the change.
   - The Reading View continuous roll updates the preview block immediately without requiring a full folder reload.

---

## Offline Typography & Font Bundling

Excalidraw relies on custom sketchy and hand-drawn fonts:
- `Virgil` / `Excalifont` (Default hand-drawn font)
- `Cascadia` / `ComicShanns` (Code / monospace)
- `Assistant` / `Xiaolai` (International text support)

To ensure diagrams render pixel-perfectly without an internet connection:
- `copy-fonts.js` automatically pulls `.woff2` files from `@excalidraw/excalidraw` in `node_modules` during `npm run build`.
- `@font-face` definitions in `web_excalidraw/src/index.css` reference local `./fonts/...` URLs.
- The C++ custom scheme handler serves them with `font/woff2` MIME headers.

---

## Cross-Platform Implementation

| Platform | Web Engine | Protocol Mechanism | Status |
| :--- | :--- | :--- | :--- |
| **Linux Desktop** | WebKitGTK | `webkit_web_context_register_uri_scheme("nview", ...)` | ✅ Implemented & Verified |

---

## Troubleshooting & FAQs

### Q: The drawing editor opens to a blank screen or error 404.
**A:** The web bundle has not been built yet. Run:
```bash
cd web_excalidraw
npm install
npm run build
cd ..
flutter run -d linux
```

### Q: Can I run `web_excalidraw` in a standard browser during development?
**A:** Yes! Run `npm run dev` inside `web_excalidraw/` to launch Vite's development server with Hot Module Replacement (HMR).

### Q: Do I ever need to commit `assets/excalidraw/` to Git?
**A:** No. `assets/excalidraw/*` is ignored. Only `web_excalidraw/` source code and `assets/excalidraw/.gitkeep` should be committed. CI/CD pipelines build the web bundle before compiling the Flutter desktop executable:
```bash
cd web_excalidraw && npm ci && npm run build && cd ..
flutter build linux --release
```
