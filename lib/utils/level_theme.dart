import 'package:flutter/material.dart';
import 'education_level.dart';

class LevelTheme {
  // Junior Level Colors (Purple theme)
  static const Color juniorPrimary = Color(0xFF6C5CE7);
  static const Color juniorSecondary = Color(0xFF9B8AFF);
  static const Color juniorAccent = Color(0xFFE8E4FF);
  static const Color juniorGradientStart = Color(0xFF6C5CE7);
  static const Color juniorGradientEnd = Color(0xFF9B8AFF);
  
  // Intermediate Level Colors (Green theme)
  static const Color intermediatePrimary = Color(0xFF00B894);
  static const Color intermediateSecondary = Color(0xFF55EFC4);
  static const Color intermediateAccent = Color(0xFFE0F8F3);
  static const Color intermediateGradientStart = Color(0xFF00B894);
  static const Color intermediateGradientEnd = Color(0xFF55EFC4);
  
  // Senior Level Colors (Orange theme)
  static const Color seniorPrimary = Color(0xFFFF9F43);
  static const Color seniorSecondary = Color(0xFFFFC87C);
  static const Color seniorAccent = Color(0xFFFFF4E6);
  static const Color seniorGradientStart = Color(0xFFFF9F43);
  static const Color seniorGradientEnd = Color(0xFFFFC87C);
  
  // Get primary color based on level
  static Color getPrimaryColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'junior':
        return juniorPrimary;
      case 'intermediate':
        return intermediatePrimary;
      case 'senior':
        return seniorPrimary;
      default:
        return intermediatePrimary; // Default to intermediate
    }
  }
  
  // Get secondary color based on level
  static Color getSecondaryColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'junior':
        return juniorSecondary;
      case 'intermediate':
        return intermediateSecondary;
      case 'senior':
        return seniorSecondary;
      default:
        return intermediateSecondary;
    }
  }
  
  // Get accent color based on level
  static Color getAccentColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'junior':
        return juniorAccent;
      case 'intermediate':
        return intermediateAccent;
      case 'senior':
        return seniorAccent;
      default:
        return intermediateAccent;
    }
  }
  
  // Get gradient colors based on level
  static List<Color> getGradientColors(String? level) {
    switch (level?.toLowerCase()) {
      case 'junior':
        return [juniorGradientStart, juniorGradientEnd];
      case 'intermediate':
        return [intermediateGradientStart, intermediateGradientEnd];
      case 'senior':
        return [seniorGradientStart, seniorGradientEnd];
      default:
        return [intermediateGradientStart, intermediateGradientEnd];
    }
  }
  
  // Get background gradient based on level
  static LinearGradient getBackgroundGradient(String? level) {
    final colors = getGradientColors(level);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colors[0].withOpacity(0.1),
        Colors.white,
        colors[1].withOpacity(0.1),
      ],
    );
  }
  
  // Get card gradient based on level
  static LinearGradient getCardGradient(String? level) {
    final colors = getGradientColors(level);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
  
  // Get level emoji
  static String getLevelEmoji(String? level) {
    return EducationLevel.getLevelEmoji(level ?? EducationLevel.intermediate);
  }
  
  // Get level description
  static String getLevelDescription(String? level) {
    return EducationLevel.getLevelDescription(level ?? EducationLevel.intermediate);
  }
  
  // Get level name (capitalized)
  static String getLevelName(String? level) {
    if (level == null) return 'Intermediate';
    return level.substring(0, 1).toUpperCase() + level.substring(1).toLowerCase();
  }
}

