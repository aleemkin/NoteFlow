import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';

import 'package:noteflow/core/platform/app_platform.dart';

/// Semantic notification type determining icons, colors, and accessibility.
enum AppNotificationType { success, error, info, warning }

/// Non-intrusive notification system.
///
/// On Android and mobile platforms, it presents safe-area-aware, floating [SnackBar]s
/// via [ScaffoldMessenger] to adapt smoothly across diverse screen sizes and notches.
/// On desktop platforms, it renders anchored cards in the top-right corner of the window.
class AppNotification {
  AppNotification._();

  /// Global key to access root ScaffoldMessenger for background or dialog notifications.
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static OverlayEntry? _currentEntry;

  /// Resolves standard icon and color attributes for a given notification type.
  static (IconData, Color, Color) resolveVisuals(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.success => (
        Icons.check_circle_rounded,
        AppColors.markSuccess,
        AppColors.markSuccess.withValues(alpha: 0.4),
      ),
      AppNotificationType.error => (
        Icons.error_outline_rounded,
        AppColors.markDanger,
        AppColors.markDanger.withValues(alpha: 0.4),
      ),
      AppNotificationType.warning => (
        Icons.warning_amber_rounded,
        AppColors.markImportant,
        AppColors.markImportant.withValues(alpha: 0.4),
      ),
      AppNotificationType.info => (
        Icons.info_outline_rounded,
        AppColors.secondary,
        AppColors.borderDefault,
      ),
    };
  }

  /// Shows a success notification.
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.success,
      duration: duration,
    );
  }

  /// Shows an error notification.
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 4000),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.error,
      duration: duration,
    );
  }

  /// Shows an informative notification.
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    show(context, message: message, title: title, duration: duration);
  }

  /// Shows a warning notification.
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.warning,
      duration: duration,
    );
  }

  /// Displays a notification card or snackbar depending on platform.
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    if (!context.mounted) return;

    // Use floating SnackBar on Android and mobile form factors to avoid overlay clipping.
    final isMobileOrAndroid = AppPlatform.isAndroid || AppPlatform.isMobile;
    if (isMobileOrAndroid) {
      final messenger =
          ScaffoldMessenger.maybeOf(context) ??
          scaffoldMessengerKey.currentState;
      if (messenger != null) {
        dismiss();
        final (icon, iconColor, borderColor) = resolveVisuals(type);
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF161B22),
            elevation: 6,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: borderColor),
            ),
            duration: duration,
            content: Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null && title.isNotEmpty) ...[
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: title != null
                              ? FontWeight.w400
                              : FontWeight.w500,
                          color: title != null
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      final messenger =
          ScaffoldMessenger.maybeOf(context) ??
          scaffoldMessengerKey.currentState;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(title != null ? '$title: $message' : message),
          duration: duration,
        ),
      );
      return;
    }

    dismiss();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _NotificationOverlay(
        title: title,
        message: message,
        type: type,
        duration: duration,
        onClose: () {
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Dismisses the currently displayed notification, if any.
  static void dismiss() {
    if (_currentEntry != null) {
      if (_currentEntry!.mounted) {
        _currentEntry!.remove();
      }
      _currentEntry = null;
    }
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  }
}

class _NotificationOverlay extends StatefulWidget {
  final String? title;
  final String message;
  final AppNotificationType type;
  final Duration duration;
  final VoidCallback onClose;

  const _NotificationOverlay({
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    required this.onClose,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    _autoDismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _handleClose();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, borderColor) = AppNotification.resolveVisuals(
      widget.type,
    );

    return Positioned(
      top: 48,
      right: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              constraints: const BoxConstraints(minWidth: 280, maxWidth: 400),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.title != null) ...[
                          Text(
                            widget.title!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                        ],
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: widget.title != null
                                ? FontWeight.w400
                                : FontWeight.w500,
                            color: widget.title != null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _handleClose,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
