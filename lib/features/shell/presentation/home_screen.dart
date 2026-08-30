import 'package:flutter/material.dart';
import 'package:noteflow/core/platform/app_platform.dart';
import 'desktop/desktop.dart';
import 'mobile/mobile.dart';

export 'desktop/desktop.dart';
export 'home_shared/home.dart';
export 'mobile/mobile.dart';

/// Adaptive Home Screen that routes to [MobileHomeScreen] on mobile platforms (Android / iOS)
/// and [DesktopHomeScreen] on desktop platforms (Linux / Windows / macOS).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isMobile) {
      return const MobileHomeScreen();
    }
    return const DesktopHomeScreen();
  }
}
