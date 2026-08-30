import 'package:flutter/material.dart';

/// Legal footer displaying Privacy Policy and Third-Party License attributions.
class WelcomeLegalFooter extends StatelessWidget {
  const WelcomeLegalFooter({super.key});

  static void showPrivacyPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF30363D)),
          ),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF58A6FF), size: 22),
              SizedBox(width: 10),
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDFE2EB),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 420),
            child: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Local-First & Offline Privacy Guarantee',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDFE2EB),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Noteflow is built on local-first principles. Your privacy is protected by default:\n\n'
                    '1. Zero Data Collection: Noteflow does not collect, transmit, profile, or sell your personal data, notes, vaults, or device identifiers.\n\n'
                    '2. Local Storage Only: All Markdown files, canvas drawings, and attachments stay strictly on your local device in the folders you designate.\n\n'
                    '3. No External Analytics or Tracking: There are no hidden telemetry, advertising SDKs, or behavioral trackers running inside Noteflow.\n\n'
                    '4. Network Usage: Noteflow operates 100% offline. Network permission is declared solely to allow opening external web hyperlinks that you explicitly tap inside notes.\n\n'
                    '5. Your Control: You retain full ownership and control of all your data at all times. Deleting a note or vault immediately modifies only your local filesystem.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: Color(0xFF8B949E),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF58A6FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showAttributions(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF30363D)),
          ),
          title: const Row(
            children: [
              Icon(Icons.code_rounded, color: Color(0xFFA78BFA), size: 22),
              SizedBox(width: 10),
              Text(
                'Open Source & Licenses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDFE2EB),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 420),
            child: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Excalidraw Attribution & Notice',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDFE2EB),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Visual drawing and canvas features in Noteflow incorporate Excalidraw, which is licensed under the MIT License.\n\n'
                    'Copyright (c) Excalidraw contributors.\n\n'
                    'Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the condition that the copyright notice and permission notice be included in all copies or substantial portions of the Software.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF8B949E),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Flutter & Ecosystem Packages',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDFE2EB),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Noteflow is built using Flutter and the Dart ecosystem, licensed under BSD-style licenses by Google LLC and community contributors.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF8B949E),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF58A6FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: Color(0xFF21262D), height: 1),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              onPressed: () => showPrivacyPolicy(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF58A6FF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Text(
              '•',
              style: TextStyle(color: Color(0xFF484F58), fontSize: 12),
            ),
            TextButton(
              onPressed: () => showAttributions(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Third-Party Notices & Licenses',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8B949E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '© 2026 Noteflow • Excalidraw is licensed under MIT / Excalidraw contributors',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Color(0xFF484F58), height: 1.4),
        ),
      ],
    );
  }
}
