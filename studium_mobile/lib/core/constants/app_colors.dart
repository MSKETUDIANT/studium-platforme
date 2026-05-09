import 'package:flutter/material.dart';

/// AppColors — Tokens couleurs Studium
/// Miroir exact de theme.ts (dashboard web)
/// Source unique de vérité pour toute l'app mobile.
abstract class AppColors {
  // ── Marque ──────────────────────────────────────────────
  static const navy      = Color(0xFF0B1852); // couleur principale
  static const navyLight = Color(0xFF1A2F8A);
  static const blue      = Color(0xFF2546CC);
  static const blueLight = Color(0xFF4D7AFF);

  // ── Fonds ────────────────────────────────────────────────
  static const pageBg    = Color(0xFFEEF0F7);
  static const cardBg    = Color(0xFFFFFFFF);
  static const inputBg   = Color(0xFFF5F7FC);

  // ── Textes ───────────────────────────────────────────────
  static const textPrimary   = Color(0xFF0B1852);
  static const textSecondary = Color(0xFF6B7A9E);
  static const textMuted     = Color(0xFF9BA3BC);
  static const textInverse   = Color(0xFFFFFFFF);

  // ── Bordures ─────────────────────────────────────────────
  static const border      = Color(0x14000000); // rgba(11,24,82,0.08)
  static const borderInput = Color(0xFFDDE1F0);
  static const borderHover = Color(0xFFC2CADF);

  // ── Sémantiques ──────────────────────────────────────────
  static const success   = Color(0xFF16A34A);
  static const successBg = Color(0xFFEAF7EF);
  static const warning   = Color(0xFFD97706);
  static const warningBg = Color(0xFFFFF8EB);
  static const danger    = Color(0xFFDC2626);
  static const dangerBg  = Color(0xFFFEF2F2);

  // ── Dark mode ────────────────────────────────────────────
  static const darkBg        = Color(0xFF0D1121);
  static const darkSurface   = Color(0xFF151B35);
  static const darkBorder    = Color(0xFF1E2A52);
  static const darkText      = Color(0xFFE8EAF2);
  static const darkTextMuted = Color(0xFF6B7A9E);
}