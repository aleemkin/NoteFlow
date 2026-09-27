# Welcome to noteflow 🚀

noteflow is a high-performance, local-first knowledge notebook combining seamless Markdown editing with embedded, official Excalidraw vector diagrams.

## Desktop Power Features

- **Continuous Notebook Roll (`Ctrl+1`)**: Read all notes and sketches in any folder as one uninterrupted vertical stream without tab fatigue.
- **Parallel Dual-Pane Editor (`Ctrl+2`)**: Edit raw Markdown on the left with instant synchronized preview on the right.
- **Debounced Instant Auto-Save**: Every keystroke is saved directly to your local disk in the background — no manual save button or lost drafts.
- **Official Excalidraw Engine**: Embedded vector drawings render as sketchy vector art with Virgil typography and open directly in the full drawing canvas.
- **Unified Document Outline & Drag Reorder**: Search sections in the right panel and drag any heading to reorder blocks directly inside your files!
- **Semantic Tagging & Roll Filters**: Annotate blocks with `@@imp`, `@@info`, `@@todo`, `@@review`, or custom topics, and filter your notebook roll with a single click.

@@imp #mark_desktop_welcome_01 title="Instant Split Editor & Auto-Save"
Press Ctrl+2 to enter Edit View. Try typing or editing any note — your changes are automatically formatted and saved to disk with zero latency.
@@/imp

## Embedded Architecture Diagram

@@drawing ./02_Architecture/system_architecture.excalidraw {#draw_architecture minHeight=280}
@@/drawing

@@info #mark_desktop_welcome_02 title="Local-First Storage Guarantee"
Your data is 100% yours. All notes are standard Markdown (`.md`), and drawings are standard Excalidraw JSON (`.excalidraw`). No cloud lock-in, no telemetry.
@@/info

## Cross-Note Transclusion Preview

Preview blocks from other notes directly inline using transclusion:

@@view 02_Architecture/System_Architecture.md#arch_core

## Getting Started

@@todo #mark_desktop_welcome_03 title="Explore Your Notebook"
Press Ctrl+K to launch Spotlight Search, browse guides in the left sidebar, or press Ctrl+O to open any custom folder on your computer!
@@/todo
