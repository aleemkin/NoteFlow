import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:window_manager/window_manager.dart';

import 'package:noteflow/app/notebook_app.dart';
import 'package:noteflow/core/platform/app_platform.dart';
import 'package:noteflow/features/support/support.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPlatform.initializePaths();

  // On mobile platforms (Android/iOS), initialize Google Mobile Ads and Billing
  if (AppPlatform.isMobile && !Platform.environment.containsKey('FLUTTER_TEST')) {
    try {
      SupportService.instance = ProductionSupportService();
    } catch (e) {
      debugPrint('SupportService initialization error: $e');
    }
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('MobileAds initialization error: $e');
    }
  }

  // On desktop platforms (Linux, macOS, Windows), hide the native OS title bar
  // so that the Flutter WindowChrome acts as the window title bar.
  if (AppPlatform.isDesktop) {
    try {
      await windowManager.ensureInitialized();

      const windowOptions = WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(640, 480),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (_) {
      // In headless test environments or when running tests, gracefully continue
    }
  }

  runApp(const ProviderScope(child: NotebookApp()));
}
