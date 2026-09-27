import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';

/// Modal loading overlay displayed during vault unpack, initialization, and loading.
///
/// Features a clear, informative status card with title, dynamic step message,
/// progress bar (or indeterminate spinner), and local-storage indicator.
class VaultLoadingOverlay extends StatelessWidget {
  final String title;
  final String message;
  final double? progress;
  final String? subtitle;

  const VaultLoadingOverlay({
    super.key,
    this.title = 'Setting up Vault',
    required this.message,
    this.progress,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Dimmed backdrop with blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withValues(alpha: 0.70),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF30363D), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Badge
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF58A6FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF58A6FF).withValues(alpha: 0.28),
                          width: 1.2,
                        ),
                      ),
                      child: const Center(
                        child: AppSvgIcon.appIcon(width: 30, height: 30),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: Color(0xFFDFE2EB),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Current step / action message
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF8B949E),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Progress Bar or Spinner
                    if (progress != null) ...[
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Saving files...',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8B949E),
                                ),
                              ),
                              Text(
                                '${(progress!.clamp(0.0, 1.0) * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF58A6FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress!.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: const Color(0xFF21262D),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF58A6FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.8,
                          color: Color(0xFF58A6FF),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Subtitle / explanatory note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.save_outlined,
                          size: 13,
                          color: Color(0xFF484F58),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            subtitle ?? 'Saving notes and diagrams to local storage',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF484F58),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
