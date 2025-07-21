import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../utils/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  String _selectedPeriod = 'Week';

  final List<String> _periods = ['Week', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    // Load stats after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final progressProvider = Provider.of<ProgressProvider>(
          context, listen: false);

      if (authProvider.user != null) {
        // Initialize progress data for the current user
        await progressProvider.initializeProgress(authProvider.user!.uid);
      }

      setState(() {
        _isLoading = false;
      });
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
          : Consumer<ProgressProvider>(
        builder: (context, progressProvider, child) {
          // Get real data from progress provider
          final userStats = progressProvider.userStats;
          final todayProgress = progressProvider.todayProgress;
          final studyGoalProgress = progressProvider.studyGoalProgress;

          // Calculate period-specific data
          final questionsAsked = _getPeriodSpecificValue(
            userStats?.totalQuestionsAsked ?? 0,
            todayProgress?.questionsAsked ?? 0,
          );
          final flashcardsCreated = _getPeriodSpecificValue(
            userStats?.totalFlashcardsCreated ?? 0,
            todayProgress?.flashcardsCreated ?? 0,
          );
          final quizzesTaken = _getPeriodSpecificValue(
            userStats?.totalQuizzesTaken ?? 0,
            todayProgress?.quizzesTaken ?? 0,
          );
          final studyStreak = userStats?.currentStreak ?? 0;
          final averageScore = userStats?.averageQuizScore ?? 0.0;
          final todayStudyTime = todayProgress?.totalStudyTime ?? 0;

          return SingleChildScrollView(
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
                            '$questionsAsked',
                            Icons.help_outline,
                            Colors.blue,
                            _getChangeText(
                                questionsAsked, 'this $_selectedPeriod'),
                          ),
                          _buildStatCard(
                            'Flashcards Created',
                            '$flashcardsCreated',
                            Icons.style,
                            Colors.green,
                            _getChangeText(
                                flashcardsCreated, 'this $_selectedPeriod'),
                          ),
                          _buildStatCard(
                            'Quizzes Taken',
                            '$quizzesTaken',
                            Icons.quiz,
                            Colors.orange,
                            _getChangeText(
                                quizzesTaken, 'this $_selectedPeriod'),
                          ),
                          _buildStatCard(
                            'Study Streak',
                            '$studyStreak days',
                            Icons.local_fire_department,
                            studyStreak > 0 ? Colors.red : Colors.grey,
                            studyStreak > 0 ? 'Keep it up!' : 'Start studying!',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Study Time Today Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Study Time Today',
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
                                    '${todayStudyTime}min',
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _getStudyTimeColor(todayStudyTime),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: studyGoalProgress != null
                                    ? (todayStudyTime /
                                    studyGoalProgress.dailyGoal).clamp(0.0, 1.0)
                                    : 0.0,
                                backgroundColor: AppTheme.withOpacity(
                                  _getStudyTimeColor(todayStudyTime),
                                  0.2,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getStudyTimeColor(todayStudyTime),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                studyGoalProgress?.isGoalMet == true
                                    ? 'Daily goal achieved! '
                                    : 'Goal: ${studyGoalProgress?.dailyGoal ??
                                    60} minutes daily',
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
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
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
                                    averageScore > 0
                                        ? '${averageScore.toStringAsFixed(1)}%'
                                        : 'No data',
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _getScoreColor(averageScore),
                                    ),
                                  ),
                                ],
                              ),
                              if (averageScore > 0) ...[
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: averageScore / 100,
                                  backgroundColor: AppTheme.withOpacity(
                                    _getScoreColor(averageScore),
                                    0.2,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getScoreColor(averageScore),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getScoreMessage(averageScore),
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
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Activity Summary Card
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

                              // Activity breakdown
                              if (todayProgress != null) ...[
                                _buildActivityRow(
                                    'Questions', todayProgress.questionsAsked,
                                    Icons.help_outline, Colors.blue),
                                const SizedBox(height: 8),
                                _buildActivityRow('Flashcards',
                                    todayProgress.flashcardsCreated,
                                    Icons.style, Colors.green),
                                const SizedBox(height: 8),
                                _buildActivityRow(
                                    'Quiz Sessions', todayProgress.quizzesTaken,
                                    Icons.quiz, Colors.orange),
                                const SizedBox(height: 8),
                                _buildActivityRow(
                                    'Study Time', todayProgress.totalStudyTime,
                                    Icons.access_time, Colors.purple),
                              ] else
                                ...[
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
                                        mainAxisAlignment: MainAxisAlignment
                                            .center,
                                        children: [
                                          Icon(
                                            Icons.trending_up,
                                            size: 36,
                                            color: Theme
                                                .of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Start studying to see activity',
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
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Text(
                                    'Daily Goals',
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
                                    child: const Text('Info'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildGoalItem(
                                'Daily Questions',
                                todayProgress?.questionsAsked ?? 0,
                                10,
                                'questions',
                                Icons.help_outline,
                              ),
                              const SizedBox(height: 10),
                              _buildGoalItem(
                                'Daily Flashcards',
                                todayProgress?.flashcardsCreated ?? 0,
                                5,
                                'cards',
                                Icons.style,
                              ),
                              const SizedBox(height: 10),
                              _buildGoalItem(
                                'Study Time',
                                todayStudyTime,
                                studyGoalProgress?.dailyGoal ?? 60,
                                'minutes',
                                Icons.access_time,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom padding
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Helper method to get period-specific values
  int _getPeriodSpecificValue(int totalValue, int todayValue) {
    switch (_selectedPeriod) {
      case 'Week':
      // Approximate weekly value (today * 7 or total if less)
        return todayValue * 7 > totalValue ? totalValue : todayValue * 7;
      case 'Month':
      // Show total value for month
        return totalValue;
      case 'Year':
      // Show total value for year
        return totalValue;
      default:
        return totalValue;
    }
  }

  String _getChangeText(int value, String period) {
    if (value == 0) return 'Start studying!';
    return 'Great progress!';
  }

  Widget _buildActivityRow(String label, int value, IconData icon,
      Color color) {
    String displayValue = label == 'Study Time' ? '${value}min' : '$value';

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme
                .of(context)
                .textTheme
                .bodyMedium,
          ),
        ),
        Text(
          displayValue,
          style: Theme
              .of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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
    if (score > 0) return Colors.red;
    return Colors.grey;
  }

  Color _getStudyTimeColor(int minutes) {
    if (minutes >= 60) return Colors.green;
    if (minutes >= 30) return Colors.orange;
    if (minutes > 0) return Colors.blue;
    return Colors.grey;
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
            title: const Text('Daily Study Goals'),
            content: const Text(
              'Your daily goals help you maintain consistent study habits:\n\n'
                  '• 10 Questions: Ask AI tutor for help\n'
                  '• 5 Flashcards: Create study materials\n'
                  '• 60 Minutes: Total active study time\n\n'
                  'Complete these goals daily to build a strong study streak!',
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