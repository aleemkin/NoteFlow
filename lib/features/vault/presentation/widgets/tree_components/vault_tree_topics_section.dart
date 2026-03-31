import 'package:flutter/material.dart';

import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/document/parsing/tag_extractor.dart';
import 'package:noteflow/core/platform/app_platform.dart';
import 'package:noteflow/features/render/surfaces/continuous_folder_surface.dart';

/// Collapsible Topics / Tags filter section rendered at the bottom of the vault tree.
class VaultTreeTopicsSection extends StatefulWidget {
  final List<TagSummary> tagSummaries;
  final ScrollFilterMode filterMode;
  final String? activeTagFilter;
  final void Function(ScrollFilterMode mode, String? tagFilter)?
  onFilterChanged;

  const VaultTreeTopicsSection({
    super.key,
    required this.tagSummaries,
    required this.filterMode,
    this.activeTagFilter,
    this.onFilterChanged,
  });

  @override
  State<VaultTreeTopicsSection> createState() => _VaultTreeTopicsSectionState();
}

class _VaultTreeTopicsSectionState extends State<VaultTreeTopicsSection> {
  bool _isTopicsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppPlatform.isMobile;
    final activeSlug = widget.activeTagFilter?.toLowerCase();
    final isCustomActive =
        widget.filterMode == ScrollFilterMode.customTag && activeSlug != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceSidebar,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Topics Accordion Header
          Material(
            color: AppColors.surfaceCard,
            child: InkWell(
              onTap: () {
                setState(() => _isTopicsExpanded = !_isTopicsExpanded);
              },
              child: Container(
                height: isMobile ? 38 : 32,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 10),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _isTopicsExpanded ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        Icons.chevron_right,
                        size: isMobile ? 18 : 15,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.label_outline_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'TOPICS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.tagSummaries.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isCustomActive)
                      InkWell(
                        onTap: () {
                          widget.onFilterChanged?.call(
                            ScrollFilterMode.all,
                            null,
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.close,
                                size: 10,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Collapsible Topics List
          if (_isTopicsExpanded)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                itemCount: widget.tagSummaries.length,
                itemBuilder: (context, index) {
                  final topic = widget.tagSummaries[index];
                  final isSelected =
                      widget.filterMode == ScrollFilterMode.customTag &&
                      activeSlug == topic.slug.toLowerCase();

                  return Padding(
                    padding: EdgeInsets.only(bottom: isMobile ? 5 : 3),
                    child: Material(
                      color: isSelected
                          ? AppColors.surfaceHover
                          : AppColors.surfaceCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 6 : 5),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.borderSubtle,
                          width: isSelected ? 1.0 : 0.8,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(isMobile ? 6 : 5),
                        hoverColor: AppColors.surfaceHover.withValues(
                          alpha: 0.5,
                        ),
                        onTap: () {
                          if (isSelected) {
                            widget.onFilterChanged?.call(
                              ScrollFilterMode.all,
                              null,
                            );
                          } else {
                            widget.onFilterChanged?.call(
                              ScrollFilterMode.customTag,
                              topic.slug,
                            );
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 10 : 8,
                            vertical: isMobile ? 8 : 5,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tag_rounded,
                                size: isMobile ? 16 : 13,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
                              ),
                              SizedBox(width: isMobile ? 8 : 6),
                              Expanded(
                                child: Text(
                                  topic.label.isNotEmpty
                                      ? topic.label
                                      : topic.slug,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: isMobile ? 13.0 : 11.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.borderSubtle,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '${topic.count}',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
