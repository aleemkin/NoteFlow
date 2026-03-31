# Welcome to noteflow 🚀

noteflow is a local-first knowledge notebook designed for seamless reading, structured Markdown writing, and embedded vector diagrams.

## Key Features & Highlights

- **Continuous Folder Stream**: In Reading View (`Ctrl+1`), all notes and drawings in a folder are displayed as one continuous flowing document without tab clutter.
- **Parallel Dual-Pane Editor**: In Edit View (`Ctrl+2`), edit raw Markdown on the left with live synchronized visual preview on the right.
- **Instant Debounced Auto-Save**: All changes are automatically written to disk with error checking and debouncing — no manual save button needed!
- **Unified Document Outline**: The right panel features a clean section outline with filter search (`Filter sections...`) and drag-and-drop reordering.
- **Topics & Semantic Annotations**: Annotate blocks with `@@imp` (Important), `@@info` (Info Reference), `@@todo` (To-Do), or custom topics, and filter entire rolls with one click from the left sidebar's **TOPICS** panel.
- **Embedded Vector Drawings**: Native Excalidraw-compatible vector drawings inline with your document flow. Clicking a drawing in Reading View or the sidebar opens directly into the visual editor.
- **VS Code-Style Tree**: Clean 24px tree rows with keyboard-driven inline file creation and rename (<kbd>Enter</kbd> commits, <kbd>Esc</kbd> cancels).

@@imp #mark_welcome_01 title="Split Editor & Auto-Save"
Edit View is permanently split with live synchronized preview. Try editing any note — your changes save automatically in the background!
@@/imp

@@drawing ./02_Architecture/system_architecture.excalidraw {#draw_overview minHeight=280}
@@/drawing

@@info #mark_welcome_02 title="Local-First Guarantee"
Canonical files are always standard Markdown (`.md`) and Excalidraw (`.excalidraw`) files stored directly on disk without proprietary vendor lock-in.
@@/info

## Cross-Note Transclusion Preview

@@view 02_Architecture/System_Architecture.md#arch_core

## How to Start Your Own Vault

Ready to create your own notebook? Press `Ctrl+O` / `Cmd+O` or choose **Open Vault Folder...** from the top menu, then select any empty folder or existing Markdown folder on your computer. Your vault will open immediately and will be remembered automatically every time you launch noteflow!

See the **03_Starting_Your_Own_Vault.md** note in the left sidebar for a complete step-by-step walkthrough.

## Next Steps

@@todo> Explore the 01_Guides and 02_Architecture folders in the left sidebar, or switch between Reading View (Ctrl+1) and Edit View (Ctrl+2)!
