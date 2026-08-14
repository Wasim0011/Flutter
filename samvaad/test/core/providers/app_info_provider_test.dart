import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/core/providers/app_info_provider.dart';

void main() {
  group('appInfoProvider', () {
    test('returns the expected foundation build string', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final String value = container.read(appInfoProvider);

      expect(value, 'Samvaad v0.1.0 — foundation build');
    });

    test('can be overridden in tests', () {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          appInfoProvider.overrideWith((ref) => 'overridden value'),
        ],
      );
      addTearDown(container.dispose);

      final String value = container.read(appInfoProvider);

      expect(value, 'overridden value');
    });
  });
}