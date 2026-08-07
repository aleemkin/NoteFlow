import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';
import 'app_icon_widget.dart';

/// Left section of the WindowChrome containing:
/// [AppIcon] noteflow / [FolderIcon] personal_notes
class AppIdentitySection extends StatefulWidget {
  final String? vaultName;
  final String currentFolder;
  final ValueChanged<String>? onFolderSelected;
  final VoidCallback? onVaultTap;
  final bool isCompact;

  const AppIdentitySection({
    super.key,
    this.vaultName,
    this.currentFolder = 'personal_notes',
    this.onFolderSelected,
    this.onVaultTap,
    this.isCompact = false,
  });

  @override
  State<AppIdentitySection> createState() => _AppIdentitySectionState();
}

class _AppIdentitySectionState extends State<AppIdentitySection> {
  bool _isHovered = false;

  void _showFolderMenu(BuildContext context, TapDownDetails details) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(
        details.globalPosition.dx,
        details.globalPosition.dy + 12,
        0,
        0,
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: AppColors.cardBackground,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      items: [
        _buildMenuItem('personal_notes', Icons.folder_outlined, '12 notes'),
        _buildMenuItem('work_journal', Icons.folder_outlined, '28 notes'),
        _buildMenuItem('daily_scratchpad', Icons.folder_outlined, '5 notes'),
        _buildMenuItem('project_roadmap', Icons.folder_outlined, '3 notes'),
        const PopupMenuDivider(height: 8),
        PopupMenuItem<String>(
          value: '__new_folder__',
          height: 36,
          child: Row(
            children: const [
              Icon(
                Icons.create_new_folder_outlined,
                size: 16,
                color: AppColors.accentCyan,
              ),
              SizedBox(width: 8),
              Text(
                'New folder...',
                style: TextStyle(fontSize: 12.5, color: AppColors.accentCyan),
              ),
            ],
          ),
        ),
      ],
    ).then((selected) {
      if (selected != null && selected != '__new_folder__') {
        widget.onFolderSelected?.call(selected);
      }
    });
  }

  PopupMenuItem<String> _buildMenuItem(
    String folderName,
    IconData icon,
    String subtitle,
  ) {
    final isCurrent = folderName == widget.currentFolder;
    return PopupMenuItem<String>(
      value: folderName,
      height: 38,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isCurrent ? AppColors.accentCyan : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              folderName,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                color: isCurrent
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App Icon badge (32x32)
        const AppIconWidget(),

        // const SizedBox(width: 9),

        // App Name: "Noteflow" in bold serif
        const Text(
          'Noteflow',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: AppColors.textPrimary,
          ),
        ),

        if (!widget.isCompact) ...[
          const SizedBox(width: 14),

          // Separator: "/"
          const Text(
            '/',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textDivider,
            ),
          ),

          const SizedBox(width: 14),

          // Interactive folder breadcrumb: [📁 vault_name]
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: widget.onVaultTap,
              onTapDown: widget.onVaultTap == null
                  ? (details) => _showFolderMenu(context, details)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? AppColors.controlHover
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppSvgIcon.folder(size: 12),
                    const SizedBox(width: 7),
                    Text(
                      widget.vaultName ?? widget.currentFolder,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                        color: _isHovered
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
