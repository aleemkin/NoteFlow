# Document Outline & Drag Reorder

The right sidebar provides structural navigation and live reorganization of your documents.

## Document Outline Inspector

1. **Instant Section Filter**: Type in the `Filter sections...` search box at the top of the Outline tab to find headings across long documents.
2. **Click to Navigate**: Clicking any heading jumps directly to that section in both Reading View and Edit View.
3. **Drag-and-Drop Reordering**: Grab any section item and drag it up or down in the outline list. noteflow parses the Markdown AST and safely reorders the entire text block inside the underlying file!

@@info #mark_guide_outline_01 title="AST-Level Reordering"
Drag-and-drop reordering preserves all child content, subheadings, callouts, and embedded drawings belonging to that section.
@@/info
