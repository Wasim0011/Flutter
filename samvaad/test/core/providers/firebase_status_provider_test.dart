import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/core/providers/firebase_status_provider.dart';
import '../../test_utils/firebase_test_setup.dart';

void main() {
  setUpAll(ensureFirebaseTestSetup);

  test('firebaseStatusProvider reports the connected project id', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final String status = container.read(firebaseStatusProvider);

    expect(status, contains('samvaad-test-project'));
  });

  test('can be overridden in tests', () {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        firebaseStatusProvider.overrideWith((ref) => 'overridden value'),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(firebaseStatusProvider), 'overridden value');
  });
}