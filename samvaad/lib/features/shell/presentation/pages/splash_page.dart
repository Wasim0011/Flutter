import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Samvaad's entry screen.
///
/// With the router guard (Milestone 2.6) now in place, this screen is
/// reached in exactly two situations: (1) briefly, while the very
/// first auth-state check is in flight, showing a loading indicator;
/// or (2) after a signed-in user is redirected here with nowhere else
/// to go yet, since no home/dashboard feature exists until a later
/// phase. Case (2) is a deliberate, temporary placeholder — it will
/// be replaced the moment a real home screen exists.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<AppUser?> authState = ref.watch(authStateChangesProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.forum_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Samvaad', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 24),
              authState.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stackTrace) => Text(
                  'Something went wrong. Please restart the app.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                data: (user) => Text(
                  user != null
                      ? 'Signed in as ${user.phoneNumber}'
                      : 'Foundation build',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}