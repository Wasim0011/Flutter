import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';

/// Reusable sign-out affordance. Currently placed on SplashPage since
/// no settings screen exists yet — will move there once one does.
class AppSignOutButton extends ConsumerWidget {
  const AppSignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => ref.read(authRepositoryProvider).signOut(),
      icon: const Icon(Icons.logout),
      label: const Text('Sign out'),
    );
  }
}