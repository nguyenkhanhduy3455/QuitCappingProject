import 'package:flutter/material.dart';

class AppColors {
  static bool _isDark = true;
  static bool get isDark => _isDark;

  static void setIsDark(bool dark) {
    _isDark = dark;
  }

  static void setBrightness(Brightness brightness) {
    _isDark = brightness == Brightness.dark;
  }

  // Adaptive background and surfaces
  static Color get background => _isDark ? const Color(0xFF0D0F14) : const Color(0xFFF6F8FA);
  static Color get surface => _isDark ? const Color(0xFF161B22) : const Color(0xFFFFFFFF);
  static Color get surfaceVariant => _isDark ? const Color(0xFF21262D) : const Color(0xFFEFF2F5);
  static Color get cardBorder => _isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);

  // Brand and status colors (constant across themes)
  static const Color primary = Color(0xFFFF5722); // QuitCapping Electric Orange
  static const Color primaryVariant = Color(0xFFFF6F00);
  static const Color secondary = Color(0xFF7C4DFF); // Deep purple accent

  static const Color approve = Color(0xFF00E676); // Swipe right neon green
  static const Color reject = Color(0xFFFF1744); // Swipe left crimson red
  static const Color pending = Color(0xFFFFD600); // Give-to-get quota amber
  static const Color inQueue = Color(0xFF00B0FF); // In-queue electric blue

  // Adaptive text colors
  static Color get textPrimary => _isDark ? const Color(0xFFF0F6FC) : const Color(0xFF1F2328);
  static Color get textSecondary => _isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A);
  static Color get textMuted => _isDark ? const Color(0xFF484F58) : const Color(0xFF8C959F);
}
