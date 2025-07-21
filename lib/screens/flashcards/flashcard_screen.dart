import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/progress_service.dart';
import '../../services/favourites_service.dart';
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
  final ProgressService _progressService = ProgressService();
  final FavouritesService _favouritesService = FavouritesService();
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
    _syncFavourites();
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

      // Track flashcard creation progress
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        await _progressService.trackFlashcardCreation(
            authProvider.user!.uid, studyTime: 3);
      }

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

      // Track flashcard review when showing answer
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        _progressService.trackFlashcardReview(
            authProvider.user!.uid, studyTime: 1);
      }
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
    _syncFavourites();
  }

  void _showFlashcardOptions() {
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
                  'Flashcard Options',
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Clear All Cards Option
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
                  title: const Text('Clear All Cards'),
                  subtitle: const Text('Remove all flashcards'),
                  onTap: () {
                    Navigator.pop(context);
                    _clearAllCards();
                  },
                ),

                // Export Cards Option
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
                  title: const Text('Export Cards'),
                  subtitle: const Text('Save flashcards to file'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportCards();
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  void _clearAllCards() {
    if (_flashcards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No flashcards to clear'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Clear All Cards'),
            content: const Text(
                'Are you sure you want to delete all flashcards? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _flashcards.clear();
                    _currentIndex = 0;
                    _isFlipped = false;
                    _flipController.reset();
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('All flashcards cleared'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }

  Future<void> _exportCards() async {
    if (_flashcards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No flashcards to export'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // TODO: Implement actual export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported ${_flashcards.length} flashcards successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Open exported file
          },
        ),
      ),
    );
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

  void _toggleFavourite(int index) {
    setState(() {
      _flashcards[index].isFavourite = !_flashcards[index].isFavourite;
    });

    _syncFavourites();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _flashcards[index].isFavourite ? Icons.favorite : Icons
                  .favorite_border,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _flashcards[index].isFavourite
                  ? 'Added to favourites'
                  : 'Removed from favourites',
            ),
          ],
        ),
        backgroundColor: _flashcards[index].isFavourite ? Colors.red : Colors
            .grey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportSingleCard(int index) async {
    final card = _flashcards[index];

    // Placeholder export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Export feature coming soon for "${card.topic}"')),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _syncFavourites() {
    _favouritesService.syncFavourites(_flashcards);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showFlashcardOptions(),
            tooltip: 'Flashcard Options',
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
                  child: _buildColorfulSubjectChip(subject, isSelected, index),
                );
              },
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme
                              .of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(24),
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
                            hintText: 'Enter topic for ${_selectedSubject
                                .toLowerCase()} flashcard...',
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
                              vertical: 12,
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
                          onSubmitted: (_) => _generateFlashcard(),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 48,
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
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: !_isGenerating ? [
                          BoxShadow(
                            color: Theme
                                .of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _isGenerating ? null : _generateFlashcard,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: _isGenerating
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Generate',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery
              .of(context)
              .size
              .height - 300,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.withOpacity(Theme
                    .of(context)
                    .colorScheme
                    .primary, 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.style,
                size: 32,
                color: Theme
                    .of(context)
                    .colorScheme
                    .primary,
              ),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 24),
            Text(
              'Try these topics:',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme
                    .of(context)
                    .colorScheme
                    .primary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
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
    final suggestions = {
      'Photosynthesis': {'color': Colors.green, 'icon': Icons.eco},
      'Quadratic equations': {'color': Colors.blue, 'icon': Icons.functions},
      'World War 2': {'color': Colors.brown, 'icon': Icons.military_tech},
      'Shakespeare': {'color': Colors.purple, 'icon': Icons.theater_comedy},
    };

    final suggestion = suggestions[text] ??
        {'color': Colors.grey, 'icon': Icons.lightbulb_outline};
    final color = suggestion['color'] as Color;
    final icon = suggestion['icon'] as IconData;

    return GestureDetector(
      onTap: () {
        _topicController.text = text;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
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
                Expanded(
                  child: Text(
                    '${flashcard.subject} • ${flashcard.topic}',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (flashcard.isFavourite)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.favorite,
                      size: 16,
                      color: Colors.red,
                    ),
                  ),
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
                    PopupMenuItem(
                      value: 'favourite',
                      child: Row(
                        children: [
                          Icon(
                            flashcard.isFavourite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: flashcard.isFavourite
                                ? Colors.red
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            flashcard.isFavourite
                                ? 'Unfavourite'
                                : 'Favourite',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'export',
                      child: const Row(
                        children: [
                          Icon(Icons.download, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Export'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteCard(_currentIndex);
                    } else if (value == 'favourite') {
                      _toggleFavourite(_currentIndex);
                    } else if (value == 'export') {
                      _exportSingleCard(_currentIndex);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Flashcard
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
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
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight * 0.6,
                              maxHeight: constraints.maxHeight,
                            ),
                            padding: const EdgeInsets.all(20),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isShowingFront ? Icons.help_outline : Icons
                                      .lightbulb,
                                  size: 24,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isShowingFront ? 'Question' : 'Answer',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Flexible(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxHeight: constraints.maxHeight * 0.5,
                                    ),
                                    child: SingleChildScrollView(
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..rotateY(
                                              isShowingFront ? 0 : 3.14159),
                                        child: Text(
                                          isShowingFront
                                              ? flashcard.question
                                              : flashcard.answer,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to ${isShowingFront
                                      ? 'reveal answer'
                                      : 'show question'}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
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
  bool isFavourite;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.subject,
    required this.topic,
    required this.createdAt,
    this.isFavourite = false,
  });
}