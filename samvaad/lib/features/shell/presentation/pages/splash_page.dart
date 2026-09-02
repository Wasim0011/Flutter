import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/firebase_status_provider.dart';

/// Samvaad's entry screen.
///
/// Milestone 2.1 temporarily displays Firebase connectivity status here
/// as proof-of-wiring — the same throwaway pattern used for
/// `appInfoProvider` in Phase 1. Once real auth state exists
/// (Milestone 2.6), this becomes the actual splash/routing-decision
/// screen.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String status = ref.watch(firebaseStatusProvider);

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
              const SizedBox(height: 8),
              Text(
                status,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}