import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/voice_provider.dart';
import '../../utils/app_theme.dart';
import '../../config/app_colors.dart';

class VoiceLearningScreen extends StatefulWidget {
  const VoiceLearningScreen({super.key});

  @override
  State<VoiceLearningScreen> createState() => _VoiceLearningScreenState();
}

class _VoiceLearningScreenState extends State<VoiceLearningScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late TabController _tabController;

  final List<String> subjects = [
    'General',
    'Mathematics',
    'Science',
    'History',
    'Literature',
    'Biology',
    'Chemistry',
    'Physics',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _tabController = TabController(length: 4, vsync: this);

    // Initialize voice service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVoice();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeVoice() async {
    final voiceProvider = context.read<VoiceProvider>();

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Initializing voice services...'),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );

    final success = await voiceProvider.initialize();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Voice services ready!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        final error = voiceProvider.error ?? 'Unknown initialization error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Voice initialization failed'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => voiceProvider.retryInitialization(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceProvider>(
      builder: (context, voiceProvider, child) {
        // Update animation based on voice state
        if (voiceProvider.isListening) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Voice Learning'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettingsDialog(voiceProvider),
              ),
              IconButton(
                icon: const Icon(Icons.info),
                onPressed: () => _showDebugInfo(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Status Banner
              if (!voiceProvider.isInitialized)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange.withOpacity(0.2),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Voice service not initialized. Check permissions.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                      TextButton(
                        onPressed: _initializeVoice,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: Theme
                      .of(context)
                      .colorScheme
                      .surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.withOpacity(Colors.black, 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Voice Chat', icon: Icon(Icons.chat)),
                    Tab(text: 'Pronunciation',
                        icon: Icon(Icons.record_voice_over)),
                    Tab(text: 'Voice Notes', icon: Icon(Icons.note_add)),
                    Tab(text: 'Flashcards', icon: Icon(Icons.volume_up)),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVoiceChatTab(voiceProvider),
                    _buildPronunciationTab(voiceProvider),
                    _buildVoiceNotesTab(voiceProvider),
                    _buildAudioFlashcardsTab(voiceProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceChatTab(VoiceProvider voiceProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Subject Selector
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
                    value: voiceProvider.currentSubject,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.subject),
                    ),
                    items: subjects
                        .map((subject) =>
                        DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        voiceProvider.setSubject(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Voice Interaction Area
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Microphone Button
                    GestureDetector(
                      onTap: voiceProvider.isInitialized
                          ? () => _handleVoiceInteraction(voiceProvider)
                          : null,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: voiceProvider.isListening ? _pulseAnimation
                                .value : 1.0,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getVoiceButtonColor(voiceProvider),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getVoiceButtonColor(voiceProvider)
                                        .withOpacity(0.3),
                                    blurRadius: voiceProvider.isListening
                                        ? 20
                                        : 10,
                                    spreadRadius: voiceProvider.isListening
                                        ? 5
                                        : 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getVoiceButtonIcon(voiceProvider),
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Status Text
                    Text(
                      _getVoiceStatusText(voiceProvider),
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: _getVoiceButtonColor(voiceProvider),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Recognized Text Display
                    if (voiceProvider.recognizedText.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.mic, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'You said:',
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              voiceProvider.recognizedText,
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .bodyLarge,
                            ),
                            if (voiceProvider.confidence > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    const Text('Confidence: '),
                                    Text(
                                      '${(voiceProvider.confidence * 100)
                                          .toInt()}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // AI Response Display
                    if (voiceProvider.lastResponse.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                    Icons.smart_toy, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Response:',
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.volume_up),
                                  onPressed: () =>
                                      voiceProvider.speak(
                                          voiceProvider.lastResponse),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              voiceProvider.lastResponse,
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .bodyLarge,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Action Buttons
                    if (voiceProvider.recognizedText.isNotEmpty &&
                        !voiceProvider.isProcessing)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => voiceProvider.askAIWithVoice(),
                            icon: const Icon(Icons.send),
                            label: const Text('Ask AI'),
                          ),
                          OutlinedButton.icon(
                            onPressed: voiceProvider.clearText,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),

                    // Error Display
                    if (voiceProvider.error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                voiceProvider.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: voiceProvider.clearError,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPronunciationTab(VoiceProvider voiceProvider) {
    final TextEditingController textController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pronunciation Practice',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      labelText: 'Enter text to practice',
                      hintText: 'e.g., photosynthesis, quantum mechanics',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.text_fields),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: textController.text.isNotEmpty &&
                          voiceProvider.isInitialized
                          ? () =>
                          _practicePronunciation(
                              voiceProvider, textController.text)
                          : null,
                      icon: const Icon(Icons.record_voice_over),
                      label: const Text('Start Practice'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Practice Options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Practice',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Hello, how are you?',
                      'Photosynthesis',
                      'Quantum mechanics',
                      'Mitochondria',
                      'Pronunciation',
                    ].map((text) =>
                        ElevatedButton(
                          onPressed: voiceProvider.isInitialized
                              ? () =>
                              _practicePronunciation(voiceProvider, text)
                              : null,
                          child: Text(text),
                        )).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceNotesTab(VoiceProvider voiceProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Voice Notes',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Take notes using your voice. Perfect for lectures or quick thoughts!',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: voiceProvider.isInitialized &&
                        !voiceProvider.isListening
                        ? () => _takeVoiceNote(voiceProvider)
                        : null,
                    icon: Icon(
                        voiceProvider.isListening ? Icons.stop : Icons.mic),
                    label: Text(voiceProvider.isListening
                        ? 'Stop Recording'
                        : 'Start Recording'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (voiceProvider.recognizedText.isNotEmpty)
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Note:',
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme
                                .of(context)
                                .colorScheme
                                .surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              voiceProvider.recognizedText,
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .bodyLarge,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            onPressed: voiceProvider.clearText,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _saveNote(voiceProvider.recognizedText),
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioFlashcardsTab(VoiceProvider voiceProvider) {
    // Sample flashcards for demonstration
    final sampleFlashcards = [
      {
        'question': 'What is photosynthesis?',
        'answer': 'The process by which plants use sunlight to synthesize food from carbon dioxide and water.'
      },
      {'question': 'What is the capital of France?', 'answer': 'Paris'},
      {'question': 'What is 2 + 2?', 'answer': '4'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Audio Flashcards',
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
                    'Listen to flashcards being read aloud',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: sampleFlashcards.length,
              itemBuilder: (context, index) {
                final card = sampleFlashcards[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(card['question']!),
                    subtitle: Text(card['answer']!),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: voiceProvider.isInitialized
                              ? () =>
                              voiceProvider.readFlashcard(
                                question: card['question']!,
                                answer: card['answer']!,
                              )
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: voiceProvider.isInitialized
                              ? () =>
                              voiceProvider.speak(
                                  '${card['question']}. ${card['answer']}')
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getVoiceButtonColor(VoiceProvider voiceProvider) {
    if (voiceProvider.isListening) return Colors.red;
    if (voiceProvider.isSpeaking) return Colors.green;
    if (voiceProvider.isProcessing) return Colors.orange;
    return Theme
        .of(context)
        .colorScheme
        .primary;
  }

  IconData _getVoiceButtonIcon(VoiceProvider voiceProvider) {
    if (voiceProvider.isListening) return Icons.stop;
    if (voiceProvider.isSpeaking) return Icons.volume_up;
    if (voiceProvider.isProcessing) return Icons.hourglass_empty;
    return Icons.mic;
  }

  String _getVoiceStatusText(VoiceProvider voiceProvider) {
    if (voiceProvider.isListening) return 'Listening... Tap to stop';
    if (voiceProvider.isSpeaking) return 'Speaking... Tap to stop';
    if (voiceProvider.isProcessing) return 'Processing your question...';
    return 'Tap to start voice chat';
  }

  Future<void> _handleVoiceInteraction(VoiceProvider voiceProvider) async {
    if (voiceProvider.isListening) {
      await voiceProvider.stopListening();
    } else if (voiceProvider.isSpeaking) {
      await voiceProvider.stopSpeaking();
    } else {
      await voiceProvider.startListening();
    }
  }

  Future<void> _practicePronunciation(VoiceProvider voiceProvider,
      String text) async {
    final score = await voiceProvider.practicePronunciation(text);

    if (mounted) {
      String message;
      Color color;
      if (score > 0.8) {
        message = 'Excellent! Score: ${(score * 100).toInt()}%';
        color = Colors.green;
      } else if (score > 0.6) {
        message = 'Good! Score: ${(score * 100).toInt()}%';
        color = Colors.orange;
      } else {
        message = 'Keep practicing! Score: ${(score * 100).toInt()}%';
        color = Colors.red;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    }
  }

  Future<void> _takeVoiceNote(VoiceProvider voiceProvider) async {
    await voiceProvider.takeVoiceNote();
  }

  void _saveNote(String note) {
    // Here you could integrate with the existing note-taking system
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note saved! (Integration with notes system pending)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showSettingsDialog(VoiceProvider voiceProvider) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Voice Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Auto-speak responses'),
                  value: voiceProvider.autoSpeak,
                  onChanged: voiceProvider.setAutoSpeak,
                ),
                ListTile(
                  title: const Text('Speech Rate'),
                  subtitle: Slider(
                    value: voiceProvider.speechRate,
                    onChanged: voiceProvider.setSpeechRate,
                    min: 0.1,
                    max: 1.0,
                  ),
                ),
                ListTile(
                  title: const Text('Pitch'),
                  subtitle: Slider(
                    value: voiceProvider.pitch,
                    onChanged: voiceProvider.setPitch,
                    min: 0.5,
                    max: 2.0,
                  ),
                ),
                ListTile(
                  title: const Text('Volume'),
                  subtitle: Slider(
                    value: voiceProvider.volume,
                    onChanged: voiceProvider.setVolume,
                    min: 0.0,
                    max: 1.0,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showDebugInfo() {
    final voiceProvider = context.read<VoiceProvider>();
    final debugInfo = voiceProvider.getDebugInfo();

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Voice Service Debug Info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: debugInfo.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${entry.key}:',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value?.toString() ?? 'null',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Copy debug info to clipboard
              final debugText = debugInfo.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n');
              // You could use Clipboard.setData here if needed
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Debug info available in console')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}