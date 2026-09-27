# System Architecture & Local-First Design

noteflow is built from the ground up around local-first engineering principles.

## Core Architectural Pillars

- **Plain Markdown & Vector Files**: Notes remain standard UTF-8 `.md` files; diagrams remain standard `.excalidraw` JSON.
- **Zero-Network Native Protocol (`nview://`)**: The bundled React+Excalidraw web engine runs locally via a WebKit custom URI scheme handler without starting background HTTP servers or opening TCP ports.
- **Atomic Unit Decomposition**: Documents are parsed into discrete units (headings, text blocks, code fences, drawings) for granular rendering, outline navigation, and drag-and-drop reordering.
- **Zero Lock-In**: Inspect, edit, or version control your vault with Git or external CLI tools at any time.

@@architecture #arch_core title="Local-First Storage Architecture"
Your data stays entirely on your local drive. No mandatory cloud accounts, hidden trackers, or proprietary databases.
@@/architecture

```dart
// Atomic unit extraction model
final units = OutlineExtractor.extractFromFolder(documents);
```
