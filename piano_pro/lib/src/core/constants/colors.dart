import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────────
  static const Color background    = Color(0xFF08080D);
  static const Color surface       = Color(0xFF0F0F18);
  static const Color surfaceHigh   = Color(0xFF161622);
  static const Color panelBg       = Color(0xFF0C0C14);

  // ── White keys ───────────────────────────────────────────────────────────────
  static const Color whiteKeyTop      = Color(0xFFFFFDF8);
  static const Color whiteKey         = Color(0xFFF2EDE0);
  static const Color whiteKeyBottom   = Color(0xFFD4C9A8);
  static const Color whiteKeyPressed  = Color(0xFFD6C47A);   // warm amber tint
  static const Color whiteKeyPressedB = Color(0xFFBFA855);
  static const Color whiteKeyShadow   = Color(0xFF9E9070);

  // ── Black keys ───────────────────────────────────────────────────────────────
  static const Color blackKeyTop      = Color(0xFF242430);
  static const Color blackKeyMid      = Color(0xFF14141C);
  static const Color blackKeyBase     = Color(0xFF060608);
  static const Color blackKeySheen    = Color(0xFF32323F);   // gloss highlight strip
  static const Color blackKeyPressed  = Color(0xFF1E2A3A);   // blue tint when pressed
  static const Color blackKeyPressedB = Color(0xFF0D1A2A);

  // ── Glow / accent ────────────────────────────────────────────────────────────
  static const Color glowAmber    = Color(0xFFFFB300);
  static const Color glowAmberB   = Color(0xFFFF8F00);
  static const Color glowAmberC   = Color(0xFFFFE082);
  static const Color glowCyan     = Color(0xFF00E5FF);
  static const Color glowCyanB    = Color(0xFF00B8D4);
  static const Color glowCyanC    = Color(0xFFB2EBF2);
  static const Color glowWhite    = Color(0xCCFFFFFF);

  // Legacy aliases kept for any widget that still references them
  static const Color glowPrimary   = glowAmber;
  static const Color glowSecondary = glowAmberB;
  static const Color glowAccent    = glowAmberC;
  static const Color glowBlue      = glowCyan;

  // ── Text ─────────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFECE8DC);
  static const Color textSecondary = Color(0xFF7A7868);
  static const Color textMuted     = Color(0xFF383830);

  // ── Borders / dividers ───────────────────────────────────────────────────────
  static const Color keyBorder   = Color(0xFF2A2A20);
  static const Color panelBorder = Color(0xFF1C1C28);

  // ── Wood rail ────────────────────────────────────────────────────────────────
  static const Color woodDark  = Color(0xFF1C0F08);
  static const Color woodMid   = Color(0xFF2E1A0E);
  static const Color woodLight = Color(0xFF4A2E1A);
  static const Color woodSheen = Color(0xFF5C3820);
}
