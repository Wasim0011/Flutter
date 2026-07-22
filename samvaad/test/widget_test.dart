import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/main.dart';

void main() {
  testWidgets('SamvaadApp renders foundation placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const SamvaadApp());

    expect(find.text('Samvaad — foundation build'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}