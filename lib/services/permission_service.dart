import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();

  factory PermissionService() => _instance;

  PermissionService._internal();

  // Request essential permissions at app startup
  Future<PermissionRequestResult> requestEssentialPermissions() async {
    try {
      if (kDebugMode) {
        print('PermissionService: Requesting essential permissions...');
      }

      // Request microphone permission for voice features
      final micPermission = await Permission.microphone.request();

      if (kDebugMode) {
        print('PermissionService: Microphone permission - ${micPermission
            .toString()}');
      }

      // Check final status
      final micStatus = await Permission.microphone.status;

      return PermissionRequestResult(
        microphoneGranted: micStatus.isGranted,
        microphoneDenied: micStatus.isDenied,
        microphonePermanentlyDenied: micStatus.isPermanentlyDenied,
        allGranted: micStatus.isGranted,
      );
    } catch (e) {
      if (kDebugMode) {
        print('PermissionService: Error requesting permissions - $e');
      }
      return PermissionRequestResult(
        microphoneGranted: false,
        microphoneDenied: true,
        microphonePermanentlyDenied: false,
        allGranted: false,
        error: e.toString(),
      );
    }
  }

  // Check current permission status
  Future<Map<String, bool>> checkPermissionStatus() async {
    try {
      final micStatus = await Permission.microphone.status;

      return {
        'microphone': micStatus.isGranted,
      };
    } catch (e) {
      if (kDebugMode) {
        print('PermissionService: Error checking permissions - $e');
      }
      return {
        'microphone': false,
      };
    }
  }

  // Check if microphone permission is granted
  Future<bool> isMicrophonePermissionGranted() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('PermissionService: Error checking microphone permission - $e');
      }
      return false;
    }
  }

  // Request only microphone permission (for later use)
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('PermissionService: Error requesting microphone permission - $e');
      }
      return false;
    }
  }

  // Open app settings for permanent denials
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      if (kDebugMode) {
        print('PermissionService: Error opening app settings - $e');
      }
    }
  }

  // Get user-friendly permission explanation
  String getPermissionExplanation(String permission) {
    switch (permission) {
      case 'microphone':
        return 'Voice Learning features require microphone access to recognize your speech and provide interactive voice-based learning experiences.';
      default:
        return 'This permission is required for the app to function properly.';
    }
  }
}

class PermissionRequestResult {
  final bool microphoneGranted;
  final bool microphoneDenied;
  final bool microphonePermanentlyDenied;
  final bool allGranted;
  final String? error;

  PermissionRequestResult({
    required this.microphoneGranted,
    required this.microphoneDenied,
    required this.microphonePermanentlyDenied,
    required this.allGranted,
    this.error,
  });

  bool get hasPermissionIssues => !allGranted;

  bool get hasPermanentDenials => microphonePermanentlyDenied;

  List<String> get deniedPermissions {
    final denied = <String>[];
    if (microphoneDenied || microphonePermanentlyDenied) {
      denied.add('Microphone');
    }
    return denied;
  }

  String get statusMessage {
    if (error != null) {
      return 'Error requesting permissions: $error';
    }
    if (allGranted) {
      return 'All permissions granted successfully!';
    }
    if (hasPermanentDenials) {
      return 'Some permissions were permanently denied. Please enable them in Settings.';
    }
    if (hasPermissionIssues) {
      return 'Some permissions were denied. Voice features may not work properly.';
    }
    return 'Permissions requested successfully!';
  }
}