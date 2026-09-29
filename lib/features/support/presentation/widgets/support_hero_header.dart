import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';

/// Hero header widget displayed at the top of the Support screen.
///
/// Features an amber-glowing coffee emblem, headline, and the core NoteFlow
/// philosophy (offline-first, no subscriptions, no telemetry).
class SupportHeroHeader extends StatelessWidget {
  final Color accentColor;

  const SupportHeroHeader({
    super.key,
    this.accentColor = const Color(0xFFF59E0B),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0x1EF59E0B),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x44F59E0B), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.coffee_rounded,
              color: accentColor,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Buy Me a Coffee',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: Color(0xFFDFE2EB),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'NoteFlow is crafted as a fast, local-first notebook with Markdown & Excalidraw drawings. '
          'No subscriptions, no lock-in, and no hidden telemetry. Your support helps keep development active.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
