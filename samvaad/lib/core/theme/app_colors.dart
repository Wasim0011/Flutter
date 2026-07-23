import 'package:flutter/material.dart';

/// Centralized color tokens for Samvaad.
///
/// Static const values (not a widget) so they're referenceable from
/// ThemeData, tests, and design tooling without a BuildContext.
///
/// Palette direction: deep teal/indigo as primary (calm, trustworthy,
/// distinct from the generic "Flutter blue" default) with a warm coral
/// accent reserved for live/active states — incoming calls, recording
/// indicators, notification badges.
abstract final class AppColors {
  // Brand — identity
  static const Color primary = Color(0xFF0F5257); // deep teal
  static const Color primaryLight = Color(0xFF3D7C81);
  static const Color primaryContainer = Color(0xFFD3E8E9);

  // Brand — liveness / urgency (calls, live captions, notifications)
  static const Color accent = Color(0xFFFF6B4A); // warm coral
  static const Color accentContainer = Color(0xFFFFE0D6);

  // Surfaces
  static const Color surfaceLight = Color(0xFFFAFAF8);
  static const Color surfaceDark = Color(0xFF10151A);

  // Semantic
  static const Color error = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFC77700);
  static const Color success = Color(0xFF1E8E63);
}