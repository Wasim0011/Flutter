import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/features/piano/presentation/piano_screen.dart';
import 'src/core/constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape — piano needs width
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Full-screen immersive
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: AppColors.background,
    ),
  );

  runApp(const ProviderScope(child: PianoApp()));
}

class PianoApp extends StatelessWidget {
  const PianoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piano Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary:   AppColors.glowAmber,
          secondary: AppColors.glowCyan,
          surface:   AppColors.surface,
        ),
      ),
      home: const PianoScreen(),
    );
  }
}
