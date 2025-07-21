import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/premium_provider.dart';
import '../../services/iap_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final premiumProvider = Provider.of<PremiumProvider>(
          context, listen: false);
      premiumProvider.initializeIAP();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .primary,
        foregroundColor: Theme
            .of(context)
            .colorScheme
            .onPrimary,
        actions: [
          TextButton(
            onPressed: () => _showRestorePurchases(context),
            child: Text(
              'Restore',
              style: TextStyle(
                color: Theme
                    .of(context)
                    .colorScheme
                    .onPrimary,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<PremiumProvider>(
        builder: (context, premiumProvider, child) {
          if (premiumProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (premiumProvider.isPremium) {
            return _buildPremiumActiveScreen(context, premiumProvider);
          }

          return _buildUpgradeScreen(context, premiumProvider);
        },
      ),
    );
  }

  Widget _buildPremiumActiveScreen(BuildContext context,
      PremiumProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
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
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.diamond,
                  size: 80,
                  color: Theme
                      .of(context)
                      .colorScheme
                      .onPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Premium Active!',
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have access to all premium features',
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildPremiumFeatures(context, isActive: true),
        ],
      ),
    );
  }

  Widget _buildUpgradeScreen(BuildContext context, PremiumProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme
                      .of(context)
                      .colorScheme
                      .primary,
                  Theme
                      .of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Icon(
                    Icons.diamond_outlined,
                    size: 80,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onPrimary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upgrade to Premium',
                    style: Theme
                        .of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock unlimited learning potential',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Current limitations
                if (!provider.isPremium) _buildCurrentLimitations(
                    context, provider),

                const SizedBox(height: 32),

                // Premium features
                _buildPremiumFeatures(context),

                const SizedBox(height: 32),

                // Subscription option
                _buildSubscriptionCard(context, provider),

                const SizedBox(height: 24),

                // Question packs
                _buildQuestionPacks(context, provider),

                const SizedBox(height: 32),

                // Terms and restore
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLimitations(BuildContext context,
      PremiumProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: provider.getQuestionLimitColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: provider.getQuestionLimitColor().withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: provider.getQuestionLimitColor(),
              ),
              const SizedBox(width: 12),
              Text(
                'Current Plan',
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
          LinearProgressIndicator(
            value: provider.questionsUsed / provider.maxQuestions,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              provider.getQuestionLimitColor(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            provider.getQuestionLimitText(),
            style: Theme
                .of(context)
                .textTheme
                .bodyMedium,
          ),
          if (provider.isQuestionLimitReached) ...[
            const SizedBox(height: 8),
            Text(
              'Upgrade to premium for unlimited questions!',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color: provider.getQuestionLimitColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumFeatures(BuildContext context, {bool isActive = false}) {
    final features = [
      {
        'icon': Icons.all_inclusive,
        'title': 'Unlimited AI Questions',
        'description': 'Ask as many questions as you want',
      },
      {
        'icon': Icons.analytics,
        'title': 'Advanced Analytics',
        'description': 'Detailed insights into your learning progress',
      },
      {
        'icon': Icons.priority_high,
        'title': 'Priority Support',
        'description': 'Get help faster with premium support',
      },
      {
        'icon': Icons.download,
        'title': 'Export Data',
        'description': 'Download your study data and progress',
      },
      {
        'icon': Icons.mic,
        'title': 'Voice Features',
        'description': 'Ask questions using voice and listen to responses',
      },
      {
        'icon': Icons.new_releases,
        'title': 'Early Access',
        'description': 'Be the first to try new features',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isActive ? 'Your Premium Features' : 'Premium Features',
          style: Theme
              .of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme
                          .of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: isActive
                          ? Theme
                          .of(context)
                          .colorScheme
                          .primary
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature['description'] as String,
                          style: Theme
                              .of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: Theme
                                .of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Icon(
                      Icons.check_circle,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .primary,
                    ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildSubscriptionCard(BuildContext context,
      PremiumProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.diamond,
            size: 48,
            color: Theme
                .of(context)
                .colorScheme
                .onPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            'Premium Subscription',
            style: Theme
                .of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
              color: Theme
                  .of(context)
                  .colorScheme
                  .onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.premiumPrice,
            style: Theme
                .of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(
              color: Theme
                  .of(context)
                  .colorScheme
                  .onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'per month',
            style: Theme
                .of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
              color: Theme
                  .of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : () =>
                  _purchasePremium(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme
                    .of(context)
                    .colorScheme
                    .surface,
                foregroundColor: Theme
                    .of(context)
                    .colorScheme
                    .primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text(
                'Subscribe Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPacks(BuildContext context, PremiumProvider provider) {
    final packs = [
      {
        'id': IAPService.questionPack50Id,
        'questions': 50,
        'price': provider.questionPack50Price,
        'popular': false,
      },
      {
        'id': IAPService.questionPack100Id,
        'questions': 100,
        'price': provider.questionPack100Price,
        'popular': true,
      },
      {
        'id': IAPService.questionPack500Id,
        'questions': 500,
        'price': provider.questionPack500Price,
        'popular': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Or Buy Question Packs',
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
          'Extend your question limit without a subscription',
          style: Theme
              .of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
            color: Theme
                .of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        ...packs.map((pack) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildQuestionPackCard(context, provider, pack),
            )),
      ],
    );
  }

  Widget _buildQuestionPackCard(BuildContext context, PremiumProvider provider,
      Map<String, dynamic> pack) {
    final isPopular = pack['popular'] as bool;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isPopular
              ? Theme
              .of(context)
              .colorScheme
              .primary
              : Colors.grey.withValues(alpha: 0.3),
          width: isPopular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Popular',
                  style: TextStyle(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pack['questions']} Questions',
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
                        'Add ${pack['questions']} questions to your limit',
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color: Theme
                              .of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pack['price'] as String,
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme
                            .of(context)
                            .colorScheme
                            .primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: provider.isLoading
                          ? null
                          : () =>
                          _purchaseQuestionPack(
                              context, provider, pack['id'] as String),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular
                            ? Theme
                            .of(context)
                            .colorScheme
                            .primary
                            : Theme
                            .of(context)
                            .colorScheme
                            .surface,
                        foregroundColor: isPopular
                            ? Theme
                            .of(context)
                            .colorScheme
                            .onPrimary
                            : Theme
                            .of(context)
                            .colorScheme
                            .primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: isPopular
                              ? BorderSide.none
                              : BorderSide(color: Theme
                              .of(context)
                              .colorScheme
                              .primary),
                        ),
                      ),
                      child: const Text('Buy'),
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

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          'By subscribing, you agree to our Terms of Service and Privacy Policy. Cancel anytime.',
          style: Theme
              .of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
            color: Theme
                .of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _showRestorePurchases(context),
          child: const Text('Restore Purchases'),
        ),
      ],
    );
  }

  void _purchasePremium(BuildContext context, PremiumProvider provider) async {
    final success = await provider.purchasePremium();
    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium subscription activated!')),
      );
    }
  }

  void _purchaseQuestionPack(BuildContext context, PremiumProvider provider,
      String packId) async {
    final success = await provider.purchaseQuestionPack(packId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question pack purchased!')),
      );
    }
  }

  void _showRestorePurchases(BuildContext context) async {
    final provider = Provider.of<PremiumProvider>(context, listen: false);
    await provider.restorePurchases();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase restoration completed')),
      );
    }
  }
}