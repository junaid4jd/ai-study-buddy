import 'package:flutter/foundation.dart';
import '../services/progress_service.dart';

class ProgressProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();

  DailyProgress? _todayProgress;
  UserStats? _userStats;
  List<DailyProgress> _weeklyProgress = [];
  StudyGoalProgress? _studyGoalProgress;
  bool _isLoading = false;

  // Getters
  DailyProgress? get todayProgress => _todayProgress;

  UserStats? get userStats => _userStats;

  List<DailyProgress> get weeklyProgress => _weeklyProgress;

  StudyGoalProgress? get studyGoalProgress => _studyGoalProgress;

  bool get isLoading => _isLoading;

  // Initialize progress data for a user
  Future<void> initializeProgress(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadTodayProgress(userId),
        _loadUserStats(userId),
        _loadWeeklyProgress(userId),
        _loadStudyGoalProgress(userId, 60), // Default 60 minutes goal
      ]);
    } catch (e) {
      if (kDebugMode) print('Error initializing progress: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTodayProgress(String userId) async {
    try {
      _todayProgress = await _progressService.getTodaysProgress(userId);
    } catch (e) {
      if (kDebugMode) print('Error loading today progress: $e');
    }
  }

  Future<void> _loadUserStats(String userId) async {
    try {
      _userStats = await _progressService.getUserStats(userId);
    } catch (e) {
      if (kDebugMode) print('Error loading user stats: $e');
    }
  }

  Future<void> _loadWeeklyProgress(String userId) async {
    try {
      _weeklyProgress = await _progressService.getWeeklyProgress(userId);
    } catch (e) {
      if (kDebugMode) print('Error loading weekly progress: $e');
    }
  }

  Future<void> _loadStudyGoalProgress(String userId,
      int dailyGoalMinutes) async {
    try {
      _studyGoalProgress =
      await _progressService.getStudyGoalProgress(userId, dailyGoalMinutes);
    } catch (e) {
      if (kDebugMode) print('Error loading study goal progress: $e');
    }
  }

  // Track activities and refresh data
  Future<void> trackQuestion(String userId, {int studyTime = 2}) async {
    await _progressService.trackQuestion(userId, studyTime: studyTime);
    await _refreshData(userId);
  }

  Future<void> trackFlashcardCreation(String userId,
      {int studyTime = 3}) async {
    await _progressService.trackFlashcardCreation(userId, studyTime: studyTime);
    await _refreshData(userId);
  }

  Future<void> trackFlashcardReview(String userId, {int studyTime = 1}) async {
    await _progressService.trackFlashcardReview(userId, studyTime: studyTime);
    await _refreshData(userId);
  }

  Future<void> trackQuizCompletion(String userId, double score,
      {int studyTime = 5}) async {
    await _progressService.trackQuizCompletion(
        userId, score, studyTime: studyTime);
    await _refreshData(userId);
  }

  Future<void> trackStudySession(String userId, int minutes) async {
    await _progressService.trackStudySession(userId, minutes);
    await _refreshData(userId);
  }

  // Refresh all data
  Future<void> _refreshData(String userId) async {
    await Future.wait([
      _loadTodayProgress(userId),
      _loadUserStats(userId),
      _loadStudyGoalProgress(userId, 60),
    ]);
    notifyListeners();
  }

  // Manual refresh method
  Future<void> refreshProgress(String userId) async {
    await _refreshData(userId);
  }

  // Get current daily progress as percentage
  double get dailyProgressPercentage {
    if (_studyGoalProgress == null) return 0.0;
    return (_studyGoalProgress!.todayProgress / _studyGoalProgress!.dailyGoal)
        .clamp(0.0, 1.0);
  }

  // Get current study streak
  int get currentStreak {
    return _userStats?.currentStreak ?? 0;
  }

  // Get total study time today in minutes
  int get todayStudyTime {
    return _todayProgress?.totalStudyTime ?? 0;
  }

  // Check if daily goal is met
  bool get isDailyGoalMet {
    return _studyGoalProgress?.isGoalMet ?? false;
  }
}