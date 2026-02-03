import 'package:flutter/material.dart';

/// App color palette inspired by warm, earthy tones
class AppColors {
  AppColors._();

  // Primary accent - warm amber/gold gradient
  static const Color primaryLight = Color(0xFFE8A54B);
  static const Color primary = Color(0xFFD4923A);
  static const Color primaryDark = Color(0xFFB8792E);

  // Background colors - Light theme
  static const Color backgroundLight = Color(0xFFFAF7F2);
  static const Color surfaceLight = Color(0xFFF5EDE3);
  static const Color cardLight = Color(0xFFF8F1E8);

  // Background colors - Dark theme
  static const Color backgroundDark = Color(0xFF1A1814);
  static const Color surfaceDark = Color(0xFF252119);
  static const Color cardDark = Color(0xFF2E2820);

  // Text colors - Light theme
  static const Color textPrimaryLight = Color(0xFF1A1814);
  static const Color textSecondaryLight = Color(0xFF6B635A);
  static const Color textTertiaryLight = Color(0xFF9A9189);

  // Text colors - Dark theme
  static const Color textPrimaryDark = Color(0xFFFAF7F2);
  static const Color textSecondaryDark = Color(0xFFB8AFA5);
  static const Color textTertiaryDark = Color(0xFF7A7268);

  // Semantic colors
  static const Color like = Color(0xFFE85D5D);
  static const Color likeLight = Color(0xFFFFE8E8);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);

  // Navigation bar - Dark glassmorphism effect
  static const Color navBarDark = Color(0xFF2A2520);
  static const Color navBarLight = Color(0xFF3D352D);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE8A54B), Color(0xFFD4923A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navBarGradient = LinearGradient(
    colors: [Color(0xFF3D352D), Color(0xFF2A2520), Color(0xFF1F1B17)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradientLight = LinearGradient(
    colors: [Color(0xFFFDF9F4), Color(0xFFF5EDE3)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF353028), Color(0xFF2A2520)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Button gradient
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFFEBB05A), Color(0xFFD4923A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
