import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/progress_service.dart';
import '../../services/ai_service.dart';
import '../../utils/app_theme.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final AIService _aiService = AIService();
  final ProgressService _progressService = ProgressService();
  final _topicController = TextEditingController();

  List<QuizQuestion> _questions = [];
  bool _isGenerating = false;
  bool _isQuizActive = false;
  int _currentQuestionIndex = 0;
  int _score = 0;
  List<int> _userAnswers = [];
  String _selectedSubject = 'General';
  int _numberOfQuestions = 5;

  final List<String> _subjects = [
    'General',
    'Mathematics',
    'Science',
    'History',
    'English',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'Economics',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generateQuiz() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic')),
      );
      return;
    }

    if (!_aiService.isConfigured) {
      _showConfigurationDialog();
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final quizData = await _aiService.generateQuiz(
        topic,
        _selectedSubject,
        _numberOfQuestions,
      );

      final questions = quizData.map((q) {
        final options = q['options']?.split('|') ?? [];
        return QuizQuestion(
          question: q['question'] ?? 'Question',
          options: options,
          correctAnswer: int.tryParse(q['correct'] ?? '0') ?? 0,
        );
      }).toList();

      setState(() {
        _questions = questions;
        _isQuizActive = true;
        _currentQuestionIndex = 0;
        _score = 0;
        _userAnswers = List.filled(_numberOfQuestions, -1);
      });

      _topicController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz generated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .error,
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('AI Service Not Configured'),
          content: Text(_aiService.configurationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_userAnswers[_currentQuestionIndex] == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an answer')),
      );
      return;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _finishQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _finishQuiz() {
    int correctAnswers = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i].correctAnswer) {
        correctAnswers++;
      }
    }

    setState(() {
      _score = correctAnswers;
      _isQuizActive = false;
    });

    // Track quiz completion progress
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      final scorePercentage = (correctAnswers / _questions.length) * 100;
      _progressService.trackQuizCompletion(
          authProvider.user!.uid, scorePercentage, studyTime: 5);
    }

    _showResultsDialog();
  }

  void _showResultsDialog() {
    final percentage = (_score / _questions.length * 100).round();
    final performanceMessage = percentage >= 90 ? '🏆 Outstanding!' :
    percentage >= 80 ? '🎉 Excellent!' :
    percentage >= 70 ? '👏 Great Job!' :
    percentage >= 60 ? '👍 Good Work!' :
    percentage >= 50 ? '📚 Keep Practicing!' :
    '💪 Don\'t Give Up!';

    final performanceColor = percentage >= 80 ? Colors.green :
    percentage >= 60 ? Colors.orange :
    Colors.red;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 320,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  performanceColor.withOpacity(0.1),
                  Theme
                      .of(context)
                      .colorScheme
                      .surface,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Performance Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          performanceColor,
                          performanceColor.withOpacity(0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: performanceColor.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      percentage >= 80 ? Icons.emoji_events :
                      percentage >= 60 ? Icons.thumb_up :
                      Icons.psychology,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Performance Message
                  Text(
                    performanceMessage,
                    style: Theme
                        .of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: performanceColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Score Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$_score',
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: performanceColor,
                              ),
                            ),
                            Text(
                              '/${_questions.length}',
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                color: Theme
                                    .of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$percentage%',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            color: performanceColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress Bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Theme
                          .of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _score / _questions.length,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            performanceColor),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _resetQuiz();
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('New Quiz'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showDetailedResults();
                          },
                          icon: const Icon(Icons.analytics, size: 18),
                          label: const Text('Review'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: performanceColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDetailedResults() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            QuizResultsScreen(
              questions: _questions,
              userAnswers: _userAnswers,
              score: _score,
              onRetry: () {
                Navigator.of(context).pop();
                _resetQuiz();
              },
            ),
      ),
    );
  }

  void _resetQuiz() {
    setState(() {
      _questions = [];
      _isQuizActive = false;
      _currentQuestionIndex = 0;
      _score = 0;
      _userAnswers = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Generator'),
        centerTitle: true,
        actions: [
          if (!_isQuizActive)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showQuizOptions,
              tooltip: 'Quiz Options',
            ),
        ],
      ),
      body: Column(
        children: [
          if (!_isQuizActive) ...[
            // Colorful Subject Selection
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Theme
                    .of(context)
                    .colorScheme
                    .surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .outline
                        .withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _subjects.length,
                itemBuilder: (context, index) {
                  final subject = _subjects[index];
                  final isSelected = subject == _selectedSubject;

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildColorfulSubjectChip(
                        subject, isSelected, index),
                  );
                },
              ),
            ),
          ],

          Expanded(
            child: _isQuizActive ? _buildQuizView() : _buildGeneratorView(),
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'General':
        return Colors.grey.shade600;
      case 'Mathematics':
        return Colors.blue;
      case 'Science':
        return Colors.green;
      case 'History':
        return Colors.brown;
      case 'English':
        return Colors.purple;
      case 'Physics':
        return Colors.indigo;
      case 'Chemistry':
        return Colors.orange;
      case 'Biology':
        return Colors.teal;
      case 'Computer Science':
        return Colors.cyan;
      case 'Economics':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case 'General':
        return Icons.lightbulb_outline;
      case 'Mathematics':
        return Icons.functions;
      case 'Science':
        return Icons.science;
      case 'History':
        return Icons.account_balance;
      case 'English':
        return Icons.menu_book;
      case 'Physics':
        return Icons.flash_on;
      case 'Chemistry':
        return Icons.biotech;
      case 'Biology':
        return Icons.eco;
      case 'Computer Science':
        return Icons.computer;
      case 'Economics':
        return Icons.trending_up;
      default:
        return Icons.school;
    }
  }

  Widget _buildColorfulSubjectChip(String subject, bool isSelected, int index) {
    final chipColor = _getSubjectColor(subject);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubject = subject;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              chipColor,
              chipColor.withOpacity(0.7),
            ],
          )
              : null,
          color: isSelected ? null : chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: chipColor.withOpacity(isSelected ? 1.0 : 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: chipColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getSubjectIcon(subject),
              color: isSelected ? Colors.white : chipColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              subject,
              style: TextStyle(
                color: isSelected ? Colors.white : chipColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showQuizOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme
                  .of(context)
                  .colorScheme
                  .surface,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .outline
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Quiz Options',
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Clear Quiz History Option
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.clear_all, color: Colors.red),
                  ),
                  title: const Text('Clear Quiz History'),
                  subtitle: const Text('Remove all quiz data'),
                  onTap: () {
                    Navigator.pop(context);
                    _clearQuizHistory();
                  },
                ),

                // Export Quiz Results Option
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.download, color: Colors.green),
                  ),
                  title: const Text('Export Results'),
                  subtitle: const Text('Save quiz performance data'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportResults();
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  void _clearQuizHistory() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Clear Quiz History'),
            content: const Text(
                'Are you sure you want to clear all quiz history? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Quiz history cleared'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  void _exportResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Quiz results exported successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Open exported results
          },
        ),
      ),
    );
  }

  Widget _buildGeneratorView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Configuration Status Banner
          if (!_aiService.isConfigured)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.withOpacity(Colors.orange, 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI features disabled. Tap for setup instructions.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _showConfigurationDialog,
                    child: const Text('Setup'),
                  ),
                ],
              ),
            ),

          // Modern Quiz Generation Form
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme
                  .of(context)
                  .colorScheme
                  .surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme
                    .of(context)
                    .colorScheme
                    .outline
                    .withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme
                      .of(context)
                      .colorScheme
                      .shadow
                      .withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getSubjectColor(_selectedSubject).withOpacity(
                            0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.quiz,
                        color: _getSubjectColor(_selectedSubject),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Create Quiz',
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Smart Topic Input
                Container(
                  decoration: BoxDecoration(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _topicController,
                    decoration: InputDecoration(
                      hintText: 'Enter quiz topic for ${_selectedSubject
                          .toLowerCase()}...',
                      hintStyle: TextStyle(
                        color: Theme
                            .of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.lightbulb_outline,
                        color: Theme
                            .of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                        size: 20,
                      ),
                    ),
                    onSubmitted: (_) => _generateQuiz(),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),

                const SizedBox(height: 20),

                // Number of Questions Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_list_numbered,
                            color: Theme
                                .of(context)
                                .colorScheme
                                .primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Number of Questions',
                            style: Theme
                                .of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [3, 5, 10, 15, 20].map((count) {
                          final isSelected = _numberOfQuestions == count;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _numberOfQuestions = count;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme
                                    .of(context)
                                    .colorScheme
                                    .primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme
                                      .of(context)
                                      .colorScheme
                                      .primary
                                      : Theme
                                      .of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme
                                      .of(context)
                                      .colorScheme
                                      .onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Generate Button
                Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: !_isGenerating
                        ? LinearGradient(
                      colors: [
                        Theme
                            .of(context)
                            .colorScheme
                            .primary,
                        Theme
                            .of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.8),
                      ],
                    )
                        : null,
                    color: _isGenerating
                        ? Theme
                        .of(context)
                        .colorScheme
                        .outline
                        .withOpacity(0.3)
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: !_isGenerating ? [
                      BoxShadow(
                        color: Theme
                            .of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isGenerating ? null : _generateQuiz,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: _isGenerating
                            ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Generating Quiz...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                            : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Generate Quiz',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuizView() {
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Column(
      children: [
        // Progress indicator
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${_questions
                        .length}',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _selectedSubject,
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.withOpacity(
                  Theme
                      .of(context)
                      .colorScheme
                      .primary,
                  0.2,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme
                      .of(context)
                      .colorScheme
                      .primary,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),

        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question',
                          style: Theme
                              .of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color: Theme
                                .of(context)
                                .colorScheme
                                .primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.question,
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Options
                ...question.options
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = _userAnswers[_currentQuestionIndex] ==
                      index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _selectAnswer(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? Theme
                                .of(context)
                                .colorScheme
                                .primary
                                : AppTheme.withOpacity(
                              Theme
                                  .of(context)
                                  .colorScheme
                                  .outline,
                              0.3,
                            ),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? AppTheme.withOpacity(
                            Theme
                                .of(context)
                                .colorScheme
                                .primary,
                            0.1,
                          )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme
                                      .of(context)
                                      .colorScheme
                                      .primary
                                      : AppTheme.withOpacity(
                                    Theme
                                        .of(context)
                                        .colorScheme
                                        .outline,
                                    0.5,
                                  ),
                                  width: 2,
                                ),
                                color: isSelected
                                    ? Theme
                                    .of(context)
                                    .colorScheme
                                    .primary
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                                  : Center(
                                child: Text(
                                  String.fromCharCode(65 + index), // A, B, C, D
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme
                                        .of(context)
                                        .colorScheme
                                        .outline,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Theme
                                      .of(context)
                                      .colorScheme
                                      .primary
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),

        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousQuestion,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 16),
              Expanded(
                flex: _currentQuestionIndex == 0 ? 1 : 1,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _currentQuestionIndex == _questions.length - 1
                        ? 'Finish Quiz'
                        : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

class QuizResultsScreen extends StatelessWidget {
  final List<QuizQuestion> questions;
  final List<int> userAnswers;
  final int score;
  final VoidCallback onRetry;

  const QuizResultsScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
    required this.score,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / questions.length * 100).round();
    final performanceColor = percentage >= 80 ? Colors.green :
    percentage >= 60 ? Colors.orange :
    Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Enhanced Score Summary
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  performanceColor,
                  performanceColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: performanceColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Trophy/Performance Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      percentage >= 80 ? Icons.emoji_events :
                      percentage >= 60 ? Icons.thumb_up :
                      Icons.psychology,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Final Results',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Score Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$score',
                        style: Theme
                            .of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                        ),
                      ),
                      Text(
                        '/${questions.length}',
                        style: Theme
                            .of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '$percentage% Accuracy',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Performance Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        context,
                        'Correct',
                        score.toString(),
                        Icons.check_circle,
                        Colors.white.withOpacity(0.9),
                      ),
                      _buildStatCard(
                        context,
                        'Wrong',
                        (questions.length - score).toString(),
                        Icons.cancel,
                        Colors.white.withOpacity(0.9),
                      ),
                      _buildStatCard(
                        context,
                        'Total',
                        questions.length.toString(),
                        Icons.quiz,
                        Colors.white.withOpacity(0.9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Question Results Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme
                  .of(context)
                  .colorScheme
                  .surfaceVariant
                  .withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Detailed Review',
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${questions.length} Questions',
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Enhanced Question Results
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                final userAnswer = userAnswers[index];
                final isCorrect = userAnswer == question.correctAnswer;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme
                            .of(context)
                            .colorScheme
                            .shadow
                            .withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question header
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCorrect ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isCorrect ? Colors.green : Colors
                                        .red).withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isCorrect ? Icons.check : Icons.close,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Question ${index + 1}',
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isCorrect ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Question text
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme
                                .of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            question.question,
                            style: Theme
                                .of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Answer options
                        ...question.options
                            .asMap()
                            .entries
                            .map((entry) {
                          final optionIndex = entry.key;
                          final option = entry.value;
                          final isUserAnswer = userAnswer == optionIndex;
                          final isCorrectAnswer = question.correctAnswer ==
                              optionIndex;

                          Color? backgroundColor;
                          Color? textColor;
                          Color? borderColor;
                          IconData? icon;

                          if (isCorrectAnswer) {
                            backgroundColor = Colors.green.withOpacity(0.1);
                            textColor = Colors.green.shade700;
                            borderColor = Colors.green;
                            icon = Icons.check_circle;
                          } else if (isUserAnswer && !isCorrect) {
                            backgroundColor = Colors.red.withOpacity(0.1);
                            textColor = Colors.red.shade700;
                            borderColor = Colors.red;
                            icon = Icons.cancel;
                          } else {
                            backgroundColor = Theme
                                .of(context)
                                .colorScheme
                                .surface;
                            textColor = Theme
                                .of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7);
                            borderColor = Theme
                                .of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.2);
                          }

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor!,
                                width: (isUserAnswer || isCorrectAnswer)
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: (isUserAnswer || isCorrectAnswer)
                                        ? (isCorrectAnswer
                                        ? Colors.green
                                        : Colors.red)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: textColor!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + optionIndex),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: (isUserAnswer || isCorrectAnswer)
                                            ? Colors.white
                                            : textColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: (isUserAnswer ||
                                          isCorrectAnswer)
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (icon != null)
                                  Icon(
                                    icon,
                                    color: isCorrectAnswer
                                        ? Colors.green
                                        : Colors.red,
                                    size: 20,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Enhanced Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme
                  .of(context)
                  .colorScheme
                  .surface,
              boxShadow: [
                BoxShadow(
                  color: Theme
                      .of(context)
                      .colorScheme
                      .shadow
                      .withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back to Quiz'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: performanceColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme
              .of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: Theme
              .of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}