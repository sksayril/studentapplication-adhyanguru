import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color secondary = Color(0xFFFF9F43);
  static const Color accent = Color(0xFFA29BFE);
  
  // Light mode colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textLight = Color(0xFFB2BEC3);
  
  // Dark mode colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  
  // Class card colors
  static const Color mathClassBg = Color(0xFFD1C4E9);
  static const Color biologyCardBg = Color(0xFFFFF4E6);
  static const Color biologyCardBg2 = Color(0xFFE3F2FD);
  static const Color testExamBg = Color(0xFFE8F5E9);
  
  // Free course colors
  static const Color freeCourseYellow = Color(0xFFFFF4C4);
  static const Color freeCourseOrange = Color(0xFFFFE4C4);
  static const Color freeCourseGreen = Color(0xFFE8F5E9);
  
  // Status colors
  static const Color liveIndicator = Color(0xFFFF3B30);
  static const Color successGreen = Color(0xFF00B894);
  
  // Bottom navigation
  static const Color navBarBg = Color(0xFF1A1A2E);
  static const Color navBarSelected = Color(0xFFFFFFFF);
  static const Color navBarUnselected = Color(0xFF6B7280);
  
  // Dynamic colors based on theme
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : background;
  }
  
  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardBackground
        : cardBackground;
  }
  
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : textPrimary;
  }
  
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : textSecondary;
  }
}

