import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'widgets/action_sheets/create_action_sheet.dart';
import 'widgets/action_sheets/file_options_sheet.dart';
import 'widgets/action_sheets/text_selection_sheet.dart';

export 'widgets/action_sheets/create_action_sheet.dart';
export 'widgets/action_sheets/file_options_sheet.dart';
export 'widgets/action_sheets/text_selection_sheet.dart';

/// Touch-first mobile modal bottom sheets and quick action dialogs for Android.
/// Acts as a unified facade for [CreateActionSheet], [FileOptionsSheet], and [TextSelectionSheet].
class MobileQuickActionSheet {
  MobileQuickActionSheet._();

  /// Shows mobile bottom sheet for creating a Note, Diagram, or Folder in [parentDir].
  static Future<void> showCreateSheet({
    required BuildContext context,
    required WidgetRef ref,
    required VaultUri parentDir,
    required void Function(String path)? onFileCreated,
  }) {
    return CreateActionSheet.show(
      context: context,
      ref: ref,
      parentDir: parentDir,
      onFileCreated: onFileCreated,
    );
  }

  /// Shows file options bottom sheet (Open, Rename, Delete, etc.).
  static Future<void> showFileOptionsSheet({
    required BuildContext context,
    required WidgetRef ref,
    required String filePath,
    required bool isDirectory,
    required VoidCallback onOpen,
    VoidCallback? onPreviewInReading,
  }) {
    return FileOptionsSheet.show(
      context: context,
      ref: ref,
      filePath: filePath,
      isDirectory: isDirectory,
      onOpen: onOpen,
      onPreviewInReading: onPreviewInReading,
    );
  }

  /// Shows mobile bottom sheet for text selection in Reading View (tagging, drawings, etc.).
  static Future<void> showTextSelectionSheet({
    required BuildContext context,
    required String selectedText,
    required void Function(String tag) onTag,
    required VoidCallback onInsertDiagram,
    required VoidCallback onCopy,
    required VoidCallback onRemoveTag,
  }) {
    return TextSelectionSheet.show(
      context: context,
      selectedText: selectedText,
      onTag: onTag,
      onInsertDiagram: onInsertDiagram,
      onCopy: onCopy,
      onRemoveTag: onRemoveTag,
    );
  }
}
