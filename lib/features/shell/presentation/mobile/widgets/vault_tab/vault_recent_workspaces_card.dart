import 'dart:io';
import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:path/path.dart' as p;

/// Card displaying the list of recently opened workspaces on mobile with quick open and remove actions.
class VaultRecentWorkspacesCard extends StatelessWidget {
  final List<String> recentVaults;
  final bool isLoading;
  final String? currentVaultPath;
  final ValueChanged<String> onOpenVaultPath;
  final ValueChanged<String> onRemoveRecent;

  const VaultRecentWorkspacesCard({
    super.key,
    required this.recentVaults,
    required this.isLoading,
    this.currentVaultPath,
    required this.onOpenVaultPath,
    required this.onRemoveRecent,
  });

  String _formatDisplayPath(String fullPath) {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty && fullPath.startsWith(home)) {
      return '~${fullPath.substring(home.length)}';
    }
    return fullPath;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT WORKSPACES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B949E),
                  letterSpacing: 0.8,
                ),
              ),
              if (recentVaults.isNotEmpty)
                Text(
                  '${recentVaults.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B949E),
                  ),
                ),
            ],
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          )
        else if (recentVaults.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF21262D)),
            ),
            child: const Center(
              child: Text(
                'No recent workspaces saved yet.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF8B949E)),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF21262D)),
            ),
            child: Column(
              children: List.generate(recentVaults.length, (index) {
                final vaultPath = recentVaults[index];
                final isCurrent =
                    currentVaultPath != null && currentVaultPath == vaultPath;
                final name = p.basename(vaultPath);
                final isLast = index == recentVaults.length - 1;

                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isCurrent
                            ? null
                            : () => onOpenVaultPath(vaultPath),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                color: isCurrent
                                    ? const Color(0xFF58A6FF)
                                    : const Color(0xFF8B949E),
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name.isNotEmpty ? name : vaultPath,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isCurrent
                                                  ? const Color(0xFF58A6FF)
                                                  : const Color(0xFFDFE2EB),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isCurrent) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF34D399),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      _formatDisplayPath(vaultPath),
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF8B949E),
                                        fontFamily: 'monospace',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (!isCurrent)
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: Color(0xFF58A6FF),
                                  ),
                                  tooltip: 'Open workspace',
                                  splashRadius: 16,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => onOpenVaultPath(vaultPath),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFF6E7681),
                                ),
                                tooltip: 'Remove from recents',
                                splashRadius: 16,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () => onRemoveRecent(vaultPath),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                        height: 1,
                        indent: 44,
                        color: Color(0xFF21262D),
                      ),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }
}
