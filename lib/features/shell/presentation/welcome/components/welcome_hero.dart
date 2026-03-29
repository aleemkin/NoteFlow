import 'package:flutter/material.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';

/// Hero header for the welcome screen.
class WelcomeHero extends StatelessWidget {
  static const Color _primary = Color(0xFFADC6FF);
  static const Color _onSurface = Color(0xFFDFE2EB);
  static const Color _onSurfaceVariant = Color(0xFFC2C6D6);

  const WelcomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSvgIcon.appIcon(width: 16, height: 16),
                  SizedBox(width: 6),
                  Text(
                    'Noteflow',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w600,
              color: _onSurface,
              letterSpacing: -0.8,
              fontFamily: 'Newsreader',
              fontFamilyFallback: ['serif', 'Georgia'],
              height: 1.15,
            ),
            children: [
              TextSpan(text: 'Where thought '),
              TextSpan(
                text: 'takes form.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  color: _primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Local-first Markdown knowledge base with synchronized Excalidraw vector canvases.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15.5,
            color: _onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
