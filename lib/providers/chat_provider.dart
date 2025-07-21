import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message_model.dart';
import '../services/ai_service.dart';
import '../services/achievement_service.dart';
import '../services/progress_service.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIService _aiService = AIService();
  final AchievementService _achievementService = AchievementService();
  final ProgressService _progressService = ProgressService();
  final Uuid _uuid = const Uuid();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  int _totalQuestions = 0;
  String? _currentUserId;

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  bool get isInitialized => _isInitialized;
  String? get error => _error;
  int get totalQuestions => _totalQuestions;

  // Lazy load chat history when needed
  Future<void> ensureInitialized(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    _currentUserId = userId;
    await loadChatHistory(userId);
  }

  Future<void> loadChatHistory(String userId) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('chats')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: false)
          .limit(50)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
        throw TimeoutException('Loading chat history timed out'),
      );

      _messages = querySnapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .toList();

      _totalQuestions = _messages
          .where((msg) => msg.type == MessageType.user)
          .length;

      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error loading chat history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String userId, String message,
      String subject) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userMessage = ChatMessageModel(
        id: _uuid.v4(),
        userId: userId,
        sessionId: 'default',
        content: message,
        type: MessageType.user,
        timestamp: DateTime.now(),
        subject: subject,
      );

      _messages.add(userMessage);
      notifyListeners();

      await _firestore
          .collection('chats')
          .doc(userMessage.id)
          .set(userMessage.toFirestore());

      final aiResponse = await _aiService.generateTutorResponse(
          message, subject);

      final aiMessage = ChatMessageModel(
        id: _uuid.v4(),
        userId: userId,
        sessionId: 'default',
        content: aiResponse,
        type: MessageType.ai,
        timestamp: DateTime.now(),
        subject: subject,
      );

      _messages.add(aiMessage);

      _totalQuestions++;
      await _achievementService.trackQuestionAsked(userId, _totalQuestions);

      // Track question in progress service (2 minutes average time per question)
      await _progressService.trackQuestion(userId, studyTime: 2);

      await _firestore
          .collection('chats')
          .doc(aiMessage.id)
          .set(aiMessage.toFirestore());

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('Error sending message: $e');
      return false;
    }
  }

  Future<void> clearChatHistory(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _messages.clear();
      _totalQuestions = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) print('Error clearing chat history: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('chats').doc(messageId).delete();

      _messages.removeWhere((msg) => msg.id == messageId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) print('Error deleting message: $e');
    }
  }

  List<ChatMessageModel> getMessagesBySubject(String subject) {
    return _messages.where((msg) => msg.subject == subject).toList();
  }

  List<String> getUniqueSubjects() {
    return _messages
        .map((msg) => msg.subject)
        .where((subject) => subject.isNotEmpty)
        .toSet()
        .toList();
  }

  ChatMessageModel? getLastMessage() {
    return _messages.isNotEmpty ? _messages.last : null;
  }

  List<ChatMessageModel> getRecentMessages({int limit = 10}) {
    final sortedMessages = List<ChatMessageModel>.from(_messages);
    sortedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedMessages.take(limit).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void addMessage(ChatMessageModel message) {
    _messages.add(message);
    if (message.type == MessageType.user) {
      _totalQuestions++;
    }
    notifyListeners();
  }

  void removeMessage(String messageId) {
    final removedMessage = _messages.firstWhere((msg) => msg.id == messageId);
    _messages.removeWhere((msg) => msg.id == messageId);

    if (removedMessage.type == MessageType.user && _totalQuestions > 0) {
      _totalQuestions--;
    }
    notifyListeners();
  }
}