# Starting Your Own Vault

Follow these simple steps to set up your personal notebook in noteflow.

## 1. Create or Choose a Folder

noteflow works directly on any local folder on your file system. You can:
- Create a new empty folder anywhere on your disk (e.g. `~/Documents/MyNotes`).
- Or select an existing folder containing Markdown (`.md`) files or documentation.

## 2. Open Your Vault in noteflow

- Press `Ctrl+O` (or `Cmd+O` on macOS) at any time.
- Or click the folder icon or **Open Vault Folder...** from the window top bar.
- Pick your chosen folder in the system file picker.

@@info #mark_vault_01 title="Auto-Remembered Vault"
noteflow automatically remembers your last opened vault. Every time you launch the app, it immediately reopens your notebook right where you left off!
@@/info

## 3. Creating Notes & Folders

- Hover over the **EXPLORER** header in the left sidebar and click the **+ New File** or **+ New Folder** icons.
- Or use the context menu on any directory.
- Type the note name and press `Enter` to commit, or `Escape` to cancel.

## 4. Embedding Drawings & Diagrams

- To create a vector diagram, create a file ending with `.excalidraw` (e.g. `diagram.excalidraw`).
- Clicking it opens the interactive canvas where you can sketch diagrams, flowcharts, and mind maps.
- Embed any drawing into a markdown note using callout syntax:
  ```markdown
  @@drawing ./diagram.excalidraw {#my_diagram minHeight=300}
  @@/drawing
  ```

@@todo #mark_vault_02 title="Ready to Start?"
Press `Ctrl+O` now to open your own folder, or continue exploring the sample vault!
@@/todo
