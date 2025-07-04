# AI Study Companion App

A personalized AI-powered study companion app built with Flutter that helps students learn through
interactive tutoring, flashcard generation, and progress tracking.

## Features

### 🧠 AI-Powered Tutoring

- **Chat-based Q&A**: Get instant help with questions across various subjects (math, science,
  history, etc.)
- **Intelligent Explanations**: AI breaks down complex concepts into easy-to-understand explanations
- **Contextual Learning**: AI remembers conversation context for better follow-up answers
- **Subject Specialization**: Dedicated AI tutors for different academic subjects

### 📚 Smart Flashcard System

- **AI-Generated Flashcards**: Automatically create flashcards from topics or notes
- **Spaced Repetition**: Intelligent scheduling based on your learning progress
- **Custom Flashcards**: Create your own flashcards with rich text support
- **Performance Tracking**: Monitor which cards you struggle with most

### 📈 Progress Tracking & Analytics

- **Study Statistics**: Track time spent studying each subject
- **Daily Goals**: Set and achieve daily study targets
- **Weekly/Monthly Reports**: Detailed analytics of your learning progress
- **Achievement System**: Unlock badges and milestones as you learn

### 🔔 Smart Notifications

- **Study Reminders**: Customizable push notifications for study sessions
- **Review Alerts**: Get reminded when it's time to review flashcards
- **Goal Notifications**: Celebrate when you achieve daily/weekly goals

### 👩‍🎓 User Management

- **Firebase Authentication**: Secure user registration and login
- **Profile Customization**: Personalize your learning experience
- **Cross-Device Sync**: Access your data from any device
- **Privacy Controls**: Manage your data and privacy settings

### 💰 Monetization Model

- **Freemium Model**: Basic features free with premium upgrades
- **Question Limits**: Free users get 10 questions per day, premium unlimited
- **Premium Features**: Advanced analytics, unlimited AI generations, priority support
- **In-App Purchases**: Buy additional question packs or unlock premium features

## Technology Stack

### Frontend

- **Flutter**: Cross-platform mobile development
- **Provider**: State management
- **Material Design 3**: Modern UI components
- **Flutter Animate**: Smooth animations and transitions

### Backend Services

- **Firebase Auth**: User authentication
- **Cloud Firestore**: Real-time database
- **Firebase Messaging**: Push notifications
- **Firebase Storage**: File storage (future enhancement)

### AI Integration

- **OpenAI GPT-3.5/4**: Conversational AI for tutoring
- **OpenAI Whisper**: Voice input processing (planned feature)
- **Custom Prompts**: Specialized AI prompts for educational content

### Additional Libraries

- **Hive**: Local data storage and caching
- **Dio**: HTTP client for API requests
- **SharedPreferences**: User preferences storage
- **Speech-to-Text**: Voice input capabilities

## Setup Instructions

### Prerequisites

- Flutter SDK (>=3.8.1)
- Dart SDK
- Android Studio / Xcode
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ai_study_buddy
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
    - Create a new Firebase project
    - Enable Authentication, Firestore, and Messaging
    - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
    - Place files in respective platform folders

4. **OpenAI API Setup**
    - Get an OpenAI API key from https://platform.openai.com/
    - Replace `YOUR_OPENAI_API_KEY_HERE` in `lib/services/ai_service.dart`

5. **Run the app**
   ```bash
   flutter run
   ```

### Configuration

#### API Keys

Update the following files with your API keys:

- `lib/services/ai_service.dart`: OpenAI API key
- Firebase configuration files for your project

#### App Settings

- Modify daily question limits in `lib/models/user_model.dart`
- Customize notification schedules in `lib/services/notification_service.dart`
- Adjust AI prompts in `lib/services/ai_service.dart`

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── flashcard_model.dart
│   └── chat_message_model.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── chat_provider.dart
│   ├── flashcard_provider.dart
│   └── study_provider.dart
├── screens/                  # UI screens
│   ├── auth/
│   ├── home/
│   ├── chat/
│   ├── flashcards/
│   └── profile/
├── services/                 # External services
│   ├── ai_service.dart
│   └── notification_service.dart
├── utils/                    # Utilities
│   └── app_theme.dart
└── widgets/                  # Reusable components
```

## Key Features Implementation

### AI Chat System

The app integrates with OpenAI's GPT models to provide intelligent tutoring responses. The AI is
trained with specific prompts to act as an educational tutor, providing explanations that are:

- Age-appropriate and educational
- Broken down into simple steps
- Encouraging and supportive
- Subject-specific when needed

### Flashcard Intelligence

AI-generated flashcards use educational best practices:

- Question-answer format optimization
- Difficulty level adjustment
- Spaced repetition algorithms
- Performance-based card scheduling

### Progress Analytics

Comprehensive tracking includes:

- Time spent per subject
- Daily/weekly study streaks
- Question accuracy rates
- Learning velocity metrics

## Upcoming Features

### Voice Integration

- **Speech-to-Text**: Ask questions using voice input
- **Text-to-Speech**: Listen to AI responses
- **Voice Commands**: Navigate the app hands-free

### Advanced AI Features

- **Personalized Learning Paths**: AI suggests optimal study sequences
- **Weakness Detection**: Identify knowledge gaps automatically
- **Study Plan Generation**: Create custom study schedules
- **Multi-Modal Learning**: Support for images, diagrams, and videos

### Social Features

- **Study Groups**: Collaborate with other students
- **Leaderboards**: Friendly competition with peers
- **Shared Flashcards**: Community-generated content
- **Peer Tutoring**: Connect with other students for help

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, email support@aistudycompanion.com or create an issue in this repository.

## Acknowledgments

- OpenAI for providing the GPT API
- Firebase team for backend infrastructure
- Flutter team for the amazing framework
- Material Design team for UI guidelines
