# Split Editor & Auto-Save Workflow

The editing interface in noteflow is built for speed, precision, and focus.

## Parallel Dual-Pane Architecture

- **Left Pane**: Clean Markdown editor with syntax highlighting, custom callout block support, and a rich formatting toolbar.
- **Right Pane**: Real-time synchronized preview rendered with GitHub-flavored Markdown styling and inline drawings.

@@imp #mark_guide_02 title="Instant Debounced Auto-Save"
Edits are debounced and saved automatically to disk. You never have to worry about clicking a save button or losing changes.
@@/imp

## Live External File Sync

noteflow actively watches the local file system. If you edit files externally in VS Code, Git, or scripts, noteflow detects changes and reloads immediately without blinking or losing scroll position.
