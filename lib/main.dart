import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:noteflow/app/notebook_app.dart';
import 'package:noteflow/core/platform/app_platform.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPlatform.initializePaths();

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
