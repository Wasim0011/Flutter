import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_info_provider.dart';

/// Samvaad's entry screen.
///
/// Milestone 5 converts this from StatelessWidget to ConsumerWidget and
/// reads `appInfoProvider` — proving Riverpod DI is wired end-to-end
/// from ProviderScope down to a real widget. Once Auth exists, this
/// becomes the actual splash/bootstrapping screen that decides where to
/// route the user next.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String appInfo = ref.watch(appInfoProvider);

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
                appInfo,
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