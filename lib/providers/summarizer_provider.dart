import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/study_summary_model.dart';
import '../services/ai_service.dart';

class SummarizerProvider with ChangeNotifier {
  final AIService _aiService = AIService();
  final List<StudySummary> _summaries = [];
  bool _isLoading = false;
  String? _error;

  List<StudySummary> get summaries => _summaries;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get isConfigured => _aiService.isConfigured;

  SummarizerProvider() {
    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final summariesJson = prefs.getStringList('study_summaries') ?? [];

      _summaries.clear();
      for (String summaryJson in summariesJson) {
        final summary = StudySummary.fromJson(jsonDecode(summaryJson));
        _summaries.add(summary);
      }

      // Sort by creation date, newest first
      _summaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading summaries: $e');
      }
    }
  }

  Future<void> _saveSummaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final summariesJson = _summaries
          .map((summary) => jsonEncode(summary.toJson()))
          .toList();
      await prefs.setStringList('study_summaries', summariesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving summaries: $e');
      }
    }
  }

  Future<StudySummary?> generateSummary(String content, String subject) async {
    if (content
        .trim()
        .isEmpty) {
      _error = 'Please enter some content to summarize';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final summary = await _aiService.summarizeContent(content, subject);

      // Add to local list
      _summaries.insert(0, summary);

      // Save to local storage
      await _saveSummaries();

      _isLoading = false;
      notifyListeners();

      return summary;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteSummary(String id) async {
    _summaries.removeWhere((summary) => summary.id == id);
    await _saveSummaries();
    notifyListeners();
  }

  Future<void> deleteAllSummaries() async {
    _summaries.clear();
    await _saveSummaries();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get summaries by subject
  List<StudySummary> getSummariesBySubject(String subject) {
    return _summaries.where((summary) => summary.subject == subject).toList();
  }

  // Get recent summaries (last 7 days)
  List<StudySummary> getRecentSummaries() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _summaries
        .where((summary) => summary.createdAt.isAfter(weekAgo))
        .toList();
  }
}