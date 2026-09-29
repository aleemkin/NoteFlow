import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Centralized asset paths for SVG icons in the application.
class AppSvgIcons {
  const AppSvgIcons._();

  static const String appIcon = 'assets/icons/svg/AppIcon.svg';
  static const String folder = 'assets/icons/svg/Folder.svg';
  static const String longCoffee = 'assets/icons/svg/long_coffee.svg';
  static const String leftPanelClosed =
      'assets/icons/svg/left_panel_closed.svg';
  static const String leftPanelOpen = 'assets/icons/svg/left_panel_open.svg';
  static const String rightPanelClosed =
      'assets/icons/svg/right_panel_closed.svg';
  static const String rightPanelOpen = 'assets/icons/svg/right_panel_open.svg';
  static const String codeMenu = 'assets/icons/svg/code_menu.svg';
  static const String readingToggle = 'assets/icons/svg/reading_toggle.svg';
  static const String editorToggle = 'assets/icons/svg/editor_toggle.svg';
  static const String notes = 'assets/icons/svg/notes.svg';
  static const String notesSelected = 'assets/icons/svg/notes_selected.svg';
  static const String openFolder = 'assets/icons/svg/open_folder.svg';
  static const String newFolder = 'assets/icons/svg/new_folder.svg';
  static const String editor = 'assets/icons/svg/editor.svg';
  static const String editorSelected = 'assets/icons/svg/editor_selected.svg';
  static const String canvas = 'assets/icons/svg/canvas.svg';
  static const String canvasSelected = 'assets/icons/svg/canvas_selected.svg';
  static const String vault = 'assets/icons/svg/vault.svg';
  static const String vaultSelected = 'assets/icons/svg/vault_selected.svg';
  static const String openBook = 'assets/icons/svg/open_book.svg';
}

/// A reusable widget to render SVG icons with support for sizing, coloring,
/// fit, alignment, and semantics.
class AppSvgIcon extends StatelessWidget {
  /// Path to the SVG asset (e.g. 'assets/icons/svg/Folder.svg' or from [AppSvgIcons]).
  final String assetPath;

  /// Width of the SVG icon. If [size] is provided and [width] is null, [size] is used.
  final double? width;

  /// Height of the SVG icon. If [size] is provided and [height] is null, [size] is used.
  final double? height;

  /// Convenience shortcut to set both [width] and [height] to the same value.
  final double? size;

  /// Optional color filter applied to the SVG. If null, the SVG's native colors are preserved.
  final Color? color;

  /// Blend mode when [color] is applied. Defaults to [BlendMode.srcIn].
  final BlendMode blendMode;

  /// How the SVG should be scaled. Defaults to [BoxFit.contain].
  final BoxFit fit;

  /// Alignment of the SVG within its bounding box. Defaults to [Alignment.center].
  final AlignmentGeometry alignment;

  /// Optional accessibility label for screen readers.
  final String? semanticsLabel;

  const AppSvgIcon({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  });

  /// Factory constructor for providing an asset path positionally: AppSvgIcon.asset(path, ...)
  const AppSvgIcon.asset(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  });

  /// Factory constructor for AppIcon badge
  const AppSvgIcon.appIcon({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel = 'App Icon',
  }) : assetPath = AppSvgIcons.appIcon;

  /// Factory constructor for Folder icon
  const AppSvgIcon.folder({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel = 'Folder',
  }) : assetPath = AppSvgIcons.folder;

  /// Factory constructor for Open Folder icon
  const AppSvgIcon.openFolder({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel = 'Open Folder',
  }) : assetPath = AppSvgIcons.openFolder;

  /// Factory constructor for New Folder icon
  const AppSvgIcon.newFolder({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel = 'New Folder',
  }) : assetPath = AppSvgIcons.newFolder;

  /// Factory constructor for Left Panel Open icon
  const AppSvgIcon.leftPanelOpen({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.leftPanelOpen;

  /// Factory constructor for Left Panel Closed icon
  const AppSvgIcon.leftPanelClosed({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.leftPanelClosed;

  /// Factory constructor for Right Panel Open icon
  const AppSvgIcon.rightPanelOpen({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.rightPanelOpen;

  /// Factory constructor for Right Panel Closed icon
  const AppSvgIcon.rightPanelClosed({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.rightPanelClosed;

  /// Factory constructor for Code Menu / 6-dots grip icon
  const AppSvgIcon.codeMenu({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.codeMenu;

  /// Factory constructor for Reading Toggle icon
  const AppSvgIcon.readingToggle({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.readingToggle;

  /// Factory constructor for Editor Toggle icon
  const AppSvgIcon.editorToggle({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.editorToggle;

  /// Factory constructor for Notes icon (unselected)
  const AppSvgIcon.notes({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.notes;

  /// Factory constructor for Notes icon (selected)
  const AppSvgIcon.notesSelected({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.notesSelected;

  /// Factory constructor for Editor icon (unselected)
  const AppSvgIcon.editor({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.editor;

  /// Factory constructor for Editor icon (selected)
  const AppSvgIcon.editorSelected({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.editorSelected;

  /// Factory constructor for Canvas icon (unselected)
  const AppSvgIcon.canvas({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.canvas;

  /// Factory constructor for Canvas icon (selected)
  const AppSvgIcon.canvasSelected({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.canvasSelected;

  /// Factory constructor for Vault icon (unselected)
  const AppSvgIcon.vault({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.vault;

  /// Factory constructor for Vault icon (selected)
  const AppSvgIcon.vaultSelected({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.vaultSelected;

  /// Factory constructor for Open Book icon
  const AppSvgIcon.openBook({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.openBook;

  /// Factory constructor for Long Coffee icon
  const AppSvgIcon.longCoffee({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : assetPath = AppSvgIcons.longCoffee;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = size ?? width;
    final effectiveHeight = size ?? height;

    return SvgPicture.asset(
      assetPath,
      width: effectiveWidth,
      height: effectiveHeight,
      fit: fit,
      alignment: alignment,
      semanticsLabel: semanticsLabel,
      colorFilter: color != null ? ColorFilter.mode(color!, blendMode) : null,
    );
  }
}
