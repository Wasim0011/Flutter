import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/core/router/app_router.dart';
import 'package:samvaad/core/router/app_routes.dart';
import 'package:samvaad/features/auth/domain/entities/app_user.dart';
import 'package:samvaad/features/auth/presentation/providers/app_session.dart';

void main() {
  const AppUser user = AppUser(id: 'u1', phoneNumber: '+919999999999');
  String? go(AppSession s, String location) =>
      appRedirect(session: s, location: location);

  test('loading: everything waits on splash', () {
    expect(
      go(const AppSessionLoading(), AppRoutes.phoneEntry),
      AppRoutes.splash,
    );
    expect(go(const AppSessionLoading(), AppRoutes.splash), isNull);
  });

  test('signed out: only auth routes are reachable', () {
    const s = AppSessionSignedOut();
    expect(go(s, AppRoutes.home), AppRoutes.phoneEntry);
    expect(go(s, AppRoutes.splash), AppRoutes.phoneEntry);
    expect(go(s, AppRoutes.phoneEntry), isNull);
    expect(go(s, AppRoutes.otpVerification), isNull);
  });

  test('needs onboarding: everything goes to onboarding', () {
    const s = AppSessionNeedsOnboarding(user);
    expect(go(s, AppRoutes.home), AppRoutes.onboarding);
    expect(go(s, AppRoutes.splash), AppRoutes.onboarding);
    expect(go(s, AppRoutes.onboarding), isNull);
  });

  test('ready: auth/onboarding/splash go home, app routes are left alone', () {
    const s = AppSessionReady(user);
    expect(go(s, AppRoutes.splash), AppRoutes.home);
    expect(go(s, AppRoutes.phoneEntry), AppRoutes.home);
    expect(go(s, AppRoutes.onboarding), AppRoutes.home);
    expect(go(s, AppRoutes.home), isNull);
    expect(go(s, AppRoutes.conversation), isNull);
  });
}
