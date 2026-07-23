import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/main.dart';

void main() {
  testWidgets('SamvaadApp renders themed foundation placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const SamvaadApp());

    expect(find.text('Samvaad'), findsOneWidget);
    expect(find.text('Foundation build — theming active'), findsOneWidget);

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme?.useMaterial3, isTrue);
    expect(app.darkTheme?.useMaterial3, isTrue);
  });
}