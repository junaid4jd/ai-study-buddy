import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  String _selectedPeriod = 'Week';

  // Sample data - in a real app, this would come from a database
  int _questionsAsked = 0;
  int _flashcardsCreated = 0;
  int _quizzesTaken = 0;
  int _studyStreak = 1;
  double _averageScore = 0.0;

  final List<String> _periods = ['Week', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    // Load stats after the first frame is built to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        // For now, just show some sample stats to avoid the provider issues
        setState(() {
          _questionsAsked = 25;
          _flashcardsCreated = 15;
          _quizzesTaken = 8;
          _studyStreak = 5;
          _averageScore = 85.5;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Statistics'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) =>
                _periods
                    .map((period) =>
                    PopupMenuItem(
                      value: period,
                      child: Text(period),
                    ))
                    .toList(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text(
                  _selectedPeriod,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            Text(
              'Overview',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildStatCard(
                  'Questions Asked',
                  '$_questionsAsked',
                  Icons.help_outline,
                  Colors.blue,
                  '+${(_questionsAsked * 0.1).round()} this week',
                ),
                _buildStatCard(
                  'Flashcards Created',
                  '$_flashcardsCreated',
                  Icons.style,
                  Colors.green,
                  '+${(_flashcardsCreated * 0.15).round()} this week',
                ),
                _buildStatCard(
                  'Quizzes Taken',
                  '$_quizzesTaken',
                  Icons.quiz,
                  Colors.orange,
                  '+${(_quizzesTaken * 0.2).round()} this week',
                ),
                _buildStatCard(
                  'Study Streak',
                  '$_studyStreak days',
                  Icons.local_fire_department,
                  Colors.red,
                  'Keep it up!',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Performance Section
            Text(
              'Performance',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Average Quiz Score',
                            style: Theme
                                .of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${_averageScore.toStringAsFixed(1)}%',
                          style: Theme
                              .of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(_averageScore),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _averageScore / 100,
                      backgroundColor: AppTheme.withOpacity(
                        _getScoreColor(_averageScore),
                        0.2,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(_averageScore),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getScoreMessage(_averageScore),
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
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Activity Chart Placeholder
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity This $_selectedPeriod',
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.withOpacity(
                          Theme
                              .of(context)
                              .colorScheme
                              .primary,
                          0.05,
                        ),
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
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 36,
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .primary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Activity Chart',
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                color: Theme
                                    .of(context)
                                    .colorScheme
                                    .primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Visual analytics coming soon',
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
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Goals Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Goals',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _showGoalsDialog,
                          child: const Text('Set Goals'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildGoalItem(
                      'Daily Questions',
                      _questionsAsked % 10,
                      10,
                      'questions',
                      Icons.help_outline,
                    ),
                    const SizedBox(height: 10),
                    _buildGoalItem(
                      'Weekly Flashcards',
                      _flashcardsCreated % 15,
                      15,
                      'cards',
                      Icons.style,
                    ),
                    const SizedBox(height: 10),
                    _buildGoalItem(
                      'Study Streak',
                      _studyStreak,
                      7,
                      'days',
                      Icons.local_fire_department,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom padding to ensure content doesn't get cut off
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title,
      String value,
      IconData icon,
      Color color,
      String subtitle,) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: Theme
                  .of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
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
                  0.6,
                ),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(String title,
      int current,
      int target,
      String unit,
      IconData icon,) {
    final progress = current / target;
    final isCompleted = current >= target;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isCompleted ? Colors.green : Theme
              .of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$current/$target $unit',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color: isCompleted ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppTheme.withOpacity(
                  Theme
                      .of(context)
                      .colorScheme
                      .primary,
                  0.2,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : Colors.orange,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        if (isCompleted)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreMessage(double score) {
    if (score >= 90) return 'Excellent performance! Keep up the great work!';
    if (score >= 80) return 'Great job! You\'re doing very well!';
    if (score >= 70) return 'Good progress! Keep practicing!';
    if (score >= 60) return 'You\'re on the right track! Keep studying!';
    if (score > 0) return 'Keep working hard, you\'ll get there!';
    return 'Start taking quizzes to see your progress!';
  }

  void _showGoalsDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Set Your Goals'),
            content: const Text(
              'Goal setting feature will be available in a future update. '
                  'For now, try to ask 10 questions per day, create 15 flashcards per week, '
                  'and maintain a 7-day study streak!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it!'),
              ),
            ],
          ),
    );
  }
}