# 🎹 Piano Pro

A professional, polyphonic piano application built with Flutter — featuring real-time audio playback, neon glow visual effects, multi-touch support, and a refined dark luxury UI.

---

## ✨ Features

- **Polyphonic Playback** — Play multiple notes simultaneously with up to 32 active voices via [flutter_soloud](https://github.com/alnitak/flutter_soloud)
- **Multi-Touch Input** — Full gesture support for simultaneous key presses across the keyboard
- **Neon Glow Effects** — Animated glow, pulse, and ripple effects on key press
- **3 Octave Range** — 37 keys spanning C3–C6, with ±2 octave shift controls
- **Sustain Pedal** — Toggle sustain mode from the top control bar
- **Volume Control** — Real-time volume slider with per-voice fade-out on release
- **Landscape Optimised** — Forced landscape layout for maximum key width
- **Low-Latency Audio** — Pre-loaded WAV samples for near-zero first-press latency

---

## 📸 Preview

> _Run on a physical device in landscape orientation for the best experience._

---

## 🏗️ Architecture

The project follows a clean **feature-first** structure with Riverpod for state management:

```
lib/
├── main.dart
└── src/
    ├── features/
    │   └── piano/
    │       ├── data/
    │       │   └── audio_service.dart       # SoLoud wrapper — init, preload, play, stop
    │       ├── domain/
    │       │   └── note_model.dart          # NoteModel + NoteFactory (MIDI/frequency logic)
    │       └── presentation/
    │           ├── providers/
    │           │   └── piano_provider.dart  # Riverpod providers + PianoController
    │           ├── widgets/
    │           │   ├── piano_key.dart       # WhitePianoKey & BlackPianoKey
    │           │   └── neon_glow.dart       # NeonGlow, PulsingGlow, KeyRipple
    │           └── piano_screen.dart        # Root screen + layout
    └── core/
        └── constants/
            └── colors.dart                  # Design token palette
```

### State Management

| Provider | Type | Responsibility |
|---|---|---|
| `pianoControllerProvider` | `Provider` | Orchestrates play / stop calls |
| `pressedNotesProvider` | `StateNotifierProvider<Set<int>>` | Tracks active MIDI note numbers |
| `allNotesProvider` | `Provider<List<NoteModel>>` | Generates the full note range |
| `sustainProvider` | `StateProvider<bool>` | Sustain pedal toggle |
| `volumeProvider` | `StateProvider<double>` | Master volume (0.0 – 1.0) |
| `octaveShiftProvider` | `StateProvider<int>` | Octave transpose (−2 to +2) |

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version |
|---|---|
| Flutter | ≥ 3.19.0 |
| Dart | ≥ 3.0.0 |
| Android `minSdkVersion` | 21 |
| iOS Deployment Target | 13.0 |

### 1. Clone & Install

```bash
git clone https://github.com/your-username/piano_pro.git
cd piano_pro
flutter pub get
```

### 2. Add Audio Samples

Piano Pro uses real sampled audio. Place `.wav` files in `assets/sounds/` using the naming convention below:

| Key | Filename | Key | Filename |
|---|---|---|---|
| C3 | `C3.wav` | C#3 | `Cs3.wav` |
| D3 | `D3.wav` | D#3 | `Ds3.wav` |
| … | … | … | … |
| C6 | `C6.wav` | | |

> **Free samples:** [University of Iowa Electronic Music Studios — Piano](https://theremin.music.uiowa.edu/MIpiano.html)  
> Replace `#` with `s` in filenames (e.g. `C#4` → `Cs4.wav`).

### 3. Run

```bash
# Physical device recommended for multi-touch & audio latency
flutter run --release
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.5.1   # State management
  flutter_soloud: ^2.0.0     # Low-latency audio engine
  just_audio: ^0.9.38        # Fallback audio
  collection: ^1.18.0        # Utilities
```

---

## 🎨 Design System

All design tokens live in `lib/src/core/constants/colors.dart`.

| Token | Hex | Usage |
|---|---|---|
| `background` | `#0A0A0F` | App background |
| `whiteKey` | `#F5F0E8` | White piano keys |
| `blackKey` | `#1A1A22` | Black piano keys |
| `glowPrimary` | `#FFB300` | Amber neon glow (white keys) |
| `glowBlue` | `#40C4FF` | Blue neon glow (black keys) |

---

## 🧭 Roadmap

- [ ] MIDI input/output support
- [ ] Metronome with tap-tempo
- [ ] Record & playback
- [ ] Additional instrument voices (organ, strings)
- [ ] Chord detection overlay
- [ ] iPad split-screen support

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">Built with Flutter 💙</p>