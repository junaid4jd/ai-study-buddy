import 'package:cloud_firestore/cloud_firestore.dart';

enum AchievementType {
  studyTime,
  questionsAnswered,
  flashcardsCreated,
  streakDays,
  subjectMastery,
  firstLogin,
  premium,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final AchievementType type;
  final int targetValue;
  final int points;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int currentProgress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.type,
    required this.targetValue,
    required this.points,
    this.isUnlocked = false,
    this.unlockedAt,
    this.currentProgress = 0,
  });

  factory Achievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Achievement(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      iconPath: data['iconPath'] ?? '',
      type: AchievementType.values.firstWhere(
            (e) =>
        e
            .toString()
            .split('.')
            .last == data['type'],
        orElse: () => AchievementType.studyTime,
      ),
      targetValue: data['targetValue'] ?? 0,
      points: data['points'] ?? 0,
      isUnlocked: data['isUnlocked'] ?? false,
      unlockedAt: data['unlockedAt'] != null
          ? (data['unlockedAt'] as Timestamp).toDate()
          : null,
      currentProgress: data['currentProgress'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'type': type
          .toString()
          .split('.')
          .last,
      'targetValue': targetValue,
      'points': points,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'currentProgress': currentProgress,
    };
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    AchievementType? type,
    int? targetValue,
    int? points,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? currentProgress,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      points: points ?? this.points,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
    );
  }

  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  bool get isCompleted => currentProgress >= targetValue;

  static List<Achievement> getDefaultAchievements() {
    return [
      Achievement(
        id: 'first_steps',
        title: 'First Steps',
        description: 'Welcome to AI Study Buddy! Complete your first session.',
        iconPath: 'assets/icons/first_steps.png',
        type: AchievementType.firstLogin,
        targetValue: 1,
        points: 10,
      ),
      Achievement(
        id: 'study_rookie',
        title: 'Study Rookie',
        description: 'Study for 1 hour total',
        iconPath: 'assets/icons/study_rookie.png',
        type: AchievementType.studyTime,
        targetValue: 60,
        // minutes
        points: 25,
      ),
      Achievement(
        id: 'study_pro',
        title: 'Study Pro',
        description: 'Study for 10 hours total',
        iconPath: 'assets/icons/study_pro.png',
        type: AchievementType.studyTime,
        targetValue: 600,
        // minutes
        points: 100,
      ),
      Achievement(
        id: 'study_master',
        title: 'Study Master',
        description: 'Study for 50 hours total',
        iconPath: 'assets/icons/study_master.png',
        type: AchievementType.studyTime,
        targetValue: 3000,
        // minutes
        points: 500,
      ),
      Achievement(
        id: 'curious_mind',
        title: 'Curious Mind',
        description: 'Ask 10 questions to the AI tutor',
        iconPath: 'assets/icons/curious_mind.png',
        type: AchievementType.questionsAnswered,
        targetValue: 10,
        points: 50,
      ),
      Achievement(
        id: 'question_master',
        title: 'Question Master',
        description: 'Ask 100 questions to the AI tutor',
        iconPath: 'assets/icons/question_master.png',
        type: AchievementType.questionsAnswered,
        targetValue: 100,
        points: 200,
      ),
      Achievement(
        id: 'flashcard_creator',
        title: 'Flashcard Creator',
        description: 'Create 10 flashcards',
        iconPath: 'assets/icons/flashcard_creator.png',
        type: AchievementType.flashcardsCreated,
        targetValue: 10,
        points: 30,
      ),
      Achievement(
        id: 'flashcard_master',
        title: 'Flashcard Master',
        description: 'Create 100 flashcards',
        iconPath: 'assets/icons/flashcard_master.png',
        type: AchievementType.flashcardsCreated,
        targetValue: 100,
        points: 150,
      ),
      Achievement(
        id: 'streak_starter',
        title: 'Streak Starter',
        description: 'Study for 3 days in a row',
        iconPath: 'assets/icons/streak_starter.png',
        type: AchievementType.streakDays,
        targetValue: 3,
        points: 40,
      ),
      Achievement(
        id: 'streak_legend',
        title: 'Streak Legend',
        description: 'Study for 30 days in a row',
        iconPath: 'assets/icons/streak_legend.png',
        type: AchievementType.streakDays,
        targetValue: 30,
        points: 300,
      ),
      Achievement(
        id: 'premium_member',
        title: 'Premium Member',
        description: 'Unlock premium features',
        iconPath: 'assets/icons/premium_member.png',
        type: AchievementType.premium,
        targetValue: 1,
        points: 100,
      ),
    ];
  }
}