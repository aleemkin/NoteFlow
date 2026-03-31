# System Architecture & Local-First Design

noteflow is architected around local-first principles with standard, open formats.

## Core Principles

- **Plain Markdown & Vector Files**: Notes remain standard `.md` files; diagrams remain standard `.excalidraw` JSON.
- **Atomic Unit Decomposition**: Documents are parsed into discrete atomic units (headings, text blocks, drawings) for granular rendering and reordering.
- **Zero Lock-In**: You can inspect, edit, or version control your vault with Git or external editors at any time.

@@architecture #arch_core title="Local-First Guarantee"
Your data stays entirely on your local machine. No mandatory accounts, telemetry, or cloud dependencies.
@@/architecture

```dart
// Atomic unit extraction model
final units = OutlineExtractor.extractFromFolder(documents);
```
