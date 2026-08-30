import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../domain/note_model.dart';

/// Provides the singleton [AudioService].
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});

/// Low-level wrapper around flutter_soloud.
/// Handles init, preloading, polyphonic playback, volume, and sustain.
class AudioService {
  final SoLoud _soloud = SoLoud.instance;

  final Map<int, AudioSource> _sources = {};
  final Map<int, SoundHandle> _handles = {};

  bool _initialized = false;
  double _volume = 0.85;
  bool _sustain = false;

  // Notes released while sustain is on — held until sustain is lifted
  final Set<int> _sustainedMidi = {};

  Future<void> initialize() async {
    if (_initialized) return;
    await _soloud.init();
    _soloud.setMaxActiveVoiceCount(32);
    _initialized = true;
  }

  Future<void> preloadNotes(List<NoteModel> notes) async {
    // Run all loads concurrently instead of sequentially
    await Future.wait(
      notes.map((note) async {
        try {
          final source = await _soloud.loadAsset(note.assetPath);
          _sources[note.midiNumber] = source;
        } catch (e) {
          debugPrint('AudioService: ${note.assetPath} missing — will pitch-shift.');
        }
      }),
    );
  }

  // ── Volume ──────────────────────────────────────────────────────────────────

  /// 0.0 – 1.0.  Affects all subsequent note plays and live handles.
  void setVolume(double v) {
    _volume = v.clamp(0.0, 1.0);
    // Update all currently playing handles
    for (final handle in _handles.values) {
      try {
        _soloud.setVolume(handle, _volume);
      } catch (_) {}
    }
  }

  // ── Sustain ─────────────────────────────────────────────────────────────────

  void setSustain(bool on) {
    _sustain = on;
    if (!on) {
      // Release all notes that were held only by sustain
      for (final midi in List<int>.from(_sustainedMidi)) {
        _fadeStop(midi);
      }
      _sustainedMidi.clear();
    }
  }

  // ── Playback ─────────────────────────────────────────────────────────────────

  Future<void> playNote(NoteModel note) async {
    if (!_initialized) return;

    AudioSource? source = _sources[note.midiNumber];
    double rate = 1.0;

    if (source == null) {
      int offset = 1;
      while (offset <= 12) {
        if (_sources.containsKey(note.midiNumber - offset)) {
          source = _sources[note.midiNumber - offset];
          rate = math.pow(2.0, offset / 12.0).toDouble();
          break;
        } else if (_sources.containsKey(note.midiNumber + offset)) {
          source = _sources[note.midiNumber + offset];
          rate = math.pow(2.0, -offset / 12.0).toDouble();
          break;
        }
        offset++;
      }
    }

    if (source == null) return;

    // Re-trigger: stop the old handle for the same note
    _fadeStop(note.midiNumber);
    _sustainedMidi.remove(note.midiNumber);

    try {
      final handle = await _soloud.play(source, volume: _volume);
      if (rate != 1.0) _soloud.setRelativePlaySpeed(handle, rate);
      _handles[note.midiNumber] = handle;
    } catch (e) {
      debugPrint('AudioService: playNote error: $e');
    }
  }

  Future<void> stopNote(NoteModel note) async {
    if (_sustain) {
      // Keep the audio playing but mark as "would have stopped"
      _sustainedMidi.add(note.midiNumber);
      return;
    }
    _fadeStop(note.midiNumber);
  }

  void _fadeStop(int midiNumber) {
    final handle = _handles.remove(midiNumber);
    if (handle != null) {
      try {
        _soloud.fadeVolume(handle, 0, const Duration(milliseconds: 250));
        Future.delayed(const Duration(milliseconds: 270), () {
          try { _soloud.stop(handle); } catch (_) {}
        });
      } catch (_) {}
    }
  }

  void dispose() {
    _soloud.deinit();
  }
}
