import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/bootstrap.dart';
import 'test_utils/firebase_test_setup.dart';

void main() {
  setUpAll(ensureFirebaseTestSetup);

  testWidgets('SamvaadApp boots and renders the splash route with provider data', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SamvaadApp()));
    await tester.pumpAndSettle();

    expect(find.text('Samvaad'), findsOneWidget);
    expect(find.textContaining('Firebase connected'), findsOneWidget);
  });
}