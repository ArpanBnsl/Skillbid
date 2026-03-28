import 'package:flutter/material.dart';

/// App color palette — High contrast, bold identity
class AppColors {
  // Primary colors — vibrant teal on dark
  static const Color primaryColor = Color(0xFF00E5CC); // Vibrant teal/cyan
  static const Color primaryDark = Color(0xFF00B8A3);
  static const Color primaryLight = Color(0xFF5EFCE8);

  // Secondary colors
  static const Color secondaryColor = Color(0xFF7C4DFF); // Electric purple
  static const Color secondaryLight = Color(0xFFB388FF);
  static const Color secondaryDark = Color(0xFF651FFF);

  // Accent colors
  static const Color accent = Color(0xFFFF6D00); // Vibrant orange
  static const Color accentLight = Color(0xFFFFAB40);
  static const Color accentPink = Color(0xFFFF4081);

  // Surface colors — dark palette
  static const Color surface = Color(0xFF1A1A2E); // Deep navy
  static const Color surfaceLight = Color(0xFF252542); // Card surface
  static const Color surfaceMid = Color(0xFF16213E); // Mid surface
  static const Color surfaceVariant = Color(0xFF2D2D4A); // Elevated surface

  // Neutral colors
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFFB0B0C8); // Light lavender grey
  static const Color textHint = Color(0xFF6B6B8A); // Muted
  static const Color textDark = Color(0xFF111111); // For light surfaces
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey800 = Color(0xFF424242);

  // Status colors — saturated for dark backgrounds
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD600);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF448AFF);

  // Status light variants (for badges/chips on dark bg)
  static const Color successLight = Color(0xFF1B3A2A);
  static const Color warningLight = Color(0xFF3A3520);
  static const Color errorLight = Color(0xFF3A1B1B);
  static const Color infoLight = Color(0xFF1B2A3A);

  // Status on-color (text on status badges)
  static const Color successText = Color(0xFF00E676);
  static const Color warningText = Color(0xFFFFD600);
  static const Color errorText = Color(0xFFFF5252);
  static const Color infoText = Color(0xFF448AFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5CC), Color(0xFF00B4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF4081)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF252542), Color(0xFF2D2D4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Transparency
  static const Color transparent = Color(0x00000000);
  static const Color blackOverlay = Color(0x80000000);
  static const Color whiteOverlay = Color(0x1AFFFFFF);
  static const Color glowTeal = Color(0x3300E5CC);
  static const Color glowPurple = Color(0x337C4DFF);
  static const Color glowOrange = Color(0x33FF6D00);

  // Border colors
  static const Color border = Color(0xFF3A3A5C);
  static const Color borderLight = Color(0xFF4A4A6A);
  static const Color borderFocus = Color(0xFF00E5CC);

  // Divider
  static const Color divider = Color(0xFF2A2A45);

  // Text on light surfaces (for cards with white bg)
  static const Color textLight = Color(0xFF757575);
}
