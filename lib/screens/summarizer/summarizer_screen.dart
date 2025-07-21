import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../providers/summarizer_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/study_summary_model.dart';
import '../../models/flashcard_model.dart';
import '../../utils/app_theme.dart';

class SummarizerScreen extends StatefulWidget {
  const SummarizerScreen({super.key});

  @override
  State<SummarizerScreen> createState() => _SummarizerScreenState();
}

class _SummarizerScreenState extends State<SummarizerScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  late TabController _tabController;
  StudySummary? _currentSummary;

  final List<String> _commonSubjects = [
    'Mathematics',
    'Science',
    'History',
    'Literature',
    'Biology',
    'Chemistry',
    'Physics',
    'Psychology',
    'Computer Science',
    'Economics',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _subjectController.text = _commonSubjects.first;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _subjectController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Summarizer'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme
                  .of(context)
                  .colorScheme
                  .primary,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.withOpacity(Colors.black, 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.withOpacity(Colors.white, 0.7),
              tabs: const [
                Tab(text: 'Create Summary', icon: Icon(Icons.auto_awesome)),
                Tab(text: 'My Summaries', icon: Icon(Icons.library_books)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreateSummaryTab(),
                _buildMySummariesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateSummaryTab() {
    return Consumer<SummarizerProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subject',
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _subjectController.text,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.subject),
                        ),
                        items: _commonSubjects
                            .map((subject) =>
                            DropdownMenuItem(
                              value: subject,
                              child: Text(subject),
                            ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _subjectController.text = value;
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Content to Summarize',
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _contentController,
                        maxLines: 10,
                        decoration: InputDecoration(
                          hintText: 'Paste your study material here...\n\n'
                              'Examples:\n'
                              '• Chapter text from textbook\n'
                              '• Article content\n'
                              '• Lecture notes\n'
                              '• Research paper excerpts',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 200),
                            child: Icon(Icons.article),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (provider.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  provider.error!,
                                  style: const TextStyle(
                                      color: AppColors.error),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: provider.clearError,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: provider.isLoading
                              ? null
                              : () => _generateSummary(provider),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: provider.isLoading
                              ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('Generating Summary...'),
                            ],
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome),
                              const SizedBox(width: 8),
                              Text('Generate AI Summary'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_currentSummary != null) ...[
                const SizedBox(height: 16),
                _buildSummaryResult(_currentSummary!),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMySummariesTab() {
    return Consumer<SummarizerProvider>(
      builder: (context, provider, child) {
        if (provider.summaries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books,
                  size: 64,
                  color: Theme
                      .of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No summaries yet',
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first AI summary to see it here',
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                    color: AppTheme.withOpacity(
                      Theme
                          .of(context)
                          .colorScheme
                          .onSurface,
                      0.6,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text('Create Summary'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.summaries.length,
          itemBuilder: (context, index) {
            final summary = provider.summaries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(
                  summary.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.subject),
                    Text(
                      '${summary.mainTopics.length} topics • ${summary
                          .keyDefinitions.length} definitions',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) =>
                  [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 8),
                          Text('View'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'flashcards',
                      child: Row(
                        children: [
                          Icon(Icons.style),
                          SizedBox(width: 8),
                          Text('Create Flashcards'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _handleSummaryAction(value, summary),
                ),
                onTap: () => _viewSummary(summary),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryResult(StudySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    summary.title,
                    style: Theme
                        .of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .primary,
                    ),
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) =>
                  [
                    const PopupMenuItem(
                      value: 'flashcards',
                      child: Row(
                        children: [
                          Icon(Icons.style),
                          SizedBox(width: 8),
                          Text('Create Flashcards'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 8),
                          Text('Share'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _handleSummaryAction(value, summary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummarySection(
              'Main Topics',
              Icons.topic,
              summary.mainTopics.map((topic) => '• $topic').join('\n'),
            ),
            const SizedBox(height: 16),
            _buildSummarySection(
              'Key Definitions',
              Icons.book,
              summary.keyDefinitions.entries
                  .map((entry) => '• ${entry.key}: ${entry.value}')
                  .join('\n'),
            ),
            const SizedBox(height: 16),
            _buildSummarySection(
              'Important Facts',
              Icons.lightbulb,
              summary.importantFacts.map((fact) => '• $fact').join('\n'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme
                .of(context)
                .colorScheme
                .primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme
                .of(context)
                .colorScheme
                .surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.withOpacity(
                Theme
                    .of(context)
                    .colorScheme
                    .outline,
                0.2,
              ),
            ),
          ),
          child: Text(content),
        ),
      ],
    );
  }

  Future<void> _generateSummary(SummarizerProvider provider) async {
    if (_contentController.text
        .trim()
        .isEmpty) {
      provider.clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter content to summarize')),
      );
      return;
    }

    final summary = await provider.generateSummary(
      _contentController.text.trim(),
      _subjectController.text,
    );

    if (summary != null) {
      setState(() {
        _currentSummary = summary;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Summary generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleSummaryAction(String action, StudySummary summary) {
    switch (action) {
      case 'view':
        _viewSummary(summary);
        break;
      case 'flashcards':
        _createFlashcards(summary);
        break;
      case 'share':
        _shareSummary(summary);
        break;
      case 'delete':
        _deleteSummary(summary);
        break;
    }
  }

  void _viewSummary(StudySummary summary) {
    setState(() {
      _currentSummary = summary;
    });
    _tabController.animateTo(0);
  }

  void _createFlashcards(StudySummary summary) async {
    final flashcardProvider = context.read<FlashcardProvider>();

    // Get the current user ID (you'll need to get this from AuthProvider)
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to create flashcards'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create flashcards from key definitions
    int createdCount = 0;
    for (final entry in summary.keyDefinitions.entries) {
      try {
        await flashcardProvider.createFlashcard(
          entry.key,
          entry.value,
          summary.subject,
          userId,
        );
        createdCount++;
      } catch (e) {
        // Continue with other flashcards even if one fails
        continue;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Created $createdCount flashcards!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareSummary(StudySummary summary) {
    final text = '''
${summary.title}
Subject: ${summary.subject}

Main Topics:
${summary.mainTopics.map((topic) => '• $topic').join('\n')}

Key Definitions:
${summary.keyDefinitions.entries.map((entry) => '• ${entry.key}: ${entry
        .value}').join('\n')}

Important Facts:
${summary.importantFacts.map((fact) => '• $fact').join('\n')}

Generated by AI Study Buddy
''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Summary copied to clipboard!')),
    );
  }

  void _deleteSummary(StudySummary summary) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Summary'),
            content: Text(
                'Are you sure you want to delete "${summary.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  context.read<SummarizerProvider>().deleteSummary(summary.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Summary deleted')),
                  );
                },
                child: const Text(
                    'Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('How to Use AI Summarizer'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '1. Choose Subject',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                      'Select the subject area for better AI understanding.'),
                  const SizedBox(height: 12),
                  Text(
                    '2. Paste Content',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                      'Add your study material (articles, notes, chapters).'),
                  const SizedBox(height: 12),
                  Text(
                    '3. Generate Summary',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                      'AI will create structured notes with topics, definitions, and key facts.'),
                  const SizedBox(height: 12),
                  Text(
                    '4. Create Flashcards',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                      'Convert definitions into flashcards for study practice.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it!'),
              ),
            ],
          ),
    );
  }
}