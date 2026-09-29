import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';

/// Celebratory modal dialog acknowledging the user's contribution.
class ContributionSuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String iconEmoji;

  const ContributionSuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.iconEmoji = '☕',
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String iconEmoji = '☕',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ContributionSuccessDialog(
        title: title,
        message: message,
        iconEmoji: iconEmoji,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF30363D)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large celebratory badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0x22F59E0B),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x66F59E0B),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    iconEmoji,
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDFE2EB),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF238636),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'You\'re Awesome!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
