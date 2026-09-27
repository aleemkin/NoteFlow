# Markdown & Tag Directives

noteflow supports standard CommonMark and GitHub Flavored Markdown, supercharged with custom semantic block directives and Excalidraw embeddings.

## Rich Markdown Elements

### Task Checklists
- [x] Local-first file storage with zero cloud dependencies
- [x] Official Excalidraw vector integration
- [x] Real-time debounced auto-save engine
- [ ] Add custom themes support

### Structured Data Tables

| Component | Architecture | Storage Format | Performance |
|---|---|---|---|
| Notes Engine | Continuous AST Roll | Plain UTF-8 `.md` | < 16ms frame time |
| Drawing Canvas | React + Vite in WebKit | JSON `.excalidraw` + `.png` | Native 60 FPS |
| Tree Navigator | Incremental Virtualized | Local File System Watcher | Instant |

### Syntax-Highlighted Code Blocks

```dart
// Native scheme handler bridges Excalidraw without opening TCP ports
void registerNativeSchemeHandler(WebKitWebContext* context) {
  webkit_web_context_register_uri_scheme(
    context,
    "nview",
    handleCustomUriRequest,
    nullptr,
    nullptr
  );
}
```

## Semantic Tag Directives

Tag content blocks to highlight key insights and enable instant roll filtering:

### 1. Important Callout (`@@imp`)
@@imp #mark_directives_01 title="Critical Notice"
High-priority insights, breaking changes, or warnings that require immediate attention.
@@/imp

### 2. Information Reference (`@@info`)
@@info #mark_directives_02 title="Technical Specification"
Reference material, architecture notes, documentation links, and formulas.
@@/info

### 3. Action Items (`@@todo`)
@@todo #mark_directives_03 title="Upcoming Action"
Tasks and action items tracked across notes.
@@/todo

### 4. Review Flags (`@@review`)
@@review #mark_directives_04 title="Under Review"
Content pending team or editorial review before final sign-off.
@@/review

### 5. Single-Line Shorthand
@@imp> Single-line important alert using concise shorthand syntax!
