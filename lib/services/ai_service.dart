import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/study_summary_model.dart';

class AIService {
  // IMPORTANT: To use AI features, you need to set your OpenAI API key:
  // 
  // Method 1 - Run with API key (Recommended for development):
  // flutter run --dart-define=OPENAI_API_KEY=your_actual_api_key_here
  //
  // Method 2 - Set environment variable permanently:
  // export OPENAI_API_KEY=your_actual_api_key_here
  // flutter run
  //
  // Method 3 - For production, use secure storage or backend proxy
  //
  // Get your API key from: https://platform.openai.com/

  final Dio _dio = Dio();

  AIService() {
    _dio.options.baseUrl = ApiConfig.openAiBaseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
      'Content-Type': 'application/json',
    };

    // Set timeouts from config
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = ApiConfig.requestTimeout;
  }

  bool get isConfigured => ApiConfig.isApiKeyConfigured;

  String get configurationMessage => ApiConfig.validationMessage;

  // Helper method to clean JSON response from markdown formatting
  String _cleanJsonResponse(String response) {
    String cleaned = response.trim();

    // Remove markdown code block markers
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

    return cleaned;
  }

  Future<String> generateTutorResponse(String question, String subject) async {
    if (!isConfigured) {
      return ApiConfig.validationMessage;
    }

    return _executeWithRetry(() async {
      final response = await _dio.post(
        ApiConfig.chatCompletionsEndpoint,
        data: {
          'model': ApiConfig.openAiModel,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful AI tutor specializing in $subject. '
                  'Provide clear, educational explanations suitable for students. '
                  'Break down complex concepts into simple steps. '
                  'Always encourage learning and provide examples when helpful.'
            },
            {
              'role': 'user',
              'content': question,
            }
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      return content.toString().trim();
    });
  }

  Future<Map<String, String>> generateFlashcard(String topic,
      String subject) async {
    if (!isConfigured) {
      return {
        'question': 'API key not configured',
        'answer': 'Please set OPENAI_API_KEY environment variable to use AI features.',
      };
    }

    return _executeWithRetry(() async {
      final response = await _dio.post(
        ApiConfig.chatCompletionsEndpoint,
        data: {
          'model': ApiConfig.openAiModel,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful AI that creates educational flashcards. '
                  'Generate a question and answer pair for the given topic in $subject. '
                  'Format your response as JSON with "question" and "answer" fields. '
                  'Make the question challenging but fair, and provide a comprehensive answer.'
            },
            {
              'role': 'user',
              'content': 'Create a flashcard about: $topic',
            }
          ],
          'max_tokens': 300,
          'temperature': 0.8,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      final cleanedContent = _cleanJsonResponse(content);
      final jsonContent = jsonDecode(cleanedContent);

      return {
        'question': jsonContent['question']?.toString() ?? 'Generated question',
        'answer': jsonContent['answer']?.toString() ?? 'Generated answer',
      };
    });
  }

  Future<List<Map<String, String>>> generateQuiz(String topic, String subject,
      int numberOfQuestions) async {
    if (!isConfigured) {
      return [
        {
          'question': 'API key not configured',
          'options': 'Please set OPENAI_API_KEY environment variable to use AI features.|Option B|Option C|Option D',
          'correct': '0',
        }
      ];
    }

    return _executeWithRetry(() async {
      final response = await _dio.post(
        ApiConfig.chatCompletionsEndpoint,
        data: {
          'model': ApiConfig.openAiModel,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful AI that creates educational quizzes. '
                  'Generate $numberOfQuestions multiple choice questions about $topic in $subject. '
                  'Format your response as JSON array with objects containing "question", "options" (array of 4 choices), and "correct" (index of correct answer). '
                  'Make questions educational and appropriate for students.'
            },
            {
              'role': 'user',
              'content': 'Create a quiz about: $topic',
            }
          ],
          'max_tokens': 800,
          'temperature': 0.8,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      final cleanedContent = _cleanJsonResponse(content);
      final List<dynamic> jsonContent = jsonDecode(cleanedContent);

      return jsonContent.map((question) =>
      {
        'question': question['question']?.toString() ?? 'Generated question',
        'options': (question['options'] as List<dynamic>).map((opt) =>
            opt.toString()).toList().join('|'),
        'correct': question['correct']?.toString() ?? '0',
      }).toList();
    });
  }

  Future<String> explainConcept(String concept, String subject,
      String difficultyLevel) async {
    if (!isConfigured) {
      return ApiConfig.validationMessage;
    }

    return _executeWithRetry(() async {
      final response = await _dio.post(
        ApiConfig.chatCompletionsEndpoint,
        data: {
          'model': ApiConfig.openAiModel,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful AI tutor. Explain the concept of "$concept" in $subject '
                  'at a $difficultyLevel level. Use clear language, provide examples, and break down '
                  'complex ideas into understandable parts. Be encouraging and educational.'
            },
            {
              'role': 'user',
              'content': 'Please explain: $concept',
            }
          ],
          'max_tokens': 600,
          'temperature': 0.7,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      return content.toString().trim();
    });
  }

  Future<StudySummary> summarizeContent(String content, String subject) async {
    if (!isConfigured) {
      throw Exception(ApiConfig.validationMessage);
    }

    return _executeWithRetry(() async {
      final response = await _dio.post(
        ApiConfig.chatCompletionsEndpoint,
        data: {
          'model': ApiConfig.openAiModel,
          'messages': [
            {
              'role': 'system',
              'content': 'You are an AI study assistant that creates structured study notes. '
                  'Analyze the given content and create a comprehensive study summary. '
                  'Format your response as JSON with the following structure:\n'
                  '{\n'
                  '  "title": "Descriptive title for the content",\n'
                  '  "mainTopics": ["topic1", "topic2", "topic3"],\n'
                  '  "keyDefinitions": {"term1": "definition1", "term2": "definition2"},\n'
                  '  "importantFacts": ["fact1", "fact2", "fact3"]\n'
                  '}\n'
                  'Make it educational and well-structured for student learning.'
            },
            {
              'role': 'user',
              'content': 'Please summarize this content for studying:\n\n$content',
            }
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        },
      );

      final aiResponse = response.data['choices'][0]['message']['content'];
      return StudySummary.fromAIResponse(aiResponse, content, subject);
    });
  }

  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int retryCount = 0;

    while (retryCount < ApiConfig.maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;

        if (kDebugMode) {
          print('AI Service Error (attempt $retryCount): $e');
        }

        if (retryCount >= ApiConfig.maxRetries) {
          // Handle different types of errors
          if (e is DioException) {
            switch (e.type) {
              case DioExceptionType.connectionTimeout:
              case DioExceptionType.receiveTimeout:
                throw 'Request timeout. Please check your internet connection and try again.';
              case DioExceptionType.badResponse:
                if (e.response?.statusCode == 401) {
                  throw 'Invalid API key. Please check your OpenAI API key configuration.';
                } else if (e.response?.statusCode == 429) {
                  throw 'Rate limit exceeded. Please wait a moment and try again.';
                } else {
                  throw 'Server error. Please try again later.';
                }
              default:
                throw 'Network error. Please check your internet connection.';
            }
          }
          throw 'An unexpected error occurred. Please try again.';
        }

        // Wait before retrying
        await Future.delayed(ApiConfig.retryDelay);
      }
    }

    throw 'Maximum retry attempts reached. Please try again later.';
  }
}