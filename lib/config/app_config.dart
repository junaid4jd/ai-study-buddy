class AppConfig {
  // App Identity - Easy to customize for reskinning
  static const String appName = 'AI Study Buddy';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-powered study companion with chat tutoring and flashcards';

  // Company/Developer Info
  static const String developerName = 'Your Company';
  static const String developerEmail = 'support@yourcompany.com';
  static const String privacyPolicyUrl = 'https://yourcompany.com/privacy';
  static const String termsOfServiceUrl = 'https://yourcompany.com/terms';

  // App Store Info
  static const String appStoreId = 'your_app_store_id';
  static const String playStoreId = 'your_play_store_id';

  // Firebase Configuration
  static const bool useFirebase = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;

  // Features Toggle - Easy to enable/disable features
  static const bool enablePremium = true;
  static const bool enableNotifications = true;
  static const bool enableAchievements = true;
  static const bool enableVoiceFeatures = true;

  // Premium Features
  static const String premiumProductId = 'premium_upgrade';
  static const List<String> premiumFeatures = [
    'Unlimited AI conversations',
    'Advanced flashcard features',
    'Priority support',
    'No ads',
    'Offline mode',
  ];

  // Limits for Free Users
  static const int freeMessageLimit = 10;
  static const int freeFlashcardLimit = 50;

  // UI Configuration
  static const bool enableDarkMode = true;
  static const bool enableAnimations = true;
  static const Duration animationDuration = Duration(milliseconds: 300);

  // API Configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
}