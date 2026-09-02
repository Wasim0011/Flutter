import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/core/providers/firebase_status_provider.dart';
import '../../test_utils/firebase_test_setup.dart';

void main() {
  setUpAll(ensureFirebaseTestSetup);

  test('firebaseStatusProvider reports Firebase is connected with a project id', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final String status = container.read(firebaseStatusProvider);

    // setupFirebaseCoreMocks() returns its own canned FirebaseOptions
    // regardless of what's passed to Firebase.initializeApp(), so we
    // assert on the provider's actual contract — that it reports
    // connection status with *some* project id attached — rather than
    // a specific project id value we don't actually control here.
    expect(status, startsWith('Firebase connected — project:'));
    expect(status, isNot(endsWith('project: ')));
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