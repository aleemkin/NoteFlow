import 'package:flutter/material.dart';

/// Bottom footer bar with keyboard shortcuts and branding.
class WelcomeFooter extends StatelessWidget {
  static const Color _surfaceContainerLowest = Color(0xFF0A0E14);
  static const Color _outline = Color(0xFF8C909F);

  const WelcomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _surfaceContainerLowest,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 896),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Noteflow',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _outline,
                  ),
                ),
                Wrap(
                  spacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: const [
                    _FooterShortcut(keycap: 'Ctrl+O', label: 'Open'),
                    _FooterShortcut(keycap: 'Ctrl+N', label: 'New'),
                    _FooterShortcut(keycap: 'Ctrl+K', label: 'Command Palette'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterShortcut extends StatelessWidget {
  final String keycap;
  final String label;

  const _FooterShortcut({required this.keycap, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2026),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFF2A303A)),
          ),
          child: Text(
            keycap,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: Color(0xFF8C909F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8C909F)),
        ),
      ],
    );
  }
}
