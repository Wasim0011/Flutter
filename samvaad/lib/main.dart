import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: SamvaadApp()));
}

/// Root widget for Samvaad.
///
/// Milestone 5 wraps the app in `ProviderScope` at the true root (in
/// `main()`, above `SamvaadApp` itself) — this is the Riverpod
/// convention: the scope must exist before anything in the widget tree
/// tries to read a provider, including the router or a future
/// auth-aware redirect.
class SamvaadApp extends StatelessWidget {
  const SamvaadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Samvaad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}