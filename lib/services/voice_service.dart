import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
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
  String _lastRecognizedText = '';
  double _confidence = 0.0;

  // Getters
  bool get isListening => _isListening;

  bool get isAvailable => _isAvailable;

  bool get isSpeaking => _isSpeaking;

  String get lastRecognizedText => _lastRecognizedText;

  double get confidence => _confidence;

  // Initialize voice services
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        if (kDebugMode) {
          print('Microphone permission denied');
        }
        return false;
      }

      // Initialize Speech-to-Text
      _isAvailable = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (!_isAvailable) {
        if (kDebugMode) {
          print('Speech recognition not available');
        }
        return false;
      }

      // Initialize Text-to-Speech
      await _initializeTts();

      if (kDebugMode) {
        print('Voice service initialized successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Voice service initialization failed: $e');
      }
      return false;
    }
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);

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
  }

  // Speech-to-Text functionality
  Future<void> startListening({
    String localeId = 'en_US',
    Function(String)? onResult,
    Function(String)? onError,
  }) async {
    if (!_isAvailable) {
      onError?.call('Speech recognition not available');
      return;
    }

    if (_isListening) {
      await stopListening();
    }

    try {
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
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
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

  // Text-to-Speech functionality
  Future<void> speak(String text) async {
    try {
      if (_isSpeaking) {
        await stopSpeaking();
      }
      await _flutterTts.speak(text);
    } catch (e) {
      if (kDebugMode) {
        print('TTS speak error: $e');
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
      final errorMsg = 'Sorry, I encountered an error: $e';
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
      return List<Map<String, String>>.from(voices);
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
    await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
  }

  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }

  // Cleanup
  Future<void> dispose() async {
    await stopListening();
    await stopSpeaking();
  }
}