import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();

  factory ProgressService() => _instance;

  ProgressService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Daily progress tracking
  Future<void> trackDailyActivity(String userId, ActivityType type, {
    int duration = 0,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final today = DateTime.now();
      final dateKey = _formatDate(today);

      final progressDoc = _firestore
          .collection('user_progress')
          .doc(userId)
          .collection('daily_progress')
          .doc(dateKey);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(progressDoc);

        Map<String, dynamic> data;
        if (snapshot.exists) {
          data = snapshot.data() as Map<String, dynamic>;
        } else {
          data = {
            'date': dateKey,
            'totalStudyTime': 0,
            'questionsAsked': 0,
            'flashcardsCreated': 0,
            'flashcardsReviewed': 0,
            'quizzesTaken': 0,
            'quizScore': 0.0,
            'achievements': <String>[],
            'lastUpdated': FieldValue.serverTimestamp(),
          };
        }

        switch (type) {
          case ActivityType.questionAsked:
            data['questionsAsked'] = (data['questionsAsked'] ?? 0) + 1;
            data['totalStudyTime'] = (data['totalStudyTime'] ?? 0) + duration;
            break;
          case ActivityType.flashcardCreated:
            data['flashcardsCreated'] = (data['flashcardsCreated'] ?? 0) + 1;
            data['totalStudyTime'] = (data['totalStudyTime'] ?? 0) + duration;
            break;
          case ActivityType.flashcardReviewed:
            data['flashcardsReviewed'] = (data['flashcardsReviewed'] ?? 0) + 1;
            data['totalStudyTime'] = (data['totalStudyTime'] ?? 0) + duration;
            break;
          case ActivityType.quizCompleted:
            data['quizzesTaken'] = (data['quizzesTaken'] ?? 0) + 1;
            data['totalStudyTime'] = (data['totalStudyTime'] ?? 0) + duration;
            if (metadata != null && metadata['score'] != null) {
              final currentScore = data['quizScore'] ?? 0.0;
              final currentQuizzes = data['quizzesTaken'] ?? 1;
              final newScore = metadata['score'] as double;
              data['quizScore'] =
                  ((currentScore * (currentQuizzes - 1)) + newScore) /
                      currentQuizzes;
            }
            break;
          case ActivityType.studySession:
            data['totalStudyTime'] = (data['totalStudyTime'] ?? 0) + duration;
            break;
        }

        data['lastUpdated'] = FieldValue.serverTimestamp();
        transaction.set(progressDoc, data, SetOptions(merge: true));
      });

      // Update user's overall statistics
      await _updateUserStats(userId, type, duration, metadata);
    } catch (e) {
      if (kDebugMode) print('Error tracking daily activity: $e');
    }
  }

  Future<void> _updateUserStats(String userId, ActivityType type, int duration,
      Map<String, dynamic>? metadata) async {
    try {
      final userStatsDoc = _firestore.collection('user_stats').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userStatsDoc);

        Map<String, dynamic> stats;
        if (snapshot.exists) {
          stats = snapshot.data() as Map<String, dynamic>;
        } else {
          stats = {
            'totalStudyTime': 0,
            'totalQuestionsAsked': 0,
            'totalFlashcardsCreated': 0,
            'totalFlashcardsReviewed': 0,
            'totalQuizzesTaken': 0,
            'averageQuizScore': 0.0,
            'currentStreak': 1,
            'longestStreak': 1,
            'lastActiveDate': _formatDate(DateTime.now()),
            'createdAt': FieldValue.serverTimestamp(),
          };
        }

        // Update streak
        final today = _formatDate(DateTime.now());
        final lastActiveDate = stats['lastActiveDate'] as String?;

        if (lastActiveDate != null) {
          final lastActive = DateTime.parse(lastActiveDate);
          final daysDiff = DateTime
              .now()
              .difference(lastActive)
              .inDays;

          if (daysDiff == 1) {
            // Consecutive day - increment streak
            stats['currentStreak'] = (stats['currentStreak'] ?? 0) + 1;
            stats['longestStreak'] =
                [stats['longestStreak'] ?? 0, stats['currentStreak']].reduce((a,
                    b) => a > b ? a : b);
          } else if (daysDiff > 1) {
            // Streak broken - reset to 1
            stats['currentStreak'] = 1;
          }
          // If daysDiff == 0, it's the same day, don't change streak
        }

        stats['lastActiveDate'] = today;

        // Update activity-specific stats
        switch (type) {
          case ActivityType.questionAsked:
            stats['totalQuestionsAsked'] =
                (stats['totalQuestionsAsked'] ?? 0) + 1;
            break;
          case ActivityType.flashcardCreated:
            stats['totalFlashcardsCreated'] =
                (stats['totalFlashcardsCreated'] ?? 0) + 1;
            break;
          case ActivityType.flashcardReviewed:
            stats['totalFlashcardsReviewed'] =
                (stats['totalFlashcardsReviewed'] ?? 0) + 1;
            break;
          case ActivityType.quizCompleted:
            stats['totalQuizzesTaken'] = (stats['totalQuizzesTaken'] ?? 0) + 1;
            if (metadata != null && metadata['score'] != null) {
              final currentAvg = stats['averageQuizScore'] ?? 0.0;
              final totalQuizzes = stats['totalQuizzesTaken'] ?? 1;
              final newScore = metadata['score'] as double;
              stats['averageQuizScore'] =
                  ((currentAvg * (totalQuizzes - 1)) + newScore) / totalQuizzes;
            }
            break;
          case ActivityType.studySession:
            break;
        }

        stats['totalStudyTime'] = (stats['totalStudyTime'] ?? 0) + duration;
        stats['lastUpdated'] = FieldValue.serverTimestamp();

        transaction.set(userStatsDoc, stats, SetOptions(merge: true));
      });
    } catch (e) {
      if (kDebugMode) print('Error updating user stats: $e');
    }
  }

  Future<DailyProgress?> getTodaysProgress(String userId) async {
    try {
      final today = _formatDate(DateTime.now());
      final doc = await _firestore
          .collection('user_progress')
          .doc(userId)
          .collection('daily_progress')
          .doc(today)
          .get();

      if (doc.exists) {
        return DailyProgress.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting today\'s progress: $e');
      return null;
    }
  }

  Future<UserStats?> getUserStats(String userId) async {
    try {
      final doc = await _firestore.collection('user_stats').doc(userId).get();

      if (doc.exists) {
        return UserStats.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting user stats: $e');
      return null;
    }
  }

  Future<List<DailyProgress>> getWeeklyProgress(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final querySnapshot = await _firestore
          .collection('user_progress')
          .doc(userId)
          .collection('daily_progress')
          .where('date', isGreaterThanOrEqualTo: _formatDate(weekAgo))
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => DailyProgress.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting weekly progress: $e');
      return [];
    }
  }

  Future<List<DailyProgress>> getMonthlyProgress(String userId) async {
    try {
      final now = DateTime.now();
      final monthAgo = DateTime(now.year, now.month - 1, now.day);

      final querySnapshot = await _firestore
          .collection('user_progress')
          .doc(userId)
          .collection('daily_progress')
          .where('date', isGreaterThanOrEqualTo: _formatDate(monthAgo))
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => DailyProgress.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting monthly progress: $e');
      return [];
    }
  }

  // Calculate study goal progress (in minutes)
  Future<StudyGoalProgress> getStudyGoalProgress(String userId,
      int dailyGoalMinutes) async {
    try {
      final todayProgress = await getTodaysProgress(userId);
      final weeklyProgress = await getWeeklyProgress(userId);
      final userStats = await getUserStats(userId);

      final todayMinutes = todayProgress?.totalStudyTime ?? 0;
      final weeklyMinutes = weeklyProgress.fold(
          0, (sum, day) => sum + day.totalStudyTime);
      final currentStreak = userStats?.currentStreak ?? 0;

      return StudyGoalProgress(
        dailyGoal: dailyGoalMinutes,
        todayProgress: todayMinutes,
        weeklyGoal: dailyGoalMinutes * 7,
        weeklyProgress: weeklyMinutes,
        currentStreak: currentStreak,
        isGoalMet: todayMinutes >= dailyGoalMinutes,
      );
    } catch (e) {
      if (kDebugMode) print('Error getting study goal progress: $e');
      return StudyGoalProgress(
        dailyGoal: dailyGoalMinutes,
        todayProgress: 0,
        weeklyGoal: dailyGoalMinutes * 7,
        weeklyProgress: 0,
        currentStreak: 0,
        isGoalMet: false,
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day
        .toString().padLeft(2, '0')}';
  }

  // Helper methods for easy tracking
  Future<void> trackQuestion(String userId, {int studyTime = 2}) async {
    await trackDailyActivity(
        userId, ActivityType.questionAsked, duration: studyTime);
  }

  Future<void> trackFlashcardCreation(String userId,
      {int studyTime = 3}) async {
    await trackDailyActivity(
        userId, ActivityType.flashcardCreated, duration: studyTime);
  }

  Future<void> trackFlashcardReview(String userId, {int studyTime = 1}) async {
    await trackDailyActivity(
        userId, ActivityType.flashcardReviewed, duration: studyTime);
  }

  Future<void> trackQuizCompletion(String userId, double score,
      {int studyTime = 5}) async {
    await trackDailyActivity(
      userId,
      ActivityType.quizCompleted,
      duration: studyTime,
      metadata: {'score': score},
    );
  }

  Future<void> trackStudySession(String userId, int minutes) async {
    await trackDailyActivity(
        userId, ActivityType.studySession, duration: minutes);
  }
}

enum ActivityType {
  questionAsked,
  flashcardCreated,
  flashcardReviewed,
  quizCompleted,
  studySession,
}

class DailyProgress {
  final String date;
  final int totalStudyTime;
  final int questionsAsked;
  final int flashcardsCreated;
  final int flashcardsReviewed;
  final int quizzesTaken;
  final double quizScore;
  final List<String> achievements;
  final DateTime? lastUpdated;

  DailyProgress({
    required this.date,
    required this.totalStudyTime,
    required this.questionsAsked,
    required this.flashcardsCreated,
    required this.flashcardsReviewed,
    required this.quizzesTaken,
    required this.quizScore,
    required this.achievements,
    this.lastUpdated,
  });

  factory DailyProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyProgress(
      date: data['date'] ?? '',
      totalStudyTime: data['totalStudyTime'] ?? 0,
      questionsAsked: data['questionsAsked'] ?? 0,
      flashcardsCreated: data['flashcardsCreated'] ?? 0,
      flashcardsReviewed: data['flashcardsReviewed'] ?? 0,
      quizzesTaken: data['quizzesTaken'] ?? 0,
      quizScore: (data['quizScore'] ?? 0.0).toDouble(),
      achievements: List<String>.from(data['achievements'] ?? []),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }
}

class UserStats {
  final int totalStudyTime;
  final int totalQuestionsAsked;
  final int totalFlashcardsCreated;
  final int totalFlashcardsReviewed;
  final int totalQuizzesTaken;
  final double averageQuizScore;
  final int currentStreak;
  final int longestStreak;
  final String lastActiveDate;
  final DateTime? createdAt;

  UserStats({
    required this.totalStudyTime,
    required this.totalQuestionsAsked,
    required this.totalFlashcardsCreated,
    required this.totalFlashcardsReviewed,
    required this.totalQuizzesTaken,
    required this.averageQuizScore,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActiveDate,
    this.createdAt,
  });

  factory UserStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserStats(
      totalStudyTime: data['totalStudyTime'] ?? 0,
      totalQuestionsAsked: data['totalQuestionsAsked'] ?? 0,
      totalFlashcardsCreated: data['totalFlashcardsCreated'] ?? 0,
      totalFlashcardsReviewed: data['totalFlashcardsReviewed'] ?? 0,
      totalQuizzesTaken: data['totalQuizzesTaken'] ?? 0,
      averageQuizScore: (data['averageQuizScore'] ?? 0.0).toDouble(),
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastActiveDate: data['lastActiveDate'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class StudyGoalProgress {
  final int dailyGoal;
  final int todayProgress;
  final int weeklyGoal;
  final int weeklyProgress;
  final int currentStreak;
  final bool isGoalMet;

  StudyGoalProgress({
    required this.dailyGoal,
    required this.todayProgress,
    required this.weeklyGoal,
    required this.weeklyProgress,
    required this.currentStreak,
    required this.isGoalMet,
  });

  double get dailyProgressPercentage => todayProgress / dailyGoal;

  double get weeklyProgressPercentage => weeklyProgress / weeklyGoal;
}