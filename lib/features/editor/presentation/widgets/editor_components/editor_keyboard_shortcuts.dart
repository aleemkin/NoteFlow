import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Builds keyboard shortcut bindings for [DualPaneEditor].
class EditorKeyboardShortcuts {
  EditorKeyboardShortcuts._();

  static Map<ShortcutActivator, VoidCallback> buildBindings({
    required VoidCallback onSave,
    required VoidCallback onBold,
    required VoidCallback onItalic,
    required VoidCallback onInsertLink,
    required VoidCallback onTagImp,
    required VoidCallback onTagInfo,
    required VoidCallback onTagTodo,
    required VoidCallback onTagReview,
    required VoidCallback onInsertDrawing,
  }) {
    return {
      const SingleActivator(LogicalKeyboardKey.keyS, control: true): onSave,
      const SingleActivator(LogicalKeyboardKey.keyS, meta: true): onSave,
      const SingleActivator(LogicalKeyboardKey.keyB, control: true): onBold,
      const SingleActivator(LogicalKeyboardKey.keyB, meta: true): onBold,
      const SingleActivator(LogicalKeyboardKey.keyI, control: true): onItalic,
      const SingleActivator(LogicalKeyboardKey.keyI, meta: true): onItalic,
      const SingleActivator(LogicalKeyboardKey.keyK, control: true):
          onInsertLink,
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true): onInsertLink,

      // Semantic block shortcuts
      const SingleActivator(
        LogicalKeyboardKey.keyH,
        control: true,
        shift: true,
      ): onTagImp,
      const SingleActivator(LogicalKeyboardKey.keyH, meta: true, shift: true):
          onTagImp,
      const SingleActivator(
        LogicalKeyboardKey.keyI,
        control: true,
        shift: true,
      ): onTagInfo,
      const SingleActivator(LogicalKeyboardKey.keyI, meta: true, shift: true):
          onTagInfo,
      const SingleActivator(
        LogicalKeyboardKey.keyT,
        control: true,
        shift: true,
      ): onTagTodo,
      const SingleActivator(LogicalKeyboardKey.keyT, meta: true, shift: true):
          onTagTodo,
      const SingleActivator(
        LogicalKeyboardKey.keyR,
        control: true,
        shift: true,
      ): onTagReview,
      const SingleActivator(LogicalKeyboardKey.keyR, meta: true, shift: true):
          onTagReview,
      const SingleActivator(
        LogicalKeyboardKey.keyD,
        control: true,
        shift: true,
      ): onInsertDrawing,
      const SingleActivator(LogicalKeyboardKey.keyD, meta: true, shift: true):
          onInsertDrawing,
    };
  }
}
