import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors - Easy to customize for reskinning
  static const Color primary = Color(0xFF6B73FF);
  static const Color primaryLight = Color(0xFF9FA8FF);
  static const Color primaryDark = Color(0xFF4E5BFF);

  // Secondary Colors
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color secondaryLight = Color(0xFFFF9FC7);
  static const Color secondaryDark = Color(0xFFE53E7A);

  // Accent Colors
  static const Color accent = Color(0xFF00D4AA);
  static const Color accentLight = Color(0xFF4DFFDD);
  static const Color accentDark = Color(0xFF00B395);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2D2D2D);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textDark = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8F9FA), Color(0xFFE5E7EB)],
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
  );

  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x3A000000);

  // Premium Colors
  static const Color premium = Color(0xFFFFD700);
  static const Color premiumLight = Color(0xFFFFE55C);
  static const Color premiumDark = Color(0xFFB8860B);

  // Chat Colors
  static const Color userMessage = Color(0xFF6B73FF);
  static const Color aiMessage = Color(0xFFF3F4F6);
  static const Color aiMessageDark = Color(0xFF374151);

  // Flashcard Colors
  static const List<Color> flashcardColors = [
    Color(0xFFFF6B9D),
    Color(0xFF6B73FF),
    Color(0xFF00D4AA),
    Color(0xFFFFB800),
    Color(0xFFFF5722),
    Color(0xFF9C27B0),
  ];
}