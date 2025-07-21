# 🎯 Onboarding Customization Guide for AI Study Buddy

Welcome to the AI Study Buddy! This guide will help you customize the onboarding experience to match
your brand and messaging.

## 📍 Quick Start

The onboarding screens are located in: `lib/screens/onboarding/onboarding_screen.dart`

## 🎨 Easy Customization Options

### 1. **Customize Onboarding Content**

Find the `_pages` list in `_OnboardingScreenState` class (around line 24):

```dart
final List<OnboardingPageData> _pages = [
  OnboardingPageData(
    title: "🤖 AI-Powered Learning",           // Main title
    subtitle: "Your Personal Study Assistant", // Subtitle  
    description: "Get instant answers...",      // Description text
    icon: Icons.psychology,                     // Main icon
    gradient: AppColors.primaryGradient,       // Background gradient
    features: [                                 // Feature list
      "Smart AI chat tutor",
      "Subject-specific assistance", 
      "24/7 availability",
      "Personalized explanations"
    ],
  ),
  // Add more pages here...
];
```

### 2. **Change Colors & Gradients**

Update gradients in `lib/config/app_colors.dart`:

```dart
static const LinearGradient primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [YOUR_COLOR_1, YOUR_COLOR_2], // Change these colors
);
```

### 3. **Modify Icons**

Replace `Icons.psychology`, `Icons.quiz`, `Icons.emoji_events` with your preferred icons:

```dart
icon: Icons.school,        // Education theme
icon: Icons.lightbulb,     // Innovation theme  
icon: Icons.rocket,        // Growth theme
// Or use custom icons from assets
```

### 4. **Add/Remove Onboarding Pages**

To add a new page, add to the `_pages` list:

```dart
OnboardingPageData(
  title: "📊 Track Progress",
  subtitle: "Monitor Your Growth",
  description: "See detailed analytics of your learning journey...",
  icon: Icons.analytics,
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.purple, Colors.purpleAccent],
  ),
  features: [
    "Detailed analytics",
    "Performance insights",
    "Goal tracking",
    "Study streaks"
  ],
),
```

### 5. **Customize Button Text**

Change button labels by modifying these lines:

```dart
// Skip button (line ~169)
child: const Text('Skip'),

// Next button (line ~279)
Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),

// Previous button (line ~245)  
child: const Text('Previous'),
```

### 6. **Modify App Name Display**

Update the app name shown in onboarding (line ~151):

```dart
Text(
  AppStrings.appName,  // Or replace with "Your App Name"
  style: const TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),
```

## 🎯 Advanced Customization

### Custom Images Instead of Icons

Replace the icon with custom images:

```dart
// Instead of Icon widget, use:
Container(
  width: 120,
  height: 120,
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.2),
    shape: BoxShape.circle,
  ),
  child: Image.asset(
    'assets/images/onboarding/page1.png',
    width: 60,
    height: 60,
  ),
),
```

### Add Animations

The onboarding already includes smooth slide and fade animations. To customize:

```dart
// Modify animation durations (line ~70)
_animationController = AnimationController(
  duration: const Duration(milliseconds: 800), // Change duration
  vsync: this,
);

// Change animation curves (line ~76)
curve: Curves.bounceInOut, // Different curve
```

### Custom Fonts

If using custom fonts, update the text styles:

```dart
style: const TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: Colors.white,
  fontFamily: 'YourCustomFont', // Add this line
),
```

## 🛠️ Technical Details

### Onboarding Flow

1. **Splash Screen** checks if onboarding is completed
2. First-time users see **Onboarding Screen**
3. After completion, users go to **Login Screen**
4. Returning users skip onboarding

### SharedPreferences Key

The app uses `'onboarding_completed'` key to track completion status.

### File Structure

```
lib/screens/onboarding/
├── onboarding_screen.dart     # Main onboarding implementation
```

## 🎨 Design Best Practices

1. **Keep text concise** - Mobile users scan quickly
2. **Use consistent colors** - Match your app's color scheme
3. **Highlight key benefits** - Focus on user value
4. **Test on different screen sizes** - Ensure responsiveness
5. **Use engaging visuals** - Icons or illustrations work well

## 📱 Preview Changes

After making changes:

1. Delete the app from simulator/device
2. Run `flutter clean`
3. Run `flutter run`
4. First launch will show your customized onboarding

## 🚀 Pro Tips

- **A/B Test**: Try different messaging to see what resonates
- **Keep it short**: 3 pages is optimal for mobile onboarding
- **Focus on benefits**: Tell users what's in it for them
- **Use action words**: "Learn", "Achieve", "Master", "Excel"
- **Brand consistency**: Match colors, fonts, and tone to your main app

## 🎯 Ready-to-Use Alternatives

### Academic Theme

```dart
OnboardingPageData(
  title: "📖 Master Any Subject",
  subtitle: "Your Academic Success Partner", 
  description: "Excel in your studies with AI-powered assistance...",
  // ... rest of configuration
)
```

### Professional Theme

```dart
OnboardingPageData(
  title: "💼 Skill Development",
  subtitle: "Advance Your Career",
  description: "Build in-demand skills with personalized learning...",
  // ... rest of configuration  
)
```

### Creative Theme

```dart
OnboardingPageData(
  title: "🎨 Unlock Creativity", 
  subtitle: "Learn Through Innovation",
  description: "Explore new ideas and creative approaches...",
  // ... rest of configuration
)
```

---

**Need more help?** The code is well-commented and follows Flutter best practices. Each section is
clearly marked for easy modification!

**Happy customizing! 🎉**