class StudySummary {
  final String id;
  final String title;
  final String originalContent;
  final List<String> mainTopics;
  final Map<String, String> keyDefinitions;
  final List<String> importantFacts;
  final DateTime createdAt;
  final String subject;

  StudySummary({
    required this.id,
    required this.title,
    required this.originalContent,
    required this.mainTopics,
    required this.keyDefinitions,
    required this.importantFacts,
    required this.createdAt,
    required this.subject,
  });

  factory StudySummary.fromJson(Map<String, dynamic> json) {
    return StudySummary(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Summary',
      originalContent: json['originalContent'] ?? '',
      mainTopics: List<String>.from(json['mainTopics'] ?? []),
      keyDefinitions: Map<String, String>.from(json['keyDefinitions'] ?? {}),
      importantFacts: List<String>.from(json['importantFacts'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      subject: json['subject'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'originalContent': originalContent,
      'mainTopics': mainTopics,
      'keyDefinitions': keyDefinitions,
      'importantFacts': importantFacts,
      'createdAt': createdAt.toIso8601String(),
      'subject': subject,
    };
  }

  factory StudySummary.fromAIResponse(String aiResponse, String originalContent,
      String subject) {
    try {
      // Clean and parse AI response
      String cleaned = aiResponse.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.replaceFirst('```json', '').trim();
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceFirst('```', '').trim();
      }
      if (cleaned.endsWith('```')) {
        cleaned =
            cleaned
                .replaceRange(cleaned.lastIndexOf('```'), cleaned.length, '')
                .trim();
      }

      final json = jsonDecode(cleaned);

      return StudySummary(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        title: json['title'] ?? 'Study Summary',
        originalContent: originalContent,
        mainTopics: List<String>.from(json['mainTopics'] ?? []),
        keyDefinitions: Map<String, String>.from(json['keyDefinitions'] ?? {}),
        importantFacts: List<String>.from(json['importantFacts'] ?? []),
        createdAt: DateTime.now(),
        subject: subject,
      );
    } catch (e) {
      // Fallback if JSON parsing fails
      return StudySummary(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        title: 'Study Summary',
        originalContent: originalContent,
        mainTopics: ['Summary generated successfully'],
        keyDefinitions: {'Summary': aiResponse},
        importantFacts: ['AI generated summary available'],
        createdAt: DateTime.now(),
        subject: subject,
      );
    }
  }
}

import 'dart:convert';