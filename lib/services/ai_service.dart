import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _apiKey = 'YOUR_OPENAI_API_KEY_HERE'; // Replace with your actual API key

  final Dio _dio = Dio();

  AIService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
  }

  Future<String> generateTutorResponse(String question, String subject) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-3.5-turbo',
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
    } catch (e) {
      if (kDebugMode) {
        print('Error generating AI response: $e');
      }
      return 'I apologize, but I encountered an error while processing your question. Please try again.';
    }
  }

  Future<Map<String, String>> generateFlashcard(String topic,
      String subject) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-3.5-turbo',
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
      final jsonContent = jsonDecode(content);

      return {
        'question': jsonContent['question']?.toString() ?? 'Generated question',
        'answer': jsonContent['answer']?.toString() ?? 'Generated answer',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error generating flashcard: $e');
      }
      return {
        'question': 'What is $topic?',
        'answer': 'This is a concept in $subject that requires further study.',
      };
    }
  }

  Future<List<Map<String, String>>> generateQuiz(String topic, String subject,
      int numberOfQuestions) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-3.5-turbo',
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
      final List<dynamic> jsonContent = jsonDecode(content);

      return jsonContent.map((question) =>
      {
        'question': question['question']?.toString() ?? 'Generated question',
        'options': (question['options'] as List<dynamic>).map((opt) =>
            opt.toString()).toList().join('|'),
        'correct': question['correct']?.toString() ?? '0',
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error generating quiz: $e');
      }
      return [
        {
          'question': 'What is $topic?',
          'options': 'Option A|Option B|Option C|Option D',
          'correct': '0',
        }
      ];
    }
  }

  Future<String> explainConcept(String concept, String subject,
      String difficultyLevel) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-3.5-turbo',
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
    } catch (e) {
      if (kDebugMode) {
        print('Error explaining concept: $e');
      }
      return 'I apologize, but I encountered an error while explaining this concept. Please try again.';
    }
  }
}