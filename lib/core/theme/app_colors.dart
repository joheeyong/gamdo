import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Instagram Gradient
  static const Color gradientStart = Color(0xFFFCAF45); // 노란색
  static const Color gradientMiddle = Color(0xFFE1306C); // 핑크
  static const Color gradientEnd = Color(0xFF833AB4);    // 보라

  // Primary
  static const Color primary = Color(0xFFE1306C);
  static const Color primaryLight = Color(0xFFFF6B9D);
  static const Color primaryDark = Color(0xFFC13584);

  // Accent
  static const Color accent = Color(0xFF833AB4);
  static const Color accentLight = Color(0xFFB06AE0);

  // Blue (like/action)
  static const Color actionBlue = Color(0xFF3897F0);

  // Neutrals - Light
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF262626);
  static const Color textSecondaryLight = Color(0xFF8E8E8E);
  static const Color dividerLight = Color(0xFFDBDBDB);

  // Neutrals - Dark
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFF8E8E8E);
  static const Color dividerDark = Color(0xFF363636);

  // Semantic
  static const Color success = Color(0xFF58C322);
  static const Color warning = Color(0xFFFCAF45);
  static const Color error = Color(0xFFED4956);
  static const Color info = Color(0xFF3897F0);

  // Score
  static const Color scoreExcellent = Color(0xFF58C322);
  static const Color scoreGood = Color(0xFF3897F0);
  static const Color scoreAverage = Color(0xFFFCAF45);
  static const Color scoreLow = Color(0xFFED4956);

  // Color temperature
  static const Color warmColor = Color(0xFFFCAF45);
  static const Color coolColor = Color(0xFF3897F0);
  static const Color neutralColor = Color(0xFF8E8E8E);

  // Instagram gradient
  static const LinearGradient instagramGradient = LinearGradient(
    colors: [gradientStart, gradientMiddle, gradientEnd],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const LinearGradient storyGradient = LinearGradient(
    colors: [Color(0xFFFCAF45), Color(0xFFFF6B6B), Color(0xFFC13584), Color(0xFF833AB4)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
}
