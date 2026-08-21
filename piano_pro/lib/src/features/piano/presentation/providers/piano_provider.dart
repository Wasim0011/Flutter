import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateProvider, StateNotifier, StateNotifierProvider
import '../../data/audio_service.dart';
import '../../domain/note_model.dart';

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

  void press(int midi)     => state = {...state, midi};
  void release(int midi)   => state = state.difference({midi});
  bool isPressed(int midi) => state.contains(midi);

  /// Release everything (e.g. when octave shifts mid-play).
  void releaseAll() => state = {};
}

// ── Sustain (UI state only — audio engine called via PianoController) ─────────

final sustainProvider = StateProvider<bool>((ref) => false);

// ── Volume (UI state only — audio engine called via PianoController) ──────────

final volumeProvider = StateProvider<double>((ref) => 0.85);

// ── Piano controller ──────────────────────────────────────────────────────────

final pianoControllerProvider = Provider<PianoController>(PianoController.new);

class PianoController {
  PianoController(this._ref);

  final Ref _ref;

  AudioService get _audio => _ref.read(audioServiceProvider);
  PressedNotesNotifier get _pressed =>
      _ref.read(pressedNotesProvider.notifier);

  Future<void> initialize() async {
    await _audio.initialize();
    // Sync initial volume to audio engine
    _audio.setVolume(_ref.read(volumeProvider));
    final notes = _ref.read(allNotesProvider);
    await _audio.preloadNotes(notes);
  }

  /// Call when octave shift changes — stops all playing notes & reloads.
  Future<void> onOctaveChanged() async {
    _pressed.releaseAll();
    final notes = _ref.read(allNotesProvider);
    await _audio.preloadNotes(notes);
  }

  /// Toggle sustain — updates BOTH Riverpod state AND the audio engine.
  /// This is the ONLY correct way to change sustain; never write sustainProvider
  /// directly from the UI.
  void toggleSustain() {
    final next = !_ref.read(sustainProvider);
    _ref.read(sustainProvider.notifier).state = next;
    _audio.setSustain(next); // ← the actual audio engine call
  }

  /// Set volume — updates BOTH Riverpod state AND the audio engine.
  void setVolume(double v) {
    _ref.read(volumeProvider.notifier).state = v;
    _audio.setVolume(v); // ← the actual audio engine call
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