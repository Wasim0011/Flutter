import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

/// Single place where app startup concerns are wired together.
/// Firebase must be initialized before `runApp`, since providers and
/// screens further down the tree assume it's already available —
/// there's no "loading" state for Firebase.initializeApp() itself at
/// this layer; if it fails, we want that to surface immediately and
/// loudly during development, not be silently swallowed.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: SamvaadApp()));
}

/// Root widget for Samvaad.
///
/// Now a ConsumerWidget (was StatelessWidget) because the router
/// itself became a Riverpod provider in Milestone 2.6 — `appRouter`
/// (a plain top-level GoRouter) no longer exists; `appRouterProvider`
/// replaces it so `redirect` can react to live auth state. Watching it
/// here means MaterialApp.router rebuilds with a fresh GoRouter only
/// if the provider itself is ever recreated (it won't be, in normal
/// operation) — auth-driven redirects happen inside GoRouter via its
/// own refreshListenable, not by rebuilding this widget.
class SamvaadApp extends ConsumerWidget {
  const SamvaadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Samvaad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}