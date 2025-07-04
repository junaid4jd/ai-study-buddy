import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/flashcard_model.dart';
import '../services/ai_service.dart';

class FlashcardProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIService _aiService = AIService();
  final Uuid _uuid = const Uuid();

  List<FlashcardModel> _flashcards = [];
  bool _isLoading = false;
  String? _error;

  List<FlashcardModel> get flashcards => _flashcards;

  bool get isLoading => _isLoading;

  String? get error => _error;

  Future<void> loadFlashcards(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('flashcards')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _flashcards = querySnapshot.docs
          .map((doc) => FlashcardModel.fromFirestore(doc))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error loading flashcards: $e');
      }
    }
  }

  Future<void> createFlashcard(String question, String answer, String subject,
      String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final flashcard = FlashcardModel(
        id: _uuid.v4(),
        userId: userId,
        question: question,
        answer: answer,
        subject: subject,
        createdAt: DateTime.now(),
        lastReviewed: DateTime.now(),
      );

      await _firestore
          .collection('flashcards')
          .doc(flashcard.id)
          .set(flashcard.toFirestore());

      _flashcards.insert(0, flashcard);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error creating flashcard: $e');
      }
    }
  }

  Future<void> generateFlashcard(String topic, String subject,
      String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final flashcardData = await _aiService.generateFlashcard(topic, subject);

      final flashcard = FlashcardModel(
        id: _uuid.v4(),
        userId: userId,
        question: flashcardData['question']!,
        answer: flashcardData['answer']!,
        subject: subject,
        tags: [topic],
        createdAt: DateTime.now(),
        lastReviewed: DateTime.now(),
      );

      await _firestore
          .collection('flashcards')
          .doc(flashcard.id)
          .set(flashcard.toFirestore());

      _flashcards.insert(0, flashcard);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error generating flashcard: $e');
      }
    }
  }

  Future<void> updateFlashcard(FlashcardModel flashcard) async {
    try {
      await _firestore
          .collection('flashcards')
          .doc(flashcard.id)
          .update(flashcard.toFirestore());

      final index = _flashcards.indexWhere((f) => f.id == flashcard.id);
      if (index != -1) {
        _flashcards[index] = flashcard;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating flashcard: $e');
      }
    }
  }

  Future<void> deleteFlashcard(String flashcardId) async {
    try {
      await _firestore
          .collection('flashcards')
          .doc(flashcardId)
          .delete();

      _flashcards.removeWhere((f) => f.id == flashcardId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting flashcard: $e');
      }
    }
  }

  Future<void> reviewFlashcard(String flashcardId,
      double difficultyRating) async {
    try {
      final flashcard = _flashcards.firstWhere((f) => f.id == flashcardId);
      final now = DateTime.now();

      final updatedFlashcard = flashcard.copyWith(
        lastReviewed: now,
        reviewCount: flashcard.reviewCount + 1,
        difficultyLevel: (flashcard.difficultyLevel + difficultyRating) / 2,
        reviewHistory: {
          ...flashcard.reviewHistory,
          now.millisecondsSinceEpoch.toString(): difficultyRating,
        },
      );

      await updateFlashcard(updatedFlashcard);
    } catch (e) {
      if (kDebugMode) {
        print('Error reviewing flashcard: $e');
      }
    }
  }

  Future<void> bookmarkFlashcard(String flashcardId, bool isBookmarked) async {
    try {
      await _firestore
          .collection('flashcards')
          .doc(flashcardId)
          .update({'isBookmarked': isBookmarked});

      final index = _flashcards.indexWhere((f) => f.id == flashcardId);
      if (index != -1) {
        _flashcards[index] =
            _flashcards[index].copyWith(isBookmarked: isBookmarked);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error bookmarking flashcard: $e');
      }
    }
  }

  List<FlashcardModel> getFlashcardsBySubject(String subject) {
    return _flashcards.where((f) => f.subject == subject).toList();
  }

  List<FlashcardModel> getBookmarkedFlashcards() {
    return _flashcards.where((f) => f.isBookmarked).toList();
  }

  List<FlashcardModel> getDueForReview() {
    final now = DateTime.now();
    return _flashcards.where((f) {
      final daysSinceReview = now
          .difference(f.lastReviewed)
          .inDays;
      return daysSinceReview >= 1; // Simple spaced repetition
    }).toList();
  }

  List<String> getUniqueSubjects() {
    return _flashcards.map((f) => f.subject).toSet().toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}