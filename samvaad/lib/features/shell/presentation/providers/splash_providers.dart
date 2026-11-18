import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_providers.g.dart';

/// Ensures the brand splash animation has enough time to complete its
/// entrance sequence on initial app launch before the router redirects.
///
/// Kept alive so subsequent session re-evaluations (such as completing
/// onboarding) do not re-trigger another multi-second hold. Override this
/// provider in widget/integration tests so `pumpAndSettle` resolves immediately.
@Riverpod(keepAlive: true)
Future<void> splashHold(Ref ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 3600));
}
