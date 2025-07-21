import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/progress_service.dart';
import '../../utils/app_theme.dart';
import '../chat/chat_screen.dart';
import '../flashcards/flashcard_screen.dart';
import '../quiz/quiz_screen.dart';
import '../stats/stats_screen.dart';
import '../profile/profile_screen.dart';
import '../summarizer/summarizer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        onNavigate: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const ChatScreen(),
      const FlashcardScreen(),
      const QuizScreen(),
      const StatsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.withOpacity(Colors.black, 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex >= 5 ? 0 : _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'AI Tutor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.style),
              label: 'Flashcards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz),
              label: 'Quiz',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Stats',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final void Function(int) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.user;

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  onNavigate(5);
                },
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Icon(
                    Icons.account_circle,
                    color: Colors.white,
                    size: 24,
                  )
                      : null,
                ),
              ),
            );
          },
        ),
        title: const Text('AI Study Companion'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _buildHomeContent(),
    );
  }

  Widget _buildHomeContent() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final userModel = authProvider.userModel;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()}, ${user?.displayName
                              ?.split(' ')
                              .first ?? userModel?.displayName
                              ?.split(' ')
                              .first ?? 'Student'}! 👋',
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
                        const SizedBox(height: 4),
                        Text(
                          _getGreetingMessage(),
                          style: Theme
                              .of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                            color: AppTheme.withOpacity(
                              Theme
                                  .of(context)
                                  .colorScheme
                                  .onSurface,
                              0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.user == null) {
                    return const SizedBox.shrink();
                  }
                  return FutureBuilder<StudyGoalProgress>(
                    future: ProgressService().getStudyGoalProgress(
                        authProvider.user!.uid, 60),
                    builder: (context, snapshot) {
                      final progress = snapshot.data;
                      final progressValue = progress != null
                          ? (progress.todayProgress / progress.dailyGoal).clamp(
                          0.0, 1.0)
                          : 0.0;
                      final todayMinutes = progress?.todayProgress ?? 0;
                      final goalMinutes = progress?.dailyGoal ?? 60;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme
                                  .of(context)
                                  .colorScheme
                                  .primary,
                              Theme
                                  .of(context)
                                  .colorScheme
                                  .secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.withOpacity(
                                  Theme
                                      .of(context)
                                      .colorScheme
                                      .primary, 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daily Progress',
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  progress?.isGoalMet == true
                                      ? Icons.check_circle
                                      : Icons.trending_up,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor: AppTheme.withOpacity(
                                  Colors.white, 0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$todayMinutes min / $goalMinutes min',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              Text(
                'Quick Actions',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Custom grid layout for 5 cards
              Column(
                children: [
                  // First row - 2 cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          'AI Tutor',
                          'Ask questions & get help',
                          Icons.school,
                          Colors.blue,
                              () => onNavigate(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          'AI Summarizer',
                          'Create study notes',
                          Icons.auto_awesome,
                          Colors.teal,
                              () =>
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (
                                    context) => const SummarizerScreen()),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Second row - 3 cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          'Flashcards',
                          'Study cards',
                          Icons.style,
                          Colors.green,
                              () => onNavigate(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          'Quiz',
                          'Test knowledge',
                          Icons.quiz,
                          Colors.purple,
                              () => onNavigate(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          'Study Stats',
                          'Track progress',
                          Icons.analytics,
                          Colors.orange,
                              () => onNavigate(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime
        .now()
        .hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getGreetingMessage() {
    final hour = DateTime
        .now()
        .hour;
    if (hour < 12) {
      return 'Good morning! Let\'s start learning.';
    } else if (hour < 17) {
      return 'Good afternoon! Time for some study.';
    } else {
      return 'Good evening! Perfect time to review.';
    }
  }

  Widget _buildQuickActionCard(BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme
                .of(context)
                .colorScheme
                .surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.withOpacity(
                Theme
                    .of(context)
                    .colorScheme
                    .outline,
                0.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme
                    .of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme
                      .of(context)
                      .colorScheme
                      .onSurface,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
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
      ),
    );
  }
}