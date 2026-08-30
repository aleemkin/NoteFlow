import 'package:go_router/go_router.dart';

import 'package:noteflow/features/shell/presentation/home_screen.dart';

/// Application router using go_router.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())],
);
