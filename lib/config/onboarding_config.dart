import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 🎯 ONBOARDING CUSTOMIZATION CONFIG
/// 
/// This file contains all the customizable content for the onboarding screens.
/// Envato buyers can easily modify this file without touching the main code.
/// 
/// Simply change the values below to customize your onboarding experience!

class OnboardingConfig {
  // ============================================================================
  // 📱 ONBOARDING PAGES CONTENT
  // ============================================================================

  /// Easy customization: Just change these values to update your onboarding!
  static const List<OnboardingPageConfig> pages = [
    // 🤖 PAGE 1: AI Features
    OnboardingPageConfig(
      title: "🤖 AI Study Buddy",
      subtitle: "Smart Learning Assistant",
      description: "Get instant help with homework, explanations, and study guidance powered by AI!",
      icon: Icons.psychology,
      gradientColors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      features: [
        "✨ Instant AI answers",
        "📚 Smart explanations",
        "🎯 Personalized help",
        "⚡ 24/7 available"
      ],
    ),

    // 📚 PAGE 2: Study Tools  
    OnboardingPageConfig(
      title: "📚 Study Tools",
      subtitle: "Learn Smarter",
      description: "Create flashcards and take quizzes automatically. Make studying fun and effective!",
      icon: Icons.auto_awesome,
      gradientColors: [Color(0xFFF093FB), Color(0xFFF5576C)],
      features: [
        "🃏 Auto flashcards",
        "🎮 Fun quizzes",
        "📈 Track progress",
        "🏆 Earn rewards"
      ],
    ),

    // 🎯 PAGE 3: Goals & Achievement
    OnboardingPageConfig(
      title: "🎯 Your Success",
      subtitle: "Achieve Goals",
      description: "Set goals, build streaks, and celebrate your learning achievements!",
      icon: Icons.rocket_launch,
      gradientColors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      features: [
        "🎯 Set study goals",
        "🔥 Build streaks",
        "🏅 Win badges",
        "📊 See growth"
      ],
    ),
  ];

  // ============================================================================
  // 🎨 UI CUSTOMIZATION
  // ============================================================================

  /// Button text customization
  static const String skipButtonText = "Skip";
  static const String nextButtonText = "Next";
  static const String previousButtonText = "Previous";
  static const String getStartedButtonText = "Get Started";

  /// Animation settings
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration animationDuration = Duration(milliseconds: 500);
  static const Curve animationCurve = Curves.easeInOut;

  /// Layout settings
  static const double iconSize = 50.0;
  static const double iconContainerSize = 100.0;
  static const double titleFontSize = 24.0;
  static const double subtitleFontSize = 16.0;
  static const double descriptionFontSize = 14.0;
  static const double featureFontSize = 13.0;
}

/// Data class for onboarding page configuration
class OnboardingPageConfig {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final List<String> features;

  const OnboardingPageConfig({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.features,
  });

  /// Convert to gradient for use in UI
  LinearGradient get gradient =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      );
}

// ============================================================================
// 🚀 READY-TO-USE ALTERNATIVE CONFIGURATIONS
// ============================================================================

/// Alternative configuration for Academic Theme
class AcademicOnboardingConfig {
  static const List<OnboardingPageConfig> pages = [
    OnboardingPageConfig(
      title: "📖 Master Any Subject",
      subtitle: "Your Academic Success Partner",
      description: "Excel in your studies with AI-powered tutoring that adapts to your learning pace and style.",
      icon: Icons.school,
      gradientColors: [Color(0xFF4C51BF), Color(0xFF667EEA)],
      features: [
        "Subject-specific tutoring",
        "Exam preparation",
        "Study schedule optimization",
        "Academic progress tracking"
      ],
    ),
    OnboardingPageConfig(
      title: "🧠 Enhance Understanding",
      subtitle: "Deep Learning Made Simple",
      description: "Break down complex concepts into digestible pieces with interactive explanations and examples.",
      icon: Icons.lightbulb,
      gradientColors: [Color(0xFFF093FB), Color(0xFFF5576C)],
      features: [
        "Concept visualization",
        "Step-by-step explanations",
        "Interactive examples",
        "Knowledge retention tools"
      ],
    ),
    OnboardingPageConfig(
      title: "🏆 Academic Excellence",
      subtitle: "Achieve Your Best Grades",
      description: "Track your academic performance and get insights to continuously improve your learning outcomes.",
      icon: Icons.emoji_events,
      gradientColors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      features: [
        "Grade tracking",
        "Performance analytics",
        "Study habit insights",
        "Achievement milestones"
      ],
    ),
  ];
}

/// Alternative configuration for Professional Theme
class ProfessionalOnboardingConfig {
  static const List<OnboardingPageConfig> pages = [
    OnboardingPageConfig(
      title: "💼 Skill Development",
      subtitle: "Advance Your Career",
      description: "Build in-demand skills with AI-guided learning paths tailored for professional growth.",
      icon: Icons.work,
      gradientColors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      features: [
        "Industry-relevant skills",
        "Career-focused learning",
        "Professional certifications",
        "Skill gap analysis"
      ],
    ),
    OnboardingPageConfig(
      title: "📊 Track Progress",
      subtitle: "Monitor Your Growth",
      description: "Get detailed insights into your learning journey with comprehensive analytics and progress reports.",
      icon: Icons.trending_up,
      gradientColors: [Color(0xFFF093FB), Color(0xFFF5576C)],
      features: [
        "Learning analytics",
        "Skill assessments",
        "Progress milestones",
        "Performance insights"
      ],
    ),
    OnboardingPageConfig(
      title: "🚀 Achieve Goals",
      subtitle: "Reach New Heights",
      description: "Set professional learning goals and get personalized recommendations to achieve them faster.",
      icon: Icons.rocket_launch,
      gradientColors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      features: [
        "Goal-oriented learning",
        "Personalized roadmaps",
        "Achievement tracking",
        "Career advancement"
      ],
    ),
  ];
}

// ============================================================================
// 📝 CUSTOMIZATION INSTRUCTIONS
// ============================================================================

/*

🎯 HOW TO CUSTOMIZE YOUR ONBOARDING:

1. **BASIC CUSTOMIZATION:**
   - Edit the values in OnboardingConfig.pages above
   - Change titles, descriptions, icons, colors, and features
   - Modify button text and animation settings

2. **USING ALTERNATIVE THEMES:**
   - Replace OnboardingConfig.pages with AcademicOnboardingConfig.pages
   - Or use ProfessionalOnboardingConfig.pages
   - Update the import in onboarding_screen.dart

3. **ADDING NEW PAGES:**
   - Add new OnboardingPageConfig entries to the pages list
   - Follow the same structure as existing pages

4. **CUSTOM COLORS:**
   - Update gradientColors with your brand colors
   - Use Color(0xFFHEXCODE) format

5. **CUSTOM ICONS:**
   - Change icon: Icons.your_icon_name
   - Or use custom icons from assets

6. **TESTING CHANGES:**
   - Delete app from device/simulator
   - Run: flutter clean && flutter run
   - First launch will show your customized onboarding

💡 PRO TIP: Keep descriptions under 100 characters for optimal mobile display!

*/