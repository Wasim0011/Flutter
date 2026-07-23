import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/main.dart';

void main() {
  testWidgets('SamvaadApp boots and renders the splash route', (WidgetTester tester) async {
    await tester.pumpWidget(const SamvaadApp());
    await tester.pumpAndSettle();

    expect(find.text('Samvaad'), findsOneWidget);
    expect(find.text('Foundation build — routing active'), findsOneWidget);
  });
}