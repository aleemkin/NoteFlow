import 'package:flutter/material.dart';

/// Single item within the support FAQ and transparency section.
class SupportFaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const SupportFaqItem({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFFDFE2EB),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          answer,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.4,
            color: Color(0xFF8B949E),
          ),
        ),
      ],
    );
  }
}

/// Transparency and FAQ section clarifying NoteFlow's monetization philosophy.
class SupportFaqSection extends StatelessWidget {
  const SupportFaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF10141C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF202632)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: Color(0xFF8B949E),
              ),
              SizedBox(width: 8),
              Text(
                'TRANSPARENCY & PROMISES',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: Color(0xFF8B949E),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          SupportFaqItem(
            question: 'Are any NoteFlow features paywalled?',
            answer:
                'No. All core features—Markdown editing, tags, live transclusion, '
                'Excalidraw drawing canvas, and offline local vaults—are forever free and unlimited.',
          ),
          SizedBox(height: 12),
          SupportFaqItem(
            question: 'How are tips and ads utilized?',
            answer:
                'Contributions cover development time, mobile optimizations, '
                'performance improvements, and keeping NoteFlow server-free and privacy-first.',
          ),
          SizedBox(height: 12),
          SupportFaqItem(
            question: 'How is privacy protected?',
            answer:
                'NoteFlow adheres to zero user tracking. No telemetry or analytics exist in NoteFlow.',
          ),
        ],
      ),
    );
  }
}
