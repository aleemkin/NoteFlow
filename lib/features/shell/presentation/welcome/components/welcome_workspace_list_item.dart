import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noteflow/core/notifications/app_notification.dart';

/// Single item in the recent workspaces list on the welcome screen.
class WelcomeWorkspaceListItem extends StatefulWidget {
  final String name;
  final String displayPath;
  final String fullPath;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const WelcomeWorkspaceListItem({
    super.key,
    required this.name,
    required this.displayPath,
    required this.fullPath,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<WelcomeWorkspaceListItem> createState() =>
      _WelcomeWorkspaceListItemState();
}

class _WelcomeWorkspaceListItemState extends State<WelcomeWorkspaceListItem> {
  bool _isHovered = false;

  void _copyPath(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.fullPath));
    AppNotification.showSuccess(
      context,
      'Workspace path copied to clipboard',
      title: 'Path Copied',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          color: _isHovered ? const Color(0xFF1C2026) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              // Folder icon
              const Icon(
                Icons.folder_outlined,
                size: 18,
                color: Color(0xFFADC6FF),
              ),
              const SizedBox(width: 14),

              // Workspace Name & Path
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: _isHovered
                            ? const Color(0xFFADC6FF)
                            : const Color(0xFFDFE2EB),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.displayPath,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Color(0xFF8C909F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Action buttons on hover
              if (_isHovered) ...[
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  color: const Color(0xFF8C909F),
                  tooltip: 'Copy path',
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () => _copyPath(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 15),
                  color: const Color(0xFF8C909F),
                  tooltip: 'Remove from history',
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: widget.onRemove,
                ),
                const SizedBox(width: 4),
              ],

              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Color(0xFF8C909F),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
