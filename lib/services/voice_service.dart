import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'ai_service.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();

  factory VoiceService() => _instance;

  VoiceService._internal();

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AIService _aiService = AIService();

  bool _isListening = false;
  bool _isAvailable = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  String _lastRecognizedText = '';
  double _confidence = 0.0;
  String? _initializationError;

  // Getters
  bool get isListening => _isListening;

  bool get isAvailable => _isAvailable;

  bool get isSpeaking => _isSpeaking;

  bool get isInitialized => _isInitialized;

  String get lastRecognizedText => _lastRecognizedText;

  double get confidence => _confidence;

  String? get initializationError => _initializationError;

  // Initialize voice services with comprehensive error handling
  Future<bool> initialize() async {
    if (_isInitialized) {
      return _isAvailable;
    }

    try {
      _initializationError = null;

      if (kDebugMode) {
        print('Starting voice service initialization...');
      }

      // Check if running on supported platform
      if (!_isPlatformSupported()) {
        _initializationError = 'Voice features not supported on this platform';
        if (kDebugMode) {
          print(_initializationError);
        }
        return false;
      }

      // Initialize Text-to-Speech first (usually more reliable)
      final ttsInitialized = await _initializeTts();
      if (!ttsInitialized) {
        _initializationError = 'Text-to-Speech initialization failed';
        if (kDebugMode) {
          print(_initializationError);
        }
        // Continue with STT even if TTS fails
      }

      // Request and check microphone permission
      final permissionGranted = await _requestMicrophonePermission();
      if (!permissionGranted) {
        _initializationError =
        'Microphone permission denied. Please enable microphone access in device settings.';
        if (kDebugMode) {
          print(_initializationError);
        }
        return false;
      }

      // Initialize Speech-to-Text
      final sttInitialized = await _initializeSpeechToText();
      if (!sttInitialized) {
        _initializationError =
        'Speech recognition not available on this device';
        if (kDebugMode) {
          print(_initializationError);
        }
        return false;
      }

      _isInitialized = true;
      _isAvailable = true;

      if (kDebugMode) {
        print('Voice service initialized successfully');
      }

      return true;
    } catch (e) {
      _initializationError = 'Voice service initialization failed: $e';
      if (kDebugMode) {
        print('Voice service initialization failed: $e');
      }
      return false;
    }
  }

  bool _isPlatformSupported() {
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
    } catch (e) {
      // Fallback for web or other platforms
      return !kIsWeb;
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.microphone.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        if (kDebugMode) {
          print('Microphone permission permanently denied');
        }
        return false;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Permission request error: $e');
      }
      return false;
    }
  }

  Future<bool> _initializeSpeechToText() async {
    try {
      final available = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: kDebugMode,
      );

      if (available) {
        final locales = await _speechToText.locales();
        if (kDebugMode) {
          print('Speech recognition available with ${locales.length} locales');
        }
      }

      return available;
    } catch (e) {
      if (kDebugMode) {
        print('Speech-to-text initialization error: $e');
      }
      return false;
    }
  }

  Future<bool> _initializeTts() async {
    try {
      // Set default language
      await _flutterTts.setLanguage('en-US');

      // Set default speech settings
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setPitch(1.0);

      // Set up event handlers
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        if (kDebugMode) {
          print('TTS started');
        }
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        if (kDebugMode) {
          print('TTS completed');
        }
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        if (kDebugMode) {
          print('TTS error: $msg');
        }
      });

      // Test TTS availability
      final voices = await _flutterTts.getVoices;
      if (kDebugMode) {
        print('TTS initialized with ${voices?.length ?? 0} voices');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('TTS initialization error: $e');
      }
      return false;
    }
  }

  // Speech-to-Text functionality with improved error handling
  Future<void> startListening({
    String localeId = 'en_US',
    Function(String)? onResult,
    Function(String)? onError,
  }) async {
    if (!_isAvailable || !_isInitialized) {
      onError?.call(_initializationError ?? 'Speech recognition not available');
      return;
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      final permissionGranted = await _requestMicrophonePermission();
      if (!permissionGranted) {
        onError?.call('Microphone permission required');
        return;
      }

      await _speechToText.listen(
        onResult: (result) {
          _lastRecognizedText = result.recognizedWords;
          _confidence = result.confidence;
          onResult?.call(_lastRecognizedText);

          if (kDebugMode) {
            print(
                'Recognized: $_lastRecognizedText (confidence: $_confidence)');
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: localeId,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
      );
      _isListening = true;
    } catch (e) {
      onError?.call('Failed to start listening: $e');
      if (kDebugMode) {
        print('Start listening error: $e');
      }
    }
  }

  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speechToText.stop();
        _isListening = false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Stop listening error: $e');
      }
    }
  }

  void _onSpeechStatus(String status) {
    _isListening = status == 'listening';
    if (kDebugMode) {
      print('Speech status: $status');
    }
  }

  void _onSpeechError(dynamic errorNotification) {
    _isListening = false;
    if (kDebugMode) {
      print('Speech error: $errorNotification');
    }
  }

  // Text-to-Speech functionality with improved error handling
  Future<void> speak(String text) async {
    if (text
        .trim()
        .isEmpty) return;

    try {
      if (_isSpeaking) {
        await stopSpeaking();
      }

      await _flutterTts.speak(text);
    } catch (e) {
      if (kDebugMode) {
        print('TTS speak error: $e');
      }
      // Try alternative text-to-speech approach
      try {
        if (Platform.isAndroid) {
          await _flutterTts.awaitSpeakCompletion(true);
          await _flutterTts.speak(text);
        }
      } catch (e2) {
        if (kDebugMode) {
          print('Alternative TTS failed: $e2');
        }
      }
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      if (kDebugMode) {
        print('TTS stop error: $e');
      }
    }
  }

  // Voice-based AI interaction
  Future<String> askAIWithVoice({
    required String question,
    String subject = 'General',
    bool speakResponse = true,
  }) async {
    try {
      final response = await _aiService.generateTutorResponse(
          question, subject);

      if (speakResponse && response.isNotEmpty) {
        await speak(response);
      }

      return response;
    } catch (e) {
      final errorMsg = 'Sorry, I encountered an error: ${e
          .toString()
          .replaceAll('Exception: ', '')}';
      if (speakResponse) {
        await speak(errorMsg);
      }
      return errorMsg;
    }
  }

  // Voice flashcard reading
  Future<void> readFlashcard({
    required String question,
    required String answer,
    bool readQuestion = true,
    bool readAnswer = true,
  }) async {
    try {
      if (readQuestion) {
        await speak('Question: $question');
        await Future.delayed(const Duration(seconds: 1));
      }

      if (readAnswer) {
        await speak('Answer: $answer');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Flashcard reading error: $e');
      }
    }
  }

  // Voice-based note taking
  Future<String> takeVoiceNote({
    Duration maxDuration = const Duration(minutes: 2),
    Function(String)? onPartialResult,
    Function(String)? onError,
  }) async {
    String fullNote = '';

    try {
      await startListening(
        onResult: (text) {
          fullNote = text;
          onPartialResult?.call(text);
        },
        onError: onError,
      );

      // Wait for the specified duration or until manually stopped
      await Future.delayed(maxDuration);

      if (_isListening) {
        await stopListening();
      }

      return fullNote;
    } catch (e) {
      onError?.call('Voice note failed: $e');
      return '';
    }
  }

  // Pronunciation practice
  Future<double> practicePronunciation({
    required String targetText,
    Duration listenDuration = const Duration(seconds: 10),
  }) async {
    try {
      // First, speak the target text
      await speak('Please repeat: $targetText');
      await Future.delayed(const Duration(seconds: 2));

      String spokenText = '';

      // Listen for user's pronunciation
      await startListening(
        onResult: (text) {
          spokenText = text;
        },
      );

      await Future.delayed(listenDuration);
      await stopListening();

      // Calculate similarity (simple word matching)
      final similarity = _calculateSimilarity(
          targetText.toLowerCase(), spokenText.toLowerCase());

      // Provide feedback
      String feedback;
      if (similarity > 0.8) {
        feedback = 'Excellent pronunciation!';
      } else if (similarity > 0.6) {
        feedback = 'Good job! Try to be more clear.';
      } else {
        feedback = 'Keep practicing. You said: $spokenText';
      }

      await speak(feedback);
      return similarity;
    } catch (e) {
      await speak('Pronunciation practice failed. Please try again.');
      return 0.0;
    }
  }

  double _calculateSimilarity(String text1, String text2) {
    final words1 = text1.split(' ');
    final words2 = text2.split(' ');

    int matches = 0;
    int totalWords = words1.length;

    for (String word1 in words1) {
      for (String word2 in words2) {
        if (word1 == word2) {
          matches++;
          break;
        }
      }
    }

    return totalWords > 0 ? matches / totalWords : 0.0;
  }

  // Get available voices
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return List<Map<String, String>>.from(voices ?? []);
    } catch (e) {
      if (kDebugMode) {
        print('Get voices error: $e');
      }
      return [];
    }
  }

  // Set voice
  Future<void> setVoice(Map<String, String> voice) async {
    try {
      await _flutterTts.setVoice(voice);
    } catch (e) {
      if (kDebugMode) {
        print('Set voice error: $e');
      }
    }
  }

  // Adjust speech settings
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.1, 1.0));
    } catch (e) {
      if (kDebugMode) {
        print('Set speech rate error: $e');
      }
    }
  }

  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (e) {
      if (kDebugMode) {
        print('Set pitch error: $e');
      }
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      if (kDebugMode) {
        print('Set volume error: $e');
      }
    }
  }

  // Force reinitialize (useful for troubleshooting)
  Future<bool> reinitialize() async {
    _isInitialized = false;
    _isAvailable = false;
    return await initialize();
  }

  // Get detailed status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isAvailable': _isAvailable,
      'isListening': _isListening,
      'isSpeaking': _isSpeaking,
      'initializationError': _initializationError,
      'platform': Platform.operatingSystem,
      'platformSupported': _isPlatformSupported(),
    };
  }

  // Cleanup
  Future<void> dispose() async {
    await stopListening();
    await stopSpeaking();
    _isInitialized = false;
    _isAvailable = false;
  }
}