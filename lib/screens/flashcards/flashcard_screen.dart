import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../services/ai_service.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with TickerProviderStateMixin {
  final AIService _aiService = AIService();
  final _topicController = TextEditingController();
  List<Flashcard> _flashcards = [];
  bool _isGenerating = false;
  String _selectedSubject = 'General';
  int _currentIndex = 0;
  bool _isFlipped = false;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

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
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _topicController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _generateFlashcard() async {
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
      final flashcardData = await _aiService.generateFlashcard(
          topic, _selectedSubject);

      final newFlashcard = Flashcard(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        question: flashcardData['question'] ?? 'Question',
        answer: flashcardData['answer'] ?? 'Answer',
        subject: _selectedSubject,
        topic: topic,
        createdAt: DateTime.now(),
      );

      setState(() {
        _flashcards.add(newFlashcard);
        _currentIndex = _flashcards.length - 1;
        _isFlipped = false;
        _flipController.reset();
      });

      _topicController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flashcard generated successfully!')),
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

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _nextCard() {
    if (_currentIndex < _flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _flipController.reset();
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
        _flipController.reset();
      });
    }
  }

  void _deleteCard(int index) {
    setState(() {
      _flashcards.removeAt(index);
      if (_currentIndex >= _flashcards.length && _flashcards.isNotEmpty) {
        _currentIndex = _flashcards.length - 1;
      }
      if (_flashcards.isEmpty) {
        _currentIndex = 0;
      }
      _isFlipped = false;
      _flipController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedSubject = value;
              });
            },
            itemBuilder: (context) =>
                _subjects
                    .map((subject) =>
                    PopupMenuItem(
                      value: subject,
              child: Text(subject),
            ))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text(
                  _selectedSubject,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Theme
                    .of(context)
                    .colorScheme
                    .primaryContainer,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Configuration Status Banner
          if (!_aiService.isConfigured)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppTheme.withOpacity(Colors.orange, 0.1),
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

          // Generation Form
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _topicController,
                        decoration: InputDecoration(
                          hintText: 'Enter a topic to generate flashcard...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lightbulb_outline),
                        ),
                        onSubmitted: (_) => _generateFlashcard(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isGenerating ? null : _generateFlashcard,
                      child: _isGenerating
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Generate'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Flashcard Display
          Expanded(
            child: _flashcards.isEmpty
                ? _buildEmptyState()
                : _buildFlashcardView(),
          ),

          // Navigation Controls
          if (_flashcards.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Card counter
                  Text(
                    '${_currentIndex + 1} of ${_flashcards.length}',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: AppTheme.withOpacity(
                          Theme
                              .of(context)
                              .colorScheme
                              .onSurface, 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: _currentIndex > 0 ? _previousCard : null,
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: _currentIndex > 0
                              ? Theme
                              .of(context)
                              .colorScheme
                              .primaryContainer
                              : Theme
                              .of(context)
                              .colorScheme
                              .surfaceVariant,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _flipCard,
                        icon: Icon(_isFlipped ? Icons.visibility_off : Icons
                            .visibility),
                        label: Text(
                            _isFlipped ? 'Show Question' : 'Show Answer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme
                              .of(context)
                              .colorScheme
                              .primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _currentIndex < _flashcards.length - 1
                            ? _nextCard
                            : null,
                        icon: const Icon(Icons.arrow_forward),
                        style: IconButton.styleFrom(
                          backgroundColor: _currentIndex <
                              _flashcards.length - 1
                              ? Theme
                              .of(context)
                              .colorScheme
                              .primaryContainer
                              : Theme
                              .of(context)
                              .colorScheme
                              .surfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.withOpacity(Theme
                    .of(context)
                    .colorScheme
                    .primary, 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.style,
                size: 40,
                color: Theme
                    .of(context)
                    .colorScheme
                    .primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No flashcards yet',
              style: Theme
                  .of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate your first flashcard by entering a topic above',
              textAlign: TextAlign.center,
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(
                color: AppTheme.withOpacity(
                    Theme
                        .of(context)
                        .colorScheme
                        .onSurface, 0.7),
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestionChip('Photosynthesis'),
                _buildSuggestionChip('Quadratic equations'),
                _buildSuggestionChip('World War 2'),
                _buildSuggestionChip('Shakespeare'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _topicController.text = text;
      },
      backgroundColor: AppTheme.withOpacity(Theme
          .of(context)
          .colorScheme
          .primary, 0.1),
    );
  }

  Widget _buildFlashcardView() {
    final flashcard = _flashcards[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Subject and topic info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme
                  .of(context)
                  .colorScheme
                  .surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.subject,
                  size: 16,
                  color: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${flashcard.subject} • ${flashcard.topic}',
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 16),
                  itemBuilder: (context) =>
                  [
                    PopupMenuItem(
                      value: 'delete',
                      child: const Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteCard(_currentIndex);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Flashcard
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final isShowingFront = _flipAnimation.value < 0.5;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_flipAnimation.value * 3.14159),
                    child: Card(
                      elevation: 8,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isShowingFront
                                ? [
                              Theme
                                  .of(context)
                                  .colorScheme
                                  .primary,
                              Theme
                                  .of(context)
                                  .colorScheme
                                  .secondary,
                            ]
                                : [
                              Theme
                                  .of(context)
                                  .colorScheme
                                  .tertiary,
                              Theme
                                  .of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isShowingFront ? Icons.help_outline : Icons
                                  .lightbulb,
                              size: 32,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isShowingFront ? 'Question' : 'Answer',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..rotateY(isShowingFront ? 0 : 3.14159),
                              child: Text(
                                isShowingFront ? flashcard.question : flashcard
                                    .answer,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to ${isShowingFront
                                  ? 'reveal answer'
                                  : 'show question'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String subject;
  final String topic;
  final DateTime createdAt;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.subject,
    required this.topic,
    required this.createdAt,
  });
}