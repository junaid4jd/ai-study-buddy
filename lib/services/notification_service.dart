import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging
      .instance;

  static Future<void> initialize() async {
    try {
      // iOS-specific timeout handling
      final timeout = Platform.isIOS
          ? const Duration(seconds: 8)
          : const Duration(seconds: 5);

      // Add timeout to prevent hanging
      await Future.any([
        _initializeWithTimeout(),
        Future.delayed(timeout), // Timeout for iOS
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('Notification service initialization failed: $e');
      }
      // Don't rethrow - let app continue without notifications
    }
  }

  static Future<void> _initializeWithTimeout() async {
    try {
      // iOS-specific pre-initialization
      if (Platform.isIOS) {
        // Check if Firebase Messaging is available
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Request permission for notifications with iOS-specific settings
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: Platform.isIOS, // iOS supports provisional notifications
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('User granted permission for notifications');
        }

        // iOS-specific setup
        if (Platform.isIOS) {
          await _setupIOSNotifications();
        }
      } else {
        if (kDebugMode) {
          print(
              'User declined or has not accepted permission for notifications');
        }
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
        }

        if (message.notification != null) {
          if (kDebugMode) {
            print(
                'Message also contained a notification: ${message
                    .notification}');
          }
        }
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    } catch (e) {
      if (kDebugMode) {
        print('Error in notification initialization: $e');
      }
      rethrow;
    }
  }

  static Future<void> _setupIOSNotifications() async {
    try {
      // iOS-specific APNS setup
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get APNS token for iOS
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken != null && kDebugMode) {
        print('APNS Token received: ${apnsToken.substring(0, 10)}...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up iOS notifications: $e');
      }
    }
  }

  static Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken().timeout(
        Platform.isIOS
            ? const Duration(seconds: 10)
            : const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) print('FCM token request timed out');
          return null;
        },
      );
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) print('Subscribe to topic $topic timed out');
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic $topic: $e');
      }
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) print('Unsubscribe from topic $topic timed out');
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic $topic: $e');
      }
    }
  }

  static void scheduleStudyReminder() {
    // This would integrate with local notifications
    // For now, we'll just subscribe to study reminders topic
    subscribeToTopic('study_reminders');
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
  }
}