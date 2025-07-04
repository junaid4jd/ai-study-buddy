import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isPremium;
  final int questionsUsed;
  final int maxQuestions;
  final Map<String, dynamic> studyStats;
  final List<String> favoriteSubjects;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.isPremium = false,
    this.questionsUsed = 0,
    this.maxQuestions = 10,
    this.studyStats = const {},
    this.favoriteSubjects = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      isPremium: data['isPremium'] ?? false,
      questionsUsed: data['questionsUsed'] ?? 0,
      maxQuestions: data['maxQuestions'] ?? 10,
      studyStats: Map<String, dynamic>.from(data['studyStats'] ?? {}),
      favoriteSubjects: List<String>.from(data['favoriteSubjects'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isPremium': isPremium,
      'questionsUsed': questionsUsed,
      'maxQuestions': maxQuestions,
      'studyStats': studyStats,
      'favoriteSubjects': favoriteSubjects,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isPremium,
    int? questionsUsed,
    int? maxQuestions,
    Map<String, dynamic>? studyStats,
    List<String>? favoriteSubjects,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isPremium: isPremium ?? this.isPremium,
      questionsUsed: questionsUsed ?? this.questionsUsed,
      maxQuestions: maxQuestions ?? this.maxQuestions,
      studyStats: studyStats ?? this.studyStats,
      favoriteSubjects: favoriteSubjects ?? this.favoriteSubjects,
    );
  }
}