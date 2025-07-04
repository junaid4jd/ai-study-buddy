import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message_model.dart';
import '../services/ai_service.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIService _aiService = AIService();
  final Uuid _uuid = const Uuid();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentSessionId;

  List<ChatMessageModel> get messages => _messages;

  bool get isLoading => _isLoading;

  String? get error => _error;

  String? get currentSessionId => _currentSessionId;

  void startNewSession() {
    _currentSessionId = _uuid.v4();
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  Future<void> loadChatHistory(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('chat_messages')
          .where('userId', isEqualTo: userId)
          .where('sessionId', isEqualTo: _currentSessionId)
          .orderBy('timestamp', descending: false)
          .get();

      _messages = querySnapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error loading chat history: $e');
      }
    }
  }

  Future<void> sendMessage(String content, String userId,
      String subject) async {
    if (_currentSessionId == null) {
      startNewSession();
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Create user message
      final userMessage = ChatMessageModel(
        id: _uuid.v4(),
        userId: userId,
        sessionId: _currentSessionId!,
        content: content,
        type: MessageType.user,
        timestamp: DateTime.now(),
        subject: subject,
      );

      // Add user message to local list
      _messages.add(userMessage);
      notifyListeners();

      // Save user message to Firestore
      await _firestore
          .collection('chat_messages')
          .doc(userMessage.id)
          .set(userMessage.toFirestore());

      // Get AI response
      final aiResponse = await _aiService.generateTutorResponse(
          content, subject);

      // Create AI message
      final aiMessage = ChatMessageModel(
        id: _uuid.v4(),
        userId: userId,
        sessionId: _currentSessionId!,
        content: aiResponse,
        type: MessageType.ai,
        timestamp: DateTime.now(),
        subject: subject,
      );

      // Add AI message to local list
      _messages.add(aiMessage);
      _isLoading = false;
      notifyListeners();

      // Save AI message to Firestore
      await _firestore
          .collection('chat_messages')
          .doc(aiMessage.id)
          .set(aiMessage.toFirestore());
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error sending message: $e');
      }
    }
  }

  Future<void> bookmarkMessage(String messageId, bool isBookmarked) async {
    try {
      await _firestore
          .collection('chat_messages')
          .doc(messageId)
          .update({'isBookmarked': isBookmarked});

      // Update local message
      final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex] =
            _messages[messageIndex].copyWith(isBookmarked: isBookmarked);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error bookmarking message: $e');
      }
    }
  }

  Future<List<ChatMessageModel>> getBookmarkedMessages(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chat_messages')
          .where('userId', isEqualTo: userId)
          .where('isBookmarked', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bookmarked messages: $e');
      }
      return [];
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection('chat_messages')
          .doc(messageId)
          .delete();

      // Remove from local list
      _messages.removeWhere((msg) => msg.id == messageId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting message: $e');
      }
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _currentSessionId = null;
    notifyListeners();
  }
}