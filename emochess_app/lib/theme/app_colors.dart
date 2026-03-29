import 'package:flutter/material.dart';

/// EmoChess Color Palette
/// Calming cyan + health green theme
/// Designed for low visual stimulation and high readability
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF0891B2); // Calming Cyan
  static const Color primaryLight = Color(0xFF22D3EE); // Light Cyan
  static const Color primaryDark = Color(0xFF0E7490); // Dark Cyan

  // Secondary colors
  static const Color secondary = Color(0xFF22D3EE); // Light Cyan
  static const Color success = Color(0xFF059669); // Health Green
  static const Color successLight = Color(0xFF10B981); // Light Green

  // Background colors
  static const Color background = Color(0xFFECFEFF); // Soft Cream Cyan
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceAlt = Color(0xFFF0FDFA); // Very Light Cyan

  // Text colors
  static const Color textPrimary = Color(0xFF164E63); // Dark Cyan
  static const Color textSecondary = Color(0xFF0E7490); // Medium Cyan
  static const Color textMuted = Color(0xFF67E8F9); // Light Cyan (muted)

  // Emotion colors (soft, non-aggressive)
  static const Color emotionHappy = Color(0xFF34D399); // Soft Green
  static const Color emotionNeutral = Color(0xFFFCD34D); // Soft Yellow
  static const Color emotionAnxious = Color(0xFFF472B6); // Soft Pink
  static const Color emotionFrustrated = Color(
    0xFFFB923C,
  ); // Soft Orange (not red!)

  // Chess board colors (high contrast but calming)
  static const Color boardLight = Color(0xFFF0FDFA); // Light square
  static const Color boardDark = Color(0xFF99F6E4); // Dark square (teal)
  static const Color moveHighlight = Color(0xFF22D3EE); // Move indicator
  static const Color captureHighlight = Color(0xFFFB923C); // Capture indicator

  // UI elements
  static const Color border = Color(0xFF67E8F9); // Light cyan border
  static const Color shadowDark = Color(0xFF0E7490); // Shadow (dark)
  static const Color shadowLight = Color(0xFFCFFAFE); // Shadow (light)

  // Error (soft orange, not aggressive red)
  static const Color error = Color(0xFFFB7185); // Soft coral

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient calmGradient = LinearGradient(
    colors: [Color(0xFFECFEFF), Color(0xFFF0FDFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
