import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:noteflow/core/theme/app_theme.dart';

/// Standard desktop window control buttons (Minimize, Maximize, Close)
/// for borderless / frameless desktop windows.
class WindowControlButtons extends StatelessWidget {
  const WindowControlButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChromeActionButton(
          tooltip: 'Minimize Window',
          onTapDown: (_) {
            if (!kIsWeb) {
              try {
                windowManager.minimize();
              } catch (_) {}
            }
          },
          child: const Icon(
            Icons.remove_rounded,
            size: 16,
            color: AppColors.actionIcon,
          ),
        ),
        ChromeActionButton(
          tooltip: 'Maximize Window',
          onTapDown: (_) {
            if (!kIsWeb) {
              try {
                windowManager.isMaximized().then((isMax) {
                  if (isMax) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                });
              } catch (_) {}
            }
          },
          child: const Icon(
            Icons.crop_square_rounded,
            size: 16,
            color: AppColors.actionIcon,
          ),
        ),
        ChromeActionButton(
          tooltip: 'Close Window',
          onTapDown: (_) {
            if (!kIsWeb) {
              try {
                windowManager.close();
              } catch (_) {}
            }
          },
          child: const Icon(
            Icons.close_rounded,
            size: 16,
            color: Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }
}

/// Shared hoverable action button used in window controls and chrome actions.
class ChromeActionButton extends StatefulWidget {
  final Widget child;
  final String tooltip;
  final VoidCallback? onTap;
  final void Function(TapDownDetails details)? onTapDown;

  const ChromeActionButton({
    super.key,
    required this.child,
    required this.tooltip,
    this.onTap,
    this.onTapDown,
  });

  @override
  State<ChromeActionButton> createState() => _ChromeActionButtonState();
}

class _ChromeActionButtonState extends State<ChromeActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: widget.onTapDown,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppColors.actionIconHoverBg
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
