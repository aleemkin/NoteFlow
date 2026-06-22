import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:noteflow/core/theme/app_theme.dart';

/// Renders a fenced code block with dark container, language badge, and copy button.
class CodeBlockRenderer extends StatefulWidget {
  final String code;
  final String? language;

  const CodeBlockRenderer({super.key, required this.code, this.language});

  @override
  State<CodeBlockRenderer> createState() => _CodeBlockRendererState();
}

class _CodeBlockRendererState extends State<CodeBlockRenderer> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code block header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  widget.language?.isNotEmpty == true
                      ? widget.language!
                      : 'code',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _copy,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check : Icons.copy,
                          size: 12,
                          color: _copied
                              ? AppColors.markSuccess
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied' : 'Copy',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _copied
                                ? AppColors.markSuccess
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              widget.code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13.0,
                height: 1.55,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
