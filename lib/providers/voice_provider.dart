import 'package:flutter/foundation.dart';
import '../services/voice_service.dart';

enum VoiceMode {
  idle,
  listening,
  speaking,
  processing,
}

class VoiceProvider with ChangeNotifier {
  final VoiceService _voiceService = VoiceService();

  VoiceMode _currentMode = VoiceMode.idle;
  String _recognizedText = '';
  String _lastResponse = '';
  String _currentSubject = 'General';
  double _confidence = 0.0;
  bool _isInitialized = false;
  String? _error;

  // Settings
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 0.8;
  bool _autoSpeak = true;

  // Getters
  VoiceMode get currentMode => _currentMode;

  String get recognizedText => _recognizedText;

  String get lastResponse => _lastResponse;

  String get currentSubject => _currentSubject;

  double get confidence => _confidence;

  bool get isInitialized => _isInitialized;

  String? get error => _error;

  bool get isListening => _currentMode == VoiceMode.listening;

  bool get isSpeaking => _currentMode == VoiceMode.speaking;

  bool get isProcessing => _currentMode == VoiceMode.processing;

  // Settings getters
  double get speechRate => _speechRate;

  double get pitch => _pitch;

  double get volume => _volume;

  bool get autoSpeak => _autoSpeak;

  // Initialize voice service
  Future<bool> initialize() async {
    try {
      _error = null;
      notifyListeners();

      if (kDebugMode) {
        print('VoiceProvider: Starting initialization...');
      }

      final success = await _voiceService.initialize();
      _isInitialized = success;

      if (!success) {
        _error = _voiceService.initializationError ??
            'Voice service initialization failed. Please check permissions.';
        if (kDebugMode) {
          print('VoiceProvider: Initialization failed - $_error');
          final status = _voiceService.getStatus();
          print('VoiceProvider: Service status - $status');
        }
      } else {
        if (kDebugMode) {
          print('VoiceProvider: Initialization successful');
        }
      }

      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Initialization error: $e';
      _isInitialized = false;
      if (kDebugMode) {
        print('VoiceProvider: Initialization exception - $e');
      }
      notifyListeners();
      return false;
    }
  }

  // Retry initialization
  Future<bool> retryInitialization() async {
    if (kDebugMode) {
      print('VoiceProvider: Retrying initialization...');
    }
    return await _voiceService.reinitialize().then((success) {
      _isInitialized = success;
      if (!success) {
        _error = _voiceService.initializationError ?? 'Retry failed';
      } else {
        _error = null;
      }
      notifyListeners();
      return success;
    });
  }

  // Get detailed debug info
  Map<String, dynamic> getDebugInfo() {
    final serviceStatus = _voiceService.getStatus();
    return {
      ...serviceStatus,
      'providerMode': _currentMode.toString(),
      'providerError': _error,
      'recognizedText': _recognizedText,
      'lastResponse': _lastResponse,
    };
  }

  // Start voice listening
  Future<void> startListening() async {
    if (!_isInitialized) {
      _error = 'Voice service not initialized. Please retry initialization.';
      notifyListeners();
      return;
    }

    try {
      _currentMode = VoiceMode.listening;
      _error = null;
      notifyListeners();

      await _voiceService.startListening(
        onResult: (text) {
          _recognizedText = text;
          _confidence = _voiceService.confidence;
          notifyListeners();
        },
        onError: (error) {
          _error = error;
          _currentMode = VoiceMode.idle;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Failed to start listening: $e';
      _currentMode = VoiceMode.idle;
      if (kDebugMode) {
        print('VoiceProvider: Start listening error - $e');
      }
      notifyListeners();
    }
  }

  // Stop voice listening
  Future<void> stopListening() async {
    try {
      await _voiceService.stopListening();
      _currentMode = VoiceMode.idle;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to stop listening: $e';
      if (kDebugMode) {
        print('VoiceProvider: Stop listening error - $e');
      }
      notifyListeners();
    }
  }

  // Ask AI using voice
  Future<void> askAIWithVoice() async {
    if (_recognizedText
        .trim()
        .isEmpty) {
      _error = 'No question recognized';
      notifyListeners();
      return;
    }

    try {
      _currentMode = VoiceMode.processing;
      _error = null;
      notifyListeners();

      final response = await _voiceService.askAIWithVoice(
        question: _recognizedText,
        subject: _currentSubject,
        speakResponse: false, // We'll handle speaking ourselves
      );

      _lastResponse = response;

      if (_autoSpeak && response.isNotEmpty) {
        await speak(response);
      } else {
        _currentMode = VoiceMode.idle;
      }

      notifyListeners();
    } catch (e) {
      _error = 'AI request failed: $e';
      _currentMode = VoiceMode.idle;
      if (kDebugMode) {
        print('VoiceProvider: AI request error - $e');
      }
      notifyListeners();
    }
  }

  // Speak text
  Future<void> speak(String text) async {
    try {
      _currentMode = VoiceMode.speaking;
      notifyListeners();

      await _voiceService.speak(text);

      _currentMode = VoiceMode.idle;
      notifyListeners();
    } catch (e) {
      _error = 'Speech failed: $e';
      _currentMode = VoiceMode.idle;
      if (kDebugMode) {
        print('VoiceProvider: Speech error - $e');
      }
      notifyListeners();
    }
  }

  // Stop speaking
  Future<void> stopSpeaking() async {
    try {
      await _voiceService.stopSpeaking();
      _currentMode = VoiceMode.idle;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to stop speaking: $e';
      if (kDebugMode) {
        print('VoiceProvider: Stop speaking error - $e');
      }
      notifyListeners();
    }
  }

  // Read flashcard
  Future<void> readFlashcard({
    required String question,
    required String answer,
    bool readQuestion = true,
    bool readAnswer = true,
  }) async {
    try {
      _currentMode = VoiceMode.speaking;
      notifyListeners();

      await _voiceService.readFlashcard(
        question: question,
        answer: answer,
        readQuestion: readQuestion,
        readAnswer: readAnswer,
      );

      _currentMode = VoiceMode.idle;
      notifyListeners();
    } catch (e) {
      _error = 'Flashcard reading failed: $e';
      _currentMode = VoiceMode.idle;
      if (kDebugMode) {
        print('VoiceProvider: Flashcard reading error - $e');
      }
      notifyListeners();
    }
  }

  // Practice pronunciation
  Future<double> practicePronunciation(String targetText) async {
    try {
      _currentMode = VoiceMode.processing;
      _error = null;
      notifyListeners();

      final score = await _voiceService.practicePronunciation(
        targetText: targetText,
      );

      _currentMode = VoiceMode.idle;
      notifyListeners();

      return score;
    } catch (e) {
      _error = 'Pronunciation practice failed: $e';
      _currentMode = VoiceMode.idle;
      if (kDebugMode) {
        print('VoiceProvider: Pronunciation practice error - $e');
      }
      notifyListeners();
      return 0.0;
    }
  }

  // Take voice note
  Future<String> takeVoiceNote({Duration? maxDuration}) async {
    try {
      _currentMode = VoiceMode.listening;
      _error = null;
      notifyListeners();

      final note = await _voiceService.takeVoiceNote(
        maxDuration: maxDuration ?? const Duration(minutes: 2),
        onPartialResult: (text) {
          _recognizedText = text;
          notifyListeners();
        },
        onError: (error) {
          _error = error;
          notifyListeners();
        },
      );

      _currentMode = VoiceMode.idle;
      notifyListeners();

      return note;
    } catch (e) {
      _error = 'Voice note failed: $e';
      _currentMode = VoiceMode.idle;
      if (kDebugMode) {
        print('VoiceProvider: Voice note error - $e');
      }
      notifyListeners();
      return '';
    }
  }

  // Settings
  void setSubject(String subject) {
    _currentSubject = subject;
    notifyListeners();
  }

  void setAutoSpeak(bool autoSpeak) {
    _autoSpeak = autoSpeak;
    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    await _voiceService.setSpeechRate(_speechRate);
    notifyListeners();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _voiceService.setPitch(_pitch);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _voiceService.setVolume(_volume);
    notifyListeners();
  }

  // Get available voices
  Future<List<Map<String, String>>> getAvailableVoices() async {
    return await _voiceService.getAvailableVoices();
  }

  // Set voice
  Future<void> setVoice(Map<String, String> voice) async {
    await _voiceService.setVoice(voice);
    notifyListeners();
  }

  // Clear text and responses
  void clearText() {
    _recognizedText = '';
    _lastResponse = '';
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}