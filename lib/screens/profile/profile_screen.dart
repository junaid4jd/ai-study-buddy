import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/progress_service.dart';
import '../../services/favourites_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../favourites/favourites_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _studyGoal = '60 minutes';

  int _calculateStreak(DateTime? lastLoginAt) {
    if (lastLoginAt == null) return 0;
    final now = DateTime.now();
    final difference = now
        .difference(lastLoginAt)
        .inDays;
    // Simple streak calculation - if logged in today, streak is 1
    return difference == 0 ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.user;
                final userModel = authProvider.userModel;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme
                              .of(context)
                              .colorScheme
                              .primary,
                          child: Text(
                            user?.displayName?.isNotEmpty == true
                                ? user!.displayName![0].toUpperCase()
                                : user?.email?[0].toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.displayName ?? 'User',
                          style: Theme
                              .of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
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
                        // Real stats from progress service
                        if (user != null)
                          FutureBuilder<UserStats?>(
                            future: ProgressService().getUserStats(user.uid),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceEvenly,
                                  children: [
                                    CircularProgressIndicator(),
                                  ],
                                );
                              }

                              if (snapshot.hasError) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceEvenly,
                                  children: [
                                    _buildStatItem('Questions Used', '0',
                                        Icons.help_outline),
                                    _buildStatItem('Study Streak', '0 days',
                                        Icons.local_fire_department),
                                    _buildStatItem('Member Since', 'Today',
                                        Icons.calendar_today),
                                  ],
                                );
                              }

                              final stats = snapshot.data;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceEvenly,
                                children: [
                                  _buildStatItem(
                                    'Questions Used',
                                    '${stats?.totalQuestionsAsked ?? 0}',
                                    Icons.help_outline,
                                  ),
                                  _buildStatItem(
                                    'Study Streak',
                                    '${stats?.currentStreak ?? 0} days',
                                    Icons.local_fire_department,
                                  ),
                                  _buildStatItem(
                                    'Member Since',
                                    _formatDate(userModel?.createdAt ??
                                        stats?.createdAt),
                                    Icons.calendar_today,
                                  ),
                                ],
                              );
                            },
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(
                                  'Questions Used', '0', Icons.help_outline),
                              _buildStatItem('Study Streak', '0 days',
                                  Icons.local_fire_department),
                              _buildStatItem('Member Since', 'Today',
                                  Icons.calendar_today),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Study Statistics - Real Data
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.user == null) {
                  return const SizedBox.shrink();
                }

                return FutureBuilder<List<dynamic>>(
                  future: Future.wait([
                    ProgressService().getTodaysProgress(authProvider.user!.uid),
                    ProgressService().getUserStats(authProvider.user!.uid),
                    ProgressService().getWeeklyProgress(authProvider.user!.uid),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Study Statistics',
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildProgressItem(
                                  'Today\'s Progress', 0, 60, 'minutes',
                                  Colors.blue),
                              const SizedBox(height: 12),
                              _buildProgressItem(
                                  'Weekly Goal', 0, 7, 'days', Colors.green),
                              const SizedBox(height: 12),
                              _buildProgressItem(
                                  'Flashcards Created', 0, 50, 'cards',
                                  Colors.orange),
                            ],
                          ),
                        ),
                      );
                    }

                    final results = snapshot.data;
                    final todayProgress = results?[0] as DailyProgress?;
                    final userStats = results?[1] as UserStats?;
                    final weeklyProgress = results?[2] as List<
                        DailyProgress>? ?? [];

                    final todayMinutes = todayProgress?.totalStudyTime ?? 0;
                    final activeDaysThisWeek = weeklyProgress.where((day) =>
                    day.totalStudyTime > 0 || day.questionsAsked > 0 ||
                        day.flashcardsCreated > 0 || day.quizzesTaken > 0)
                        .length;
                    final totalFlashcards = userStats?.totalFlashcardsCreated ??
                        0;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Study Statistics',
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildProgressItem(
                              'Today\'s Progress',
                              todayMinutes,
                              60,
                              'minutes',
                              Colors.blue,
                            ),
                            const SizedBox(height: 12),
                            _buildProgressItem(
                              'Weekly Goal',
                              activeDaysThisWeek,
                              7,
                              'days',
                              Colors.green,
                            ),
                            const SizedBox(height: 12),
                            _buildProgressItem(
                              'Flashcards Created',
                              totalFlashcards,
                              50,
                              'cards',
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // Settings Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsItem(
                      'Notifications',
                      'Get study reminders and updates',
                      Icons.notifications_outlined,
                      Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                    ),
                    _buildSettingsItem(
                      'Dark Mode',
                      'Switch to dark theme',
                      Icons.dark_mode_outlined,
                      Switch(
                        value: _darkModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _darkModeEnabled = value;
                          });
                        },
                      ),
                    ),
                    _buildSettingsItem(
                      'Daily Study Goal',
                      _studyGoal,
                      Icons.schedule_outlined,
                      const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showStudyGoalDialog,
                    ),
                    _buildSettingsItem(
                      'Favourites',
                      'View your favourited flashcards',
                      Icons.favorite_border,
                      const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (
                              context) => const FavouritesScreen()),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      'About',
                      'App version and information',
                      Icons.info_outline,
                      const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showAboutDialog,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Account Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsItem(
                      'Change Password',
                      'Update your account password',
                      Icons.lock_outline,
                      const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showChangePasswordDialog,
                    ),
                    _buildSettingsItem(
                      'Privacy Policy',
                      'View our privacy policy',
                      Icons.privacy_tip_outlined,
                      const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(
                              'Privacy policy coming soon')),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      'Sign Out',
                      'Sign out of your account',
                      Icons.logout,
                      const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showSignOutDialog,
                      isDestructive: true,
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme
              .of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme
              .of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme
              .of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
            color: AppTheme.withOpacity(
                Theme
                    .of(context)
                    .colorScheme
                    .onSurface, 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressItem(String label,
      int current,
      int target,
      String unit,
      Color color,) {
    final progress = current / target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
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
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: AppTheme.withOpacity(color, 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(String title,
      String subtitle,
      IconData icon,
      Widget trailing, {
        VoidCallback? onTap,
        bool isDestructive = false,
      }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Theme
            .of(context)
            .colorScheme
            .primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDestructive
              ? Colors.red.withOpacity(0.7)
              : AppTheme.withOpacity(
              Theme
                  .of(context)
                  .colorScheme
                  .onSurface, 0.7),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showEditProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final nameController = TextEditingController(
        text: authProvider.user?.displayName ?? '');

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Edit Profile'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text
                      .trim()
                      .isNotEmpty) {
                    await authProvider.updateDisplayName(
                        nameController.text.trim());
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Profile updated successfully')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showStudyGoalDialog() {
    final goals = ['30 minutes', '60 minutes', '90 minutes', '120 minutes'];

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Daily Study Goal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: goals.map((goal) =>
                  RadioListTile<String>(
                    title: Text(goal),
                    value: goal,
                    groupValue: _studyGoal,
                    onChanged: (value) {
                      setState(() {
                        _studyGoal = value!;
                      });
                      Navigator.pop(context);
                    },
                  )).toList(),
            ),
          ),
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (newController.text == confirmController.text) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(
                          'Password change functionality coming soon')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match')),
                    );
                  }
                },
                child: const Text('Change'),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'AI Study Companion',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.school, size: 64),
      children: [
        const Text(
            'An AI-powered study companion app that helps students learn more effectively through personalized tutoring, flashcards, and progress tracking.'),
        const SizedBox(height: 16),
        const Text('Built with Flutter and powered by OpenAI.'),
      ],
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(
                      context, listen: false);
                  await authProvider.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                          (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).round();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).round();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }
}