import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/bootstrap.dart';
import 'package:samvaad/features/auth/presentation/providers/auth_providers.dart';
import 'features/auth/fakes/fake_auth_repository.dart';
import 'test_utils/firebase_test_setup.dart';

void main() {
  setUpAll(ensureFirebaseTestSetup);

  testWidgets('SamvaadApp boots and renders the splash route for a signed-out user', (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository();
    addTearDown(fakeRepo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const SamvaadApp(),
      ),
    );
    await tester.pumpAndSettle();

    // A signed-out user is redirected straight to phone entry by the
    // router guard, so "Sign in" (PhoneEntryPage's AppBar title) is
    // what should actually render here now — not the old splash text.
    expect(find.text('Sign in'), findsOneWidget);
  });
}