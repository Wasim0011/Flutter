import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/main.dart';

void main() {
  testWidgets('SamvaadApp boots and renders the splash route with provider data', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SamvaadApp()));
    await tester.pumpAndSettle();

    expect(find.text('Samvaad'), findsOneWidget);
    expect(find.text('Samvaad v0.1.0 — foundation build'), findsOneWidget);
  });
}