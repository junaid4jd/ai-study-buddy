import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardModel {
  final String id;
  final String userId;
  final String question;
  final String answer;
  final String subject;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime lastReviewed;
  final int reviewCount;
  final double difficultyLevel;
  final bool isBookmarked;
  final Map<String, dynamic> reviewHistory;

  FlashcardModel({
    required this.id,
    required this.userId,
    required this.question,
    required this.answer,
    required this.subject,
    this.tags = const [],
    required this.createdAt,
    required this.lastReviewed,
    this.reviewCount = 0,
    this.difficultyLevel = 0.5,
    this.isBookmarked = false,
    this.reviewHistory = const {},
  });

  factory FlashcardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlashcardModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
      subject: data['subject'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastReviewed: (data['lastReviewed'] as Timestamp).toDate(),
      reviewCount: data['reviewCount'] ?? 0,
      difficultyLevel: (data['difficultyLevel'] ?? 0.5).toDouble(),
      isBookmarked: data['isBookmarked'] ?? false,
      reviewHistory: Map<String, dynamic>.from(data['reviewHistory'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'question': question,
      'answer': answer,
      'subject': subject,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastReviewed': Timestamp.fromDate(lastReviewed),
      'reviewCount': reviewCount,
      'difficultyLevel': difficultyLevel,
      'isBookmarked': isBookmarked,
      'reviewHistory': reviewHistory,
    };
  }

  FlashcardModel copyWith({
    String? id,
    String? userId,
    String? question,
    String? answer,
    String? subject,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? lastReviewed,
    int? reviewCount,
    double? difficultyLevel,
    bool? isBookmarked,
    Map<String, dynamic>? reviewHistory,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      subject: subject ?? this.subject,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      reviewHistory: reviewHistory ?? this.reviewHistory,
    );
  }
}