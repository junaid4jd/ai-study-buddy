import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/achievement_model.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();

  factory AchievementService() => _instance;

  AchievementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Achievement> _achievements = [];
  int _totalPoints = 0;

  List<Achievement> get achievements => _achievements;

  int get totalPoints => _totalPoints;

  // Callbacks for achievement unlock events
  Function(Achievement)? onAchievementUnlocked;

  Future<void> initializeAchievements(String userId) async {
    try {
      // First, ensure default achievements exist
      await _ensureDefaultAchievements(userId);

      // Load user's achievements
      await loadUserAchievements(userId);
    } catch (e) {
      if (kDebugMode) print('Error initializing achievements: $e');
    }
  }

  Future<void> _ensureDefaultAchievements(String userId) async {
    final defaultAchievements = Achievement.getDefaultAchievements();

    for (final achievement in defaultAchievements) {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievement.id)
          .get();

      if (!doc.exists) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .doc(achievement.id)
            .set(achievement.toFirestore());
      }
    }
  }

  Future<void> loadUserAchievements(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      _achievements = querySnapshot.docs
          .map((doc) => Achievement.fromFirestore(doc))
          .toList();

      _totalPoints = _achievements
          .where((a) => a.isUnlocked)
          .fold(0, (total, a) => total + a.points);

      if (kDebugMode) {
        print('Loaded ${_achievements
            .length} achievements, total points: $_totalPoints');
      }
    } catch (e) {
      if (kDebugMode) print('Error loading achievements: $e');
    }
  }

  Future<void> checkAndUnlockAchievements(String userId, {
    int? studyTime,
    int? questionsAnswered,
    int? flashcardsCreated,
    int? streakDays,
    bool? hasPremium,
    bool? isFirstLogin,
  }) async {
    final updatedAchievements = <Achievement>[];

    for (final achievement in _achievements) {
      if (achievement.isUnlocked) continue;

      int newProgress = achievement.currentProgress;
      bool shouldUpdate = false;

      switch (achievement.type) {
        case AchievementType.studyTime:
          if (studyTime != null) {
            newProgress = studyTime;
            shouldUpdate = true;
          }
          break;
        case AchievementType.questionsAnswered:
          if (questionsAnswered != null) {
            newProgress = questionsAnswered;
            shouldUpdate = true;
          }
          break;
        case AchievementType.flashcardsCreated:
          if (flashcardsCreated != null) {
            newProgress = flashcardsCreated;
            shouldUpdate = true;
          }
          break;
        case AchievementType.streakDays:
          if (streakDays != null) {
            newProgress = streakDays;
            shouldUpdate = true;
          }
          break;
        case AchievementType.premium:
          if (hasPremium != null && hasPremium) {
            newProgress = 1;
            shouldUpdate = true;
          }
          break;
        case AchievementType.firstLogin:
          if (isFirstLogin != null && isFirstLogin) {
            newProgress = 1;
            shouldUpdate = true;
          }
          break;
        default:
          break;
      }

      if (shouldUpdate && newProgress != achievement.currentProgress) {
        final shouldUnlock = newProgress >= achievement.targetValue &&
            !achievement.isUnlocked;

        final updatedAchievement = achievement.copyWith(
          currentProgress: newProgress,
          isUnlocked: shouldUnlock ? true : achievement.isUnlocked,
          unlockedAt: shouldUnlock ? DateTime.now() : achievement.unlockedAt,
        );

        updatedAchievements.add(updatedAchievement);

        if (shouldUnlock) {
          await _unlockAchievement(userId, updatedAchievement);
        } else {
          await _updateAchievementProgress(userId, updatedAchievement);
        }
      }
    }

    // Update local achievements
    for (final updated in updatedAchievements) {
      final index = _achievements.indexWhere((a) => a.id == updated.id);
      if (index != -1) {
        _achievements[index] = updated;
      }
    }

    // Recalculate total points
    _totalPoints = _achievements
        .where((a) => a.isUnlocked)
        .fold(0, (total, a) => total + a.points);
  }

  Future<void> _unlockAchievement(String userId,
      Achievement achievement) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievement.id)
          .update(achievement.toFirestore());

      if (kDebugMode) print('Achievement unlocked: ${achievement.title}');

      // Trigger callback
      onAchievementUnlocked?.call(achievement);

      // You could also add a notification here
      // NotificationService.showAchievementNotification(achievement);

    } catch (e) {
      if (kDebugMode) print('Error unlocking achievement: $e');
    }
  }

  Future<void> _updateAchievementProgress(String userId,
      Achievement achievement) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievement.id)
          .update({
        'currentProgress': achievement.currentProgress,
      });
    } catch (e) {
      if (kDebugMode) print('Error updating achievement progress: $e');
    }
  }

  // Convenience methods for specific achievement types
  Future<void> trackStudyTime(String userId, int totalMinutes) async {
    await checkAndUnlockAchievements(userId, studyTime: totalMinutes);
  }

  Future<void> trackQuestionAsked(String userId, int totalQuestions) async {
    await checkAndUnlockAchievements(userId, questionsAnswered: totalQuestions);
  }

  Future<void> trackFlashcardCreated(String userId, int totalFlashcards) async {
    await checkAndUnlockAchievements(
        userId, flashcardsCreated: totalFlashcards);
  }

  Future<void> trackStreak(String userId, int streakDays) async {
    await checkAndUnlockAchievements(userId, streakDays: streakDays);
  }

  Future<void> trackPremiumUpgrade(String userId) async {
    await checkAndUnlockAchievements(userId, hasPremium: true);
  }

  Future<void> trackFirstLogin(String userId) async {
    await checkAndUnlockAchievements(userId, isFirstLogin: true);
  }

  // Get achievements by status
  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();

  List<Achievement> get lockedAchievements =>
      _achievements.where((a) => !a.isUnlocked).toList();

  List<Achievement> get inProgressAchievements =>
      _achievements
          .where((a) => !a.isUnlocked && a.currentProgress > 0)
          .toList();

  // Get user's rank/level based on total points
  int get userLevel => (_totalPoints / 100).floor() + 1;

  String get userRank {
    if (_totalPoints < 100) return 'Beginner';
    if (_totalPoints < 300) return 'Intermediate';
    if (_totalPoints < 600) return 'Advanced';
    if (_totalPoints < 1000) return 'Expert';
    return 'Master';
  }

  // Get next achievement to unlock
  Achievement? getNextAchievement() {
    final locked = lockedAchievements;
    if (locked.isEmpty) return null;

    // Sort by progress percentage and return the closest to completion
    locked.sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
    return locked.first;
  }
}