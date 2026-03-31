import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/core/platform/app_platform.dart';
import 'package:noteflow/core/platform/vault_uri.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';
import 'header_action_button.dart';

/// Top header for the vault tree sidebar showing active directory and action buttons.
class VaultTreeHeader extends StatelessWidget {
  final VaultUri activeDir;
  final String activeLabel;
  final VoidCallback onSelectRoot;
  final VoidCallback onNewNote;
  final VoidCallback onNewDrawing;
  final VoidCallback onNewFolder;

  const VaultTreeHeader({
    super.key,
    required this.activeDir,
    required this.activeLabel,
    required this.onSelectRoot,
    required this.onNewNote,
    required this.onNewDrawing,
    required this.onNewFolder,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppPlatform.isMobile;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 10,
        vertical: isMobile ? 10 : 6,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          AppSvgIcon.folder(
            color: AppColors.textMuted,
            width: isMobile ? 16 : 12,
            height: isMobile ? 16 : 12,
          ),
          SizedBox(width: isMobile ? 8 : 6),
          Expanded(
            child: Tooltip(
              message: activeDir.isRoot
                  ? 'Target: Vault Root'
                  : 'Target: /${activeDir.path}',
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: onSelectRoot,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 0),
                  child: Text(
                    activeLabel,
                    style: TextStyle(
                      fontSize: isMobile ? 13.5 : 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          HeaderActionButton(
            icon: Icons.note_add_outlined,
            tooltip:
                'New Note in ${activeDir.isRoot ? "root" : "/${activeDir.path}"}',
            onPressed: onNewNote,
          ),
          HeaderActionButton(
            icon: Icons.draw_outlined,
            tooltip:
                'New Drawing in ${activeDir.isRoot ? "root" : "/${activeDir.path}"}',
            onPressed: onNewDrawing,
          ),
          HeaderActionButton(
            icon: Icons.create_new_folder_outlined,
            tooltip:
                'New Folder in ${activeDir.isRoot ? "root" : "/${activeDir.path}"}',
            onPressed: onNewFolder,
          ),
        ],
      ),
    );
  }
}
