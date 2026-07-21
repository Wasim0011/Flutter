import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/audio_service.dart';
import '../../domain/note_model.dart';
import 'package:flutter_riverpod/legacy.dart';

// ── Piano config (base range — octave shift applied on top) ───────────────────

class PianoConfig {
  const PianoConfig({this.baseOctave = 3, this.octaves = 5});
  final int baseOctave;
  final int octaves;
}

final pianoConfigProvider = Provider<PianoConfig>((_) => const PianoConfig());

// ── Octave shift: -2 … +2 ────────────────────────────────────────────────────

final octaveShiftProvider = StateProvider<int>((ref) => 0);

// ── All notes — rebuilt whenever octave shift changes ────────────────────────

final allNotesProvider = Provider<List<NoteModel>>((ref) {
  final cfg   = ref.watch(pianoConfigProvider);
  final shift = ref.watch(octaveShiftProvider);
  final start = (cfg.baseOctave + shift).clamp(0, 7).toInt();
  return NoteFactory.buildRange(startOctave: start, octaves: cfg.octaves);
});

// ── Pressed notes ─────────────────────────────────────────────────────────────

final pressedNotesProvider =
StateNotifierProvider<PressedNotesNotifier, Set<int>>(
        (_) => PressedNotesNotifier());

class PressedNotesNotifier extends StateNotifier<Set<int>> {
  PressedNotesNotifier() : super({});

  void press(int midi)   => state = {...state, midi};
  void release(int midi) => state = state.difference({midi});
  bool isPressed(int midi) => state.contains(midi);

  /// Release everything (e.g. when octave shifts mid-play).
  void releaseAll() => state = {};
}

// ── Sustain ───────────────────────────────────────────────────────────────────

final sustainProvider = StateProvider<bool>((ref) => false);

// Wires sustain state → AudioService
final _sustainWatcherProvider = Provider<void>((ref) {
  final on = ref.watch(sustainProvider);
  ref.read(audioServiceProvider).setSustain(on);
});

// ── Volume ────────────────────────────────────────────────────────────────────

final volumeProvider = StateProvider<double>((ref) => 0.85);

// Wires volume state → AudioService
final _volumeWatcherProvider = Provider<void>((ref) {
  final v = ref.watch(volumeProvider);
  ref.read(audioServiceProvider).setVolume(v);
});

// ── Piano controller ──────────────────────────────────────────────────────────

final pianoControllerProvider = Provider<PianoController>(PianoController.new);

class PianoController {
  PianoController(this._ref) {
    // Kick off the watchers so they're alive for the app lifetime
    _ref.read(_sustainWatcherProvider);
    _ref.read(_volumeWatcherProvider);
  }

  final Ref _ref;

  AudioService get _audio   => _ref.read(audioServiceProvider);
  PressedNotesNotifier get _pressed =>
      _ref.read(pressedNotesProvider.notifier);

  Future<void> initialize() async {
    await _audio.initialize();
    final notes = _ref.read(allNotesProvider);
    await _audio.preloadNotes(notes);
  }

  /// Call when octave shift changes — stops all playing notes & reloads.
  Future<void> onOctaveChanged() async {
    _pressed.releaseAll();
    final notes = _ref.read(allNotesProvider);
    await _audio.preloadNotes(notes);
  }

  void onNoteDown(NoteModel note) {
    _pressed.press(note.midiNumber);
    _audio.playNote(note);
  }

  void onNoteUp(NoteModel note) {
    _pressed.release(note.midiNumber);
    _audio.stopNote(note);
  }
}
