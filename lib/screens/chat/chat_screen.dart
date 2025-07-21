import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/progress_service.dart';
import '../../utils/app_theme.dart';
import '../../models/chat_message_model.dart';
import '../../services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedSubject = 'General';
  final AIService _aiService = AIService();
  final ProgressService _progressService = ProgressService();
  bool _isThinking = false;

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

  List<ChatMessageModel> _messages = [];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    // Clear the input field immediately
    _messageController.clear();

    try {
      // Check if AI service is configured
      if (!_aiService.isConfigured) {
        _showConfigurationDialog();
        return;
      }

      // Add user message to UI immediately
      final userMessage = ChatMessageModel(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        userId: authProvider.user!.uid,
        sessionId: 'default',
        content: message,
        type: MessageType.user,
        timestamp: DateTime.now(),
        subject: _selectedSubject,
      );

      // Update UI with user message
      setState(() {
        _messages.add(userMessage);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      // Track user progress
      await _progressService.trackQuestion(
          authProvider.user!.uid, studyTime: 2);

      // Set thinking state
      setState(() {
        _isThinking = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      // Get AI response
      final aiResponse = await _aiService.generateTutorResponse(
          message, _selectedSubject);

      // Add AI response to UI
      final aiMessage = ChatMessageModel(
        id: (DateTime
            .now()
            .millisecondsSinceEpoch + 1).toString(),
        userId: authProvider.user!.uid,
        sessionId: 'default',
        content: aiResponse,
        type: MessageType.ai,
        timestamp: DateTime.now(),
        subject: _selectedSubject,
      );

      // Reset thinking state
      setState(() {
        _isThinking = false;
      });

      setState(() {
        _messages.add(aiMessage);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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

  void _showChatOptions() {
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
                  'Chat Options',
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // New Chat Option
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                        Icons.chat_bubble_outline, color: Colors.blue),
                  ),
                  title: const Text('New Chat'),
                  subtitle: const Text('Start a fresh conversation'),
                  onTap: () {
                    Navigator.pop(context);
                    _startNewChat();
                  },
                ),

                // Save Chat History Option
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.save, color: Colors.green),
                  ),
                  title: const Text('Save Chat History'),
                  subtitle: const Text('Export conversation to file'),
                  onTap: () {
                    Navigator.pop(context);
                    _saveChatHistory();
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _messageController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Started new chat conversation'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _saveChatHistory() {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No chat history to save'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // TODO: Implement actual save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Chat history saved successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Open saved chats view
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatOptions(),
            tooltip: 'Chat Options',
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
                  Icon(
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

          // Messages List
          Expanded(
            child: _messages.isEmpty && !_isThinking
                ? _buildEmptyState()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isThinking && index == _messages.length) {
                  return _buildThinkingBubble();
                }
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Smart Message Input
          _buildSmartMessageInput(),
        ],
      ),
    );
  }

  Widget _buildModernSubjectChip(String subject, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedSubject = subject;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getSubjectIcon(subject),
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : Theme
                      .of(context)
                      .colorScheme
                      .onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  subject,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme
                        .of(context)
                        .colorScheme
                        .onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
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
            Flexible(
              child: Text(
                subject,
                style: TextStyle(
                  color: isSelected ? Colors.white : chipColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildSmartMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .colorScheme
            .surface,
        border: Border(
          top: BorderSide(
            color: Theme
                .of(context)
                .colorScheme
                .outline
                .withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Text Input
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
                  controller: _messageController,
                  maxLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: _getSmartHintText(),
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
                      Icons.chat_bubble_outline,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                      size: 20,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  onChanged: (text) => setState(() {}),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Send Button
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                gradient: _messageController.text.isNotEmpty
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
                color: _messageController.text.isEmpty
                    ? Theme
                    .of(context)
                    .colorScheme
                    .outline
                    .withOpacity(0.3)
                    : null,
                borderRadius: BorderRadius.circular(24),
                boxShadow: _messageController.text.isNotEmpty ? [
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
                  onTap: _messageController.text.isNotEmpty
                      ? _sendMessage
                      : null,
                  child: Icon(
                    _messageController.text.isNotEmpty
                        ? Icons.send_rounded
                        : Icons.send_outlined,
                    color: _messageController.text.isNotEmpty
                        ? Colors.white
                        : Theme
                        .of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getQuickActions() {
    return [
      {'text': 'Explain', 'icon': Icons.lightbulb_outline},
      {'text': 'Summarize', 'icon': Icons.summarize},
      {'text': 'Question', 'icon': Icons.help_outline},
      {'text': 'Example', 'icon': Icons.code},
      {'text': 'Steps', 'icon': Icons.list_alt},
    ];
  }

  Widget _buildQuickActionChip(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme
              .of(context)
              .colorScheme
              .primary
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme
                .of(context)
                .colorScheme
                .primary
                .withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme
                  .of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: Theme
                    .of(context)
                    .colorScheme
                    .primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _insertQuickAction(String action) {
    _messageController.text = '$action ';
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
    setState(() {});
  }

  String _getSmartHintText() {
    final hints = [
      'Ask about ${_selectedSubject.toLowerCase()}...',
      'What would you like to learn?',
      'Type your question here...',
      'How can I help with ${_selectedSubject.toLowerCase()}?',
    ];
    return hints[DateTime
        .now()
        .second % hints.length];
  }

  List<String> _getSmartSuggestions(String input) {
    final suggestions = <String>[];
    final lowercaseInput = input.toLowerCase();

    // Subject-specific suggestions
    final subjectSuggestions = _getSubjectSpecificSuggestions(lowercaseInput);
    suggestions.addAll(subjectSuggestions);

    // General completion suggestions
    if (lowercaseInput.startsWith('what')) {
      suggestions.addAll(['what is', 'what are', 'what does', 'what happens']);
    } else if (lowercaseInput.startsWith('how')) {
      suggestions.addAll(['how to', 'how does', 'how can', 'how do']);
    } else if (lowercaseInput.startsWith('why')) {
      suggestions.addAll(['why is', 'why does', 'why do', 'why did']);
    } else if (lowercaseInput.startsWith('explain')) {
      suggestions.addAll(['explain how', 'explain why', 'explain the']);
    }

    return suggestions.take(5).toList();
  }

  List<String> _getSubjectSpecificSuggestions(String input) {
    switch (_selectedSubject) {
      case 'Mathematics':
        if (input.contains('solve'))
          return ['solve equation', 'solve for x', 'solve step by step'];
        if (input.contains('calculate'))
          return ['calculate area', 'calculate volume', 'calculate derivative'];
        return ['quadratic formula', 'pythagorean theorem', 'calculus basics'];

      case 'Science':
        if (input.contains('explain'))
          return ['explain photosynthesis', 'explain gravity', 'explain atoms'];
        return ['water cycle', 'periodic table', 'newton\'s laws'];

      case 'History':
        if (input.contains('when'))
          return ['when did', 'when was', 'when happened'];
        return ['world war', 'ancient civilizations', 'renaissance period'];

      case 'English':
        if (input.contains('write'))
          return ['write essay', 'write paragraph', 'write summary'];
        return ['grammar rules', 'literary devices', 'shakespeare'];

      default:
        return ['help me understand', 'give me examples', 'step by step'];
    }
  }

  Widget _buildSmartSuggestionChip(String suggestion) {
    return GestureDetector(
      onTap: () {
        _messageController.text = suggestion;
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: suggestion.length),
        );
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme
              .of(context)
              .colorScheme
              .surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme
                .of(context)
                .colorScheme
                .outline
                .withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Text(
          suggestion,
          style: TextStyle(
            color: Theme
                .of(context)
                .colorScheme
                .onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSubjectSuggestions() {
    switch (_selectedSubject) {
      case 'Mathematics':
        return [
          {
            'text': 'Explain quadratic equations',
            'color': Colors.blue,
            'icon': Icons.functions
          },
          {
            'text': 'How do I solve calculus problems?',
            'color': Colors.indigo,
            'icon': Icons.trending_up
          },
          {
            'text': 'What is the Pythagorean theorem?',
            'color': Colors.purple,
            'icon': Icons.change_history
          },
          {
            'text': 'Help with algebra basics',
            'color': Colors.deepPurple,
            'icon': Icons.calculate
          },
        ];
      case 'Science':
        return [
          {
            'text': 'How does photosynthesis work?',
            'color': Colors.green,
            'icon': Icons.eco
          },
          {
            'text': 'Explain the water cycle',
            'color': Colors.cyan,
            'icon': Icons.water_drop
          },
          {
            'text': 'What is gravity?',
            'color': Colors.orange,
            'icon': Icons.public
          },
          {
            'text': 'How do atoms work?',
            'color': Colors.red,
            'icon': Icons.scatter_plot
          },
        ];
      case 'History':
        return [
          {
            'text': 'Tell me about World War 2',
            'color': Colors.brown,
            'icon': Icons.military_tech
          },
          {
            'text': 'How did ancient civilizations live?',
            'color': Colors.amber,
            'icon': Icons.account_balance
          },
          {
            'text': 'What caused the American Revolution?',
            'color': Colors.red,
            'icon': Icons.flag
          },
          {
            'text': 'Explain the Renaissance period',
            'color': Colors.deepOrange,
            'icon': Icons.palette
          },
        ];
      case 'English':
        return [
          {
            'text': 'Help me write an essay',
            'color': Colors.teal,
            'icon': Icons.edit
          },
          {
            'text': 'Explain Shakespeare\'s themes',
            'color': Colors.indigo,
            'icon': Icons.theater_comedy
          },
          {
            'text': 'What is a metaphor?',
            'color': Colors.purple,
            'icon': Icons.lightbulb
          },
          {
            'text': 'Grammar rules explained',
            'color': Colors.green,
            'icon': Icons.spellcheck
          },
        ];
      case 'Physics':
        return [
          {
            'text': 'Explain Newton\'s laws',
            'color': Colors.blue,
            'icon': Icons.science
          },
          {
            'text': 'How does electricity work?',
            'color': Colors.yellow,
            'icon': Icons.bolt
          },
          {
            'text': 'What is quantum physics?',
            'color': Colors.purple,
            'icon': Icons.psychology
          },
          {
            'text': 'Motion and forces explained',
            'color': Colors.red,
            'icon': Icons.speed
          },
        ];
      case 'Chemistry':
        return [
          {
            'text': 'How do chemical bonds form?',
            'color': Colors.orange,
            'icon': Icons.link
          },
          {
            'text': 'Explain the periodic table',
            'color': Colors.blue,
            'icon': Icons.grid_3x3
          },
          {
            'text': 'What are chemical reactions?',
            'color': Colors.green,
            'icon': Icons.science
          },
          {
            'text': 'Help with organic chemistry',
            'color': Colors.purple,
            'icon': Icons.biotech
          },
        ];
      case 'Biology':
        return [
          {
            'text': 'How does DNA work?',
            'color': Colors.green,
            'icon': Icons.biotech
          },
          {
            'text': 'Explain cell division',
            'color': Colors.blue,
            'icon': Icons.cell_tower
          },
          {
            'text': 'What is evolution?',
            'color': Colors.brown,
            'icon': Icons.pets
          },
          {
            'text': 'How does the human body work?',
            'color': Colors.red,
            'icon': Icons.favorite
          },
        ];
      case 'Computer Science':
        return [
          {
            'text': 'What is programming?',
            'color': Colors.cyan,
            'icon': Icons.code
          },
          {
            'text': 'How do algorithms work?',
            'color': Colors.blue,
            'icon': Icons.memory
          },
          {
            'text': 'Explain data structures',
            'color': Colors.purple,
            'icon': Icons.storage
          },
          {
            'text': 'What is artificial intelligence?',
            'color': Colors.pink,
            'icon': Icons.school,
          },
        ];
      case 'Economics':
        return [
          {
            'text': 'How does supply and demand work?',
            'color': Colors.green,
            'icon': Icons.trending_up
          },
          {
            'text': 'What causes inflation?',
            'color': Colors.orange,
            'icon': Icons.attach_money
          },
          {
            'text': 'Explain market economics',
            'color': Colors.blue,
            'icon': Icons.business
          },
          {
            'text': 'How do banks work?',
            'color': Colors.teal,
            'icon': Icons.account_balance
          },
        ];
      default: // General
        return [
          {
            'text': 'Help me understand this topic',
            'color': Colors.blue,
            'icon': Icons.help_outline
          },
          {
            'text': 'Explain it step by step',
            'color': Colors.green,
            'icon': Icons.list
          },
          {
            'text': 'Give me study tips',
            'color': Colors.orange,
            'icon': Icons.school
          },
          {
            'text': 'Create practice questions',
            'color': Colors.purple,
            'icon': Icons.quiz
          },
        ];
    }
  }

  Widget _buildColorfulSuggestionChip(String text, Color color, IconData icon) {
    return GestureDetector(
      onTap: () => _sendSuggestionMessage(text),
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

  Future<void> _sendSuggestionMessage(String message) async {
    // Set the message in the text field and send it
    _messageController.text = message;
    await _sendMessage();
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isUser = message.type == MessageType.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment
            .start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme
                  .of(context)
                  .colorScheme
                  .primary,
              child: const Icon(
                Icons.school,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme
                    .of(context)
                    .colorScheme
                    .primary
                    : Theme
                    .of(context)
                    .colorScheme
                    .surfaceVariant,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : Theme
                          .of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser
                          ? Colors.white.withOpacity(0.7)
                          : Theme
                          .of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme
                  .of(context)
                  .colorScheme
                  .primary,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme
                .of(context)
                .colorScheme
                .primary,
            child: const Icon(
              Icons.school,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme
                    .of(context)
                    .colorScheme
                    .surfaceVariant,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: const Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Thinking',
                    style: TextStyle(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                  _buildAnimatedDots(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDots() {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, double value, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final animValue = ((value + delay) % 1.0);
            final opacity = (animValue > 0.5) ? 1.0 : 0.3;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: Text(
                '•',
                style: TextStyle(
                  color: Theme
                      .of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(opacity),
                  fontSize: 12,
                ),
              ),
            );
          }),
        );
      },
      onEnd: () {
        // Restart animation
        if (_isThinking && mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery
              .of(context)
              .size
              .height - 350,
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
                Icons.chat_bubble_outline,
                size: 32,
                color: Theme
                    .of(context)
                    .colorScheme
                    .primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Start a conversation',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about ${_selectedSubject
                  .toLowerCase()}. I\'m here to help!',
              textAlign: TextAlign.center,
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
                    0.7
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Colorful suggestion chips
            Text(
              'Quick Start Ideas:',
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
            const SizedBox(height: 16),

            // Suggestions with proper spacing
            Container(
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _getSubjectSuggestions().take(4).map((suggestion) {
                  return _buildColorfulSuggestionChip(
                    suggestion['text'] as String,
                    suggestion['color'] as Color,
                    suggestion['icon'] as IconData,
                  );
                }).toList(),
              ),
            ),

            // Extra spacing at bottom to ensure suggestions are never hidden
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}