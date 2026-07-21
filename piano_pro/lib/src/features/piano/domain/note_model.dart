import 'dart:math' as math;

/// Represents a single piano note with all its musical properties.
class NoteModel {
  const NoteModel({
    required this.name,
    required this.octave,
    required this.isSharp,
    required this.midiNumber,
    required this.frequency,
    required this.assetPath,
  });

  final String name;       // e.g. "C", "C#", "D"
  final int octave;        // e.g. 4
  final bool isSharp;      // black key?
  final int midiNumber;    // MIDI note number (0-127)
  final double frequency;  // Hz
  final String assetPath;  // e.g. "assets/sounds/C4.flac"

  /// Display label shown on white keys
  String get label => isSharp ? '' : name;

  /// Full note name e.g. "C#4"
  String get fullName => '$name$octave';

  @override
  String toString() => fullName;

  @override
  bool operator ==(Object other) =>
      other is NoteModel && other.midiNumber == midiNumber;

  @override
  int get hashCode => midiNumber.hashCode;
}

/// Generates a list of [NoteModel]s across the given octave range.
class NoteFactory {
  static const List<_NoteDef> _chromatic = [
    _NoteDef('C',  false),
    _NoteDef('C#', true),
    _NoteDef('D',  false),
    _NoteDef('D#', true),
    _NoteDef('E',  false),
    _NoteDef('F',  false),
    _NoteDef('F#', true),
    _NoteDef('G',  false),
    _NoteDef('G#', true),
    _NoteDef('A',  false),
    _NoteDef('A#', true),
    _NoteDef('B',  false),
  ];

  /// A4 = MIDI 69 = 440 Hz
  static double midiToFrequency(int midi) =>
      440.0 * math.pow(2.0, (midi - 69) / 12.0);

  /// Build all notes for [octaves] starting at [startOctave].
  static List<NoteModel> buildRange({
    int startOctave = 3,
    int octaves = 3,
  }) {
    final notes = <NoteModel>[];
    int midi = 12 + (startOctave * 12); // C of startOctave

    for (int oct = startOctave; oct < startOctave + octaves; oct++) {
      for (final def in _chromatic) {
        notes.add(NoteModel(
          name: def.name,
          octave: oct,
          isSharp: def.isSharp,
          midiNumber: midi,
          frequency: midiToFrequency(midi),
          assetPath: 'assets/sounds/${def.name.replaceAll('#', 's')}$oct.flac',
        ));
        midi++;
      }
    }

    // Final C to close the keyboard
    notes.add(NoteModel(
      name: 'C',
      octave: startOctave + octaves,
      isSharp: false,
      midiNumber: midi,
      frequency: midiToFrequency(midi),
      assetPath: 'assets/sounds/C${startOctave + octaves}.flac',
    ));

    return notes;
  }
}

class _NoteDef {
  const _NoteDef(this.name, this.isSharp);
  final String name;
  final bool isSharp;
}
