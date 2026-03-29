import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/core/platform/app_platform.dart';

/// Search/filter bar for filtering files inside the vault tree sidebar.
class VaultTreeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchFilter;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const VaultTreeSearchBar({
    super.key,
    required this.controller,
    required this.searchFilter,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppPlatform.isMobile;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 8,
        vertical: isMobile ? 8 : 6,
      ),
      child: SizedBox(
        height: isMobile ? 38 : 28,
        child: TextField(
          controller: controller,
          style: TextStyle(
            fontSize: isMobile ? 13.5 : 12,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Filter files in tree...',
            hintStyle: TextStyle(
              fontSize: isMobile ? 12.5 : 11,
              color: AppColors.textTertiary,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: isMobile ? 18 : 14,
              color: AppColors.textTertiary,
            ),
            prefixIconConstraints: BoxConstraints(minWidth: isMobile ? 36 : 26),
            suffixIcon: searchFilter.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      size: isMobile ? 16 : 13,
                      color: AppColors.textTertiary,
                    ),
                    padding: EdgeInsets.zero,
                    splashRadius: isMobile ? 16 : 12,
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceCard,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 8,
              vertical: isMobile ? 8 : 4,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 8 : 4),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 8 : 4),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 8 : 4),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
