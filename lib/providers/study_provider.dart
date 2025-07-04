import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudyProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _studyStats = {};
  List<String> _subjects = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic> get studyStats => _studyStats;

  List<String> get subjects => _subjects;

  bool get isLoading => _isLoading;

  String? get error => _error;

  Future<void> loadStudyData(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load user's study stats
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _studyStats = userData['studyStats'] ?? {};
        _subjects = List<String>.from(userData['favoriteSubjects'] ?? []);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error loading study data: $e');
      }
    }
  }

  Future<void> updateStudyStats(String userId, String subject,
      int minutesStudied) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Update local stats
      _studyStats[subject] = (_studyStats[subject] ?? 0) + minutesStudied;
      _studyStats['total'] = (_studyStats['total'] ?? 0) + minutesStudied;
      _studyStats['today'] = (_studyStats['today'] ?? 0) + minutesStudied;
      _studyStats['sessions'] = (_studyStats['sessions'] ?? 0) + 1;

      // Update daily stats
      final dailyKey = 'daily_$today';
      _studyStats[dailyKey] = (_studyStats[dailyKey] ?? 0) + minutesStudied;

      // Save to Firestore
      await _firestore.collection('users').doc(userId).update({
        'studyStats': _studyStats,
      });

      // Save to local storage for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('studyStats_$userId', _studyStats.toString());

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating study stats: $e');
      }
    }
  }

  Future<void> addSubject(String userId, String subject) async {
    try {
      if (!_subjects.contains(subject)) {
        _subjects.add(subject);

        await _firestore.collection('users').doc(userId).update({
          'favoriteSubjects': _subjects,
        });

        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding subject: $e');
      }
    }
  }

  Future<void> removeSubject(String userId, String subject) async {
    try {
      _subjects.remove(subject);

      await _firestore.collection('users').doc(userId).update({
        'favoriteSubjects': _subjects,
      });

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error removing subject: $e');
      }
    }
  }

  int getTotalStudyTime() {
    return _studyStats['total'] ?? 0;
  }

  int getTodayStudyTime() {
    return _studyStats['today'] ?? 0;
  }

  int getSubjectStudyTime(String subject) {
    return _studyStats[subject] ?? 0;
  }

  int getTotalSessions() {
    return _studyStats['sessions'] ?? 0;
  }

  Map<String, int> getWeeklyStats() {
    final weeklyStats = <String, int>{};
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = 'daily_${date.toIso8601String().split('T')[0]}';
      final dayName = _getDayName(date.weekday);
      weeklyStats[dayName] = _studyStats[dateKey] ?? 0;
    }

    return weeklyStats;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return 'Unknown';
    }
  }

  Map<String, int> getSubjectBreakdown() {
    final subjectStats = <String, int>{};
    for (final subject in _subjects) {
      subjectStats[subject] = _studyStats[subject] ?? 0;
    }
    return subjectStats;
  }

  double getAverageSessionDuration() {
    final totalTime = getTotalStudyTime();
    final totalSessions = getTotalSessions();

    if (totalSessions == 0) return 0;
    return totalTime / totalSessions;
  }

  Future<void> resetDailyStats() async {
    try {
      _studyStats['today'] = 0;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting daily stats: $e');
      }
    }
  }

  Future<void> setStudyGoal(String userId, int dailyGoalMinutes) async {
    try {
      _studyStats['dailyGoal'] = dailyGoalMinutes;

      await _firestore.collection('users').doc(userId).update({
        'studyStats': _studyStats,
      });

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error setting study goal: $e');
      }
    }
  }

  int getDailyGoal() {
    return _studyStats['dailyGoal'] ?? 60; // Default 60 minutes
  }

  double getDailyProgress() {
    final goal = getDailyGoal();
    final today = getTodayStudyTime();

    if (goal == 0) return 0;
    return (today / goal).clamp(0.0, 1.0);
  }

  bool isDailyGoalReached() {
    return getDailyProgress() >= 1.0;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}