import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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