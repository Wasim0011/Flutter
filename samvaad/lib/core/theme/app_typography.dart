import 'package:flutter/material.dart';

/// Typography scale for Samvaad.
///
/// Legibility is a functional requirement here, not a stylistic
/// preference: captions and translated text are core to how users
/// experience the product, so sizes lean slightly larger and line-heights
/// slightly looser than a typical default Material scale.
abstract final class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final Color base = brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.95)
        : Colors.black.withValues(alpha: 0.87);

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32, fontWeight: FontWeight.w700, color: base, height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w600, color: base, height: 1.3,
      ),
      titleLarge: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600, color: base, height: 1.3,
      ),
      bodyLarge: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w400, color: base, height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w400, color: base, height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600, color: base, height: 1.4,
      ),
    );
  }
}