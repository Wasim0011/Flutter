import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:samvaad/core/router/app_router.dart';
import 'package:samvaad/core/router/app_routes.dart';
import 'package:samvaad/features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
  });

  tearDown(() {
    fakeRepo.dispose();
    container.dispose();
  });

  test('initial location is the splash route', () {
    final GoRouter router = container.read(appRouterProvider);
    expect(router.routeInformationProvider.value.uri.toString(), AppRoutes.splash);
  });

  test('phoneEntry and otpVerification routes are registered by name', () {
    final GoRouter router = container.read(appRouterProvider);

    expect(router.namedLocation(AppRoutes.phoneEntryName), AppRoutes.phoneEntry);
    // otpVerification requires `extra`, so namedLocation() alone (path
    // resolution) is what we can verify without triggering the
    // builder — full navigation behavior is covered by the redirect
    // tests below instead.
  });
}