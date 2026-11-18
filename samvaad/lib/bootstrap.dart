import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/calling/presentation/widgets/incoming_call_gate.dart';
import 'firebase_options.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: SamvaadApp()));
}

class SamvaadApp extends ConsumerStatefulWidget {
  const SamvaadApp({super.key});

  @override
  ConsumerState<SamvaadApp> createState() => _SamvaadAppState();
}

class _SamvaadAppState extends ConsumerState<SamvaadApp> {
  @override
  void initState() {
    super.initState();
    // Removes the native splash exactly once our own first frame has
    // actually been scheduled — explicit and deterministic, rather
    // than relying on the OS to decide when "ready" is, which is what
    // makes a genuine startup hang indistinguishable from a working
    // native splash in the first place.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Samvaad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) => IncomingCallGate(child: child!),
    );
  }
}
