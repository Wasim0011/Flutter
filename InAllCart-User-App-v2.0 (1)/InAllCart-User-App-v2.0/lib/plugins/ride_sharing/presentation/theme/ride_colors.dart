import 'package:flutter/material.dart';

/// Plugin-local color palette for the ride-sharing experience.
///
/// The ride-sharing module uses its own black + yellow (Rapido-style) brand,
/// independent of the host app's global [AppColors]. Keeping these here means
/// retheming the ride flow never affects the rest of the app.
class RideColors {
  RideColors._();

  /// Primary brand — near-black. Used for primary CTAs and gradient headers.
  static const Color primary = Color(0xFF1A1A1A);
  static const Color primaryDark = Color(0xFF000000);

  /// Accent brand — yellow. Used for highlights, selected states, the PIN, etc.
  static const Color accent = Color(0xFFFFC400);

  /// Pale yellow surface, e.g. selected vehicle card background.
  static const Color accentSoft = Color(0xFFFFF8E1);

  /// Text/icon color that sits on top of [accent].
  static const Color onAccent = Color(0xFF1A1A1A);

  /// Dark gradient used for headers and the PIN badge.
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF2A2A2A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
