import 'package:flutter/material.dart';
import 'package:noteflow/core/notifications/app_notification.dart';
import 'package:noteflow/core/router/app_router.dart';
import 'package:noteflow/core/theme/app_theme.dart';

/// Root application widget.
class NotebookApp extends StatelessWidget {
  const NotebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Noteflow',
      scaffoldMessengerKey: AppNotification.scaffoldMessengerKey,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
