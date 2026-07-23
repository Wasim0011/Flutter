import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/core/router/app_router.dart';
import 'package:samvaad/core/router/app_routes.dart';

void main() {
  group('appRouter', () {
    test('initial location is the splash route', () {
      expect(appRouter.routeInformationProvider.value.uri.toString(), AppRoutes.splash);
    });

    test('splash route is registered by name', () {
      final String location = appRouter.namedLocation(AppRoutes.splashName);
      expect(location, AppRoutes.splash);
    });
  });
}