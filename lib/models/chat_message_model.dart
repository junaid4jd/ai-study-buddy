import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { user, ai, system }

class ChatMessageModel {
  final String id;
  final String userId;
  final String sessionId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final String subject;
  final Map<String, dynamic> metadata;
  final bool isBookmarked;
  final double? confidence;
  final List<String> references;

  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.subject,
    this.metadata = const {},
    this.isBookmarked = false,
    this.confidence,
    this.references = const [],
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      sessionId: data['sessionId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
            (e) =>
        e
            .toString()
            .split('.')
            .last == data['type'],
        orElse: () => MessageType.user,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      subject: data['subject'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      isBookmarked: data['isBookmarked'] ?? false,
      confidence: data['confidence']?.toDouble(),
      references: List<String>.from(data['references'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'content': content,
      'type': type
          .toString()
          .split('.')
          .last,
      'timestamp': Timestamp.fromDate(timestamp),
      'subject': subject,
      'metadata': metadata,
      'isBookmarked': isBookmarked,
      'confidence': confidence,
      'references': references,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? userId,
    String? sessionId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    String? subject,
    Map<String, dynamic>? metadata,
    bool? isBookmarked,
    double? confidence,
    List<String>? references,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      subject: subject ?? this.subject,
      metadata: metadata ?? this.metadata,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      confidence: confidence ?? this.confidence,
      references: references ?? this.references,
    );
  }
}