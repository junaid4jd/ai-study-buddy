# AI Study Companion - Setup Guide

Follow these steps to set up the AI Study Companion app on your local machine.

## Prerequisites

1. **Flutter SDK** (>=3.8.1) - [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Dart SDK** (comes with Flutter)
3. **Android Studio** or **Xcode** for running on simulators/devices
4. **Firebase account** - [Create a Firebase project](https://firebase.google.com/)
5. **OpenAI account** - [Get an API key](https://platform.openai.com/api-keys)

## Installation Steps

### 1. Clone and Install Dependencies

```bash
# Clone the repository (if not already done)
git clone <your-repository-url>
cd ai_study_buddy

# Install Flutter dependencies
flutter pub get
```

### 2. Firebase Setup

#### 2.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `ai-study-companion` (or your preferred name)
4. Enable Google Analytics (optional)

#### 2.2 Enable Firebase Services

In your Firebase project dashboard:

1. **Authentication**:
    - Go to Authentication > Sign-in method
    - Enable "Email/Password" provider

2. **Firestore Database**:
    - Go to Firestore Database
    - Click "Create database"
    - Start in "Test mode" (you can secure it later)
    - Choose your preferred location

3. **Cloud Messaging** (for notifications):
    - Go to Cloud Messaging
    - No additional setup needed

#### 2.3 Add Firebase to Your Flutter App

1. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Install FlutterFire CLI**:
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. **Login to Firebase**:
   ```bash
   firebase login
   ```

4. **Configure Firebase for Flutter**:
   ```bash
   flutterfire configure
   ```
    - Select your Firebase project
    - Choose platforms (iOS, Android, etc.)
    - This will generate `firebase_options.dart` and update platform-specific files

#### 2.4 Platform-Specific Setup

**For Android:**

- `firebase_options.dart` is automatically updated
- `android/app/google-services.json` is automatically added

**For iOS:**

- `firebase_options.dart` is automatically updated
- `ios/Runner/GoogleService-Info.plist` is automatically added

### 3. OpenAI API Setup

1. Get your OpenAI API key from [OpenAI Platform](https://platform.openai.com/api-keys)

2. Update the API key in `lib/services/ai_service.dart`:
   ```dart
   static const String _apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

   **⚠️ Security Note**: For production apps, store API keys in environment variables or secure
   storage, not in source code.

### 4. Configure App Settings (Optional)

#### Customize User Limits

In `lib/models/user_model.dart`, you can modify:

```dart
this.maxQuestions = 10,  // Free user question limit
```

#### Adjust Notification Settings

In `lib/services/notification_service.dart`, customize notification topics and schedules.

#### Modify AI Prompts

In `lib/services/ai_service.dart`, you can adjust the AI system prompts for different educational
styles.

## Running the App

### 1. Check Flutter Installation

```bash
flutter doctor
```

Fix any issues reported.

### 2. Run on Simulator/Device

**For iOS Simulator:**

```bash
flutter run -d "iPhone 15 Pro"
```

**For Android Emulator:**

```bash
flutter run -d android
```

**For Physical Device:**

```bash
# Make sure device is connected and USB debugging is enabled
flutter run
```

### 3. Test the App

1. **Registration**: Create a new account
2. **Login**: Sign in with your credentials
3. **AI Chat**: Ask a test question to verify OpenAI integration
4. **Flashcards**: Try creating a flashcard
5. **Notifications**: Test notification permissions

## Troubleshooting

### Common Issues

1. **Firebase Connection Issues**:
   ```bash
   # Reconfigure Firebase
   flutterfire configure
   ```

2. **OpenAI API Errors**:
    - Verify your API key is correct
    - Check your OpenAI account has credits
    - Ensure the API key has the correct permissions

3. **Build Errors**:
   ```bash
   # Clean and rebuild
   flutter clean
   flutter pub get
   flutter run
   ```

4. **iOS Build Issues**:
   ```bash
   cd ios
   pod install
   cd ..
   flutter run
   ```

### Debug Mode vs Release Mode

**Debug Mode** (default):

- Includes debugging symbols
- Hot reload available
- Performance may be slower

**Release Mode**:

```bash
flutter run --release
```

## Production Deployment

### Android

```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Security Considerations for Production

1. **API Key Security**:
    - Use environment variables
    - Implement backend API proxy
    - Set up API key restrictions

2. **Firebase Security Rules**:
   ```javascript
   // Firestore security rules example
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users can only access their own data
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       
       // Chat messages can only be accessed by the owner
       match /chat_messages/{messageId} {
         allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
       }
       
       // Flashcards can only be accessed by the owner
       match /flashcards/{flashcardId} {
         allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
       }
     }
   }
   ```

3. **Enable Authentication Rules**:
    - In Firebase Console > Authentication > Settings
    - Configure authorized domains
    - Set up password policies

## Support

If you encounter issues:

1. Check the [Flutter Documentation](https://docs.flutter.dev/)
2. Review [Firebase Documentation](https://firebase.google.com/docs)
3. Check [OpenAI API Documentation](https://platform.openai.com/docs)
4. Create an issue in this repository

## Next Steps

Once your app is running:

1. **Customize the UI** to match your brand
2. **Add more subjects** and AI prompts
3. **Implement advanced features** like voice input
4. **Set up analytics** to track user engagement
5. **Add monetization** features (subscriptions, premium features)

Happy coding! 🚀