import 'package:flutter/material.dart';

/// Palette de couleurs BiblioShare
/// Tons chauds inspirés du papier ancien et du cuir
class AppColors {
  AppColors._();

  // Primary — Brun chaud (authenticité, littérature)
  static const Color primary = Color(0xFF8B6F4E);
  static const Color primaryLight = Color(0xFFC4956A);
  static const Color primaryDark = Color(0xFF5C4033);

  // Secondary — Brun doux
  static const Color secondary = Color(0xFFA67B5B);
  static const Color secondaryLight = Color(0xFFD4B896);
  static const Color secondaryDark = Color(0xFF7A5C3E);

  // Accent — Caramel doré
  static const Color accent = Color(0xFFD4A574);

  // Background
  static const Color background = Color(0xFFFFF8F0);
  static const Color backgroundWarm = Color(0xFFFFF5EB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFF5E6D3);
  static const Color surfaceVariant = Color(0xFFFFF5EB);

  // Text
  static const Color textPrimary = Color(0xFF3D2B1F);
  static const Color textSecondary = Color(0xFF7A6555);
  static const Color textHint = Color(0xFFA69585);

  // Borders
  static const Color border = Color(0xFFE8D5C0);
  static const Color borderLight = Color(0xFFF0E4D4);

  // Status
  static const Color success = Color(0xFF7B9E6B);
  static const Color warning = Color(0xFFD4A04A);
  static const Color error = Color(0xFFC4716C);
  static const Color info = Color(0xFF8B6F4E);

  // Stars
  static const Color starFilled = Color(0xFFD4A04A);
  static const Color starEmpty = Color(0xFFE8D5C0);

  // Gradient (pour boutons primaires)
  static const List<Color> primaryGradient = [
    Color(0xFFC4956A),
    Color(0xFF8B6F4E),
  ];

  // Dark mode
  static const Color darkBackground = Color(0xFF1A1510);
  static const Color darkSurface = Color(0xFF2A231C);
  static const Color darkSurfaceVariant = Color(0xFF3A3028);
}
