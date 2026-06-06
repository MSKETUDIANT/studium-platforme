import 'package:flutter/material.dart';

/// Extension sur BuildContext pour obtenir les couleurs qui s'adaptent
/// automatiquement au thème clair/sombre.
extension AdaptiveColors on BuildContext {
  bool   get isDark     => Theme.of(this).brightness == Brightness.dark;
  Color  get cardColor  => Theme.of(this).colorScheme.surface;
  Color  get textPrimary => Theme.of(this).colorScheme.onSurface;
  Color  get textMuted  => const Color(0xFF9CA3AF);
  Color  get border     => isDark ? const Color(0xFF1E2A52) : const Color(0xFFE5E7EB);
  Color  get pageBg     => Theme.of(this).scaffoldBackgroundColor;
}
