// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For mdappworks, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:piano_pro/main.dart';
import 'package:piano_pro/src/features/piano/data/audio_service.dart';
import 'package:piano_pro/src/features/piano/domain/note_model.dart';

class FakeAudioService implements AudioService {
  @override
  Future<void> initialize() async {}
  @override
  Future<void> preloadNotes(List<NoteModel> notes) async {}
  @override
  void setVolume(double v) {}
  @override
  void setSustain(bool on) {}
  @override
  Future<void> playNote(NoteModel note) async {}
  @override
  Future<void> stopNote(NoteModel note) async {}
  @override
  void dispose() {}
}

void main() {
  testWidgets('Piano app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(FakeAudioService()),
        ],
        child: const PianoApp(),
      ),
    );

    // Verify that the app starts and displays the piano screen.
    expect(find.byType(MaterialApp), findsOneWidget);
    // You can add more specific checks here, like finding a key
  });
}
