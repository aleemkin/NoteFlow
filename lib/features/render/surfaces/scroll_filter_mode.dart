/// Projection filter mode for the continuous folder surface.
enum ScrollFilterMode {
  /// Renders all document content seamlessly.
  all,

  /// Filters to only show important (`@@imp`) annotated blocks.
  importantOnly,

  /// Filters to only show info reference (`@@info`) annotated blocks.
  infoOnly,

  /// Filters by custom semantic tag annotation (e.g. `@@review`, `@@todo`).
  customTag,

  /// Filters to only show embedded diagrams and drawings.
  diagramsOnly,
}
