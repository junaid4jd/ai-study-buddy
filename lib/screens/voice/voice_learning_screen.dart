import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class VoiceLearningScreen extends StatefulWidget {
  const VoiceLearningScreen({super.key});

  @override
  State<VoiceLearningScreen> createState() => _VoiceLearningScreenState();
}

class _VoiceLearningScreenState extends State<VoiceLearningScreen>
    with TickerProviderStateMixin {
  bool _isListening = false;
  String _lastSpokenText = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      _pulseController.repeat(reverse: true);
      // Simulate voice recognition - in a real app, you would use speech_to_text package
      _simulateVoiceRecognition();
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _simulateVoiceRecognition() {
    // Simulate voice recognition delay
    Future.delayed(const Duration(seconds: 3), () {
      if (_isListening && mounted) {
        setState(() {
          _lastSpokenText =
          "Voice recognition feature coming soon! This is a demo.";
          _isListening = false;
        });
        _pulseController.stop();
        _pulseController.reset();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice recognition simulation complete!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Learning'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Coming Soon Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.withOpacity(Colors.blue, 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.construction,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coming Soon!',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Voice learning features are under development. Try the demo below!',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: Colors.blue.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Voice Recognition Demo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Voice Recognition Demo',
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Microphone Button
                    GestureDetector(
                      onTap: _toggleListening,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isListening ? _pulseAnimation.value : 1.0,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isListening
                                    ? Colors.red.withOpacity(0.8)
                                    : Theme
                                    .of(context)
                                    .colorScheme
                                    .primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isListening ? Colors.red : Theme
                                        .of(context)
                                        .colorScheme
                                        .primary)
                                        .withValues(alpha: 0.3),
                                    blurRadius: _isListening ? 20 : 10,
                                    spreadRadius: _isListening ? 5 : 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isListening ? Icons.stop : Icons.mic,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      _isListening
                          ? 'Listening...'
                          : 'Tap to start voice recognition',
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: _isListening
                            ? Colors.red
                            : Theme
                            .of(context)
                            .colorScheme
                            .primary,
                      ),
                    ),

                    if (_lastSpokenText.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme
                              .of(context)
                              .colorScheme
                              .surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recognized Text:',
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Theme
                                    .of(context)
                                    .colorScheme
                                    .primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _lastSpokenText,
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Features Preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.preview,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Upcoming Features',
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
                    const SizedBox(height: 16),

                    _buildFeatureItem(
                      'Voice Questions',
                      'Ask questions using your voice instead of typing',
                      Icons.record_voice_over,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      'Pronunciation Practice',
                      'Practice pronunciation of terms and concepts',
                      Icons.hearing,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      'Audio Flashcards',
                      'Listen to flashcards being read aloud',
                      Icons.volume_up,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      'Speech-to-Text Notes',
                      'Take notes by speaking instead of typing',
                      Icons.note_add,
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Feedback Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.feedback,
                      size: 48,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Help Us Improve',
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your feedback is valuable! Let us know what voice features you\'d like to see.',
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
                          0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Feedback feature coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Send Feedback'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title,
      String description,
      IconData icon,
      Color color,) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.withOpacity(color, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme
                    .of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                  color: AppTheme.withOpacity(
                    Theme
                        .of(context)
                        .colorScheme
                        .onSurface,
                    0.7,
                  ),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme
              .of(context)
              .colorScheme
              .outline
              .withValues(alpha: 128),
        ),
      ],
    );
  }
}