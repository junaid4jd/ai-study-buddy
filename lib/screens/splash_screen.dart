import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool isInitialized;

  const SplashScreen({super.key, this.isInitialized = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _dotsController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Setup animations
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
    _dotsController.repeat();

    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for minimum splash duration
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for auth provider to initialize
    while (!authProvider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    final prefs = await SharedPreferences.getInstance();
    final isOnboardingCompleted = prefs.getBool('onboarding_completed') ??
        false;

    if (!mounted) return;

    // Navigate based on auth state
    if (isOnboardingCompleted) {
      if (authProvider.isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * 2 * 3.14159,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.school,
                              size: 60,
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .primary,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              Text(
                'AI Study Companion',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Your AI-powered learning companion',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withAlpha(230),
                ),
              ),

              const SizedBox(height: 48),

              // Animated Loading Dots
              const SizedBox(height: 32),
              _AnimatedLoadingDots(controller: _dotsController),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for animated loading dots
class _AnimatedLoadingDots extends StatelessWidget {
  final AnimationController controller;
  static const int dotCount = 3;
  static const double dotSize = 12;
  static const double dotSpacing = 8;

  const _AnimatedLoadingDots({required this.controller});

  Widget _buildDot(int index) {
    // Create staggered animation for each dot
    final double start = index * 0.2; // 0.2 second delay between dots
    final double end = start + 0.4; // Each dot animation lasts 0.4 seconds

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double t = controller.value;
        double dotScale = 1.0;
        double dotOpacity = 0.4;

        // Calculate the current phase of this dot's animation
        if (t >= start && t <= end) {
          double progress = (t - start) / (end - start);
          // Use a sine wave for smooth bouncing
          dotScale = 1.0 + (0.8 * (1 - (2 * (progress - 0.5).abs())));
          dotOpacity = 0.4 + (0.6 * (1 - (2 * (progress - 0.5).abs())));
        } else if (t > end && t < start + 1.0) {
          // Keep some visibility when not actively animating
          dotOpacity = 0.4;
        }

        return Transform.scale(
          scale: dotScale,
          child: Container(
            width: dotSize,
            height: dotSize,
            margin: EdgeInsets.symmetric(horizontal: dotSpacing / 2),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((dotOpacity * 255).round()),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(dotCount, (index) => _buildDot(index)),
    );
  }
}