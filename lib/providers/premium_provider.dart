import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/iap_service.dart';
import '../services/achievement_service.dart';
import '../models/user_model.dart';

class PremiumProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final IAPService _iapService = IAPService();
  final AchievementService _achievementService = AchievementService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;

  bool get isLoading => _isLoading;

  String? get error => _error;

  // Premium status getters
  bool get isPremium => _user?.isPremium ?? false;

  int get questionsUsed => _user?.questionsUsed ?? 0;

  int get maxQuestions => _user?.maxQuestions ?? 10;

  int get questionsRemaining => maxQuestions - questionsUsed;

  bool get hasQuestionsRemaining => questionsRemaining > 0;

  bool get isQuestionLimitReached => !isPremium && questionsRemaining <= 0;

  Future<void> loadUser(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _user = UserModel.fromFirestore(doc);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('Error loading user: $e');
    }
  }

  Future<void> initializeIAP() async {
    try {
      await _iapService.initialize();

      // Set up purchase callbacks
      _iapService.onPurchaseSuccess = _handlePurchaseSuccess;
      _iapService.onPurchaseError = _handlePurchaseError;
      _iapService.onPurchaseRestored = _handlePurchaseRestored;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) print('Error initializing IAP: $e');
    }
  }

  Future<bool> incrementQuestionUsage(String userId) async {
    if (_user == null) return false;

    // Check if user can ask questions
    if (isQuestionLimitReached) {
      _error =
      'Daily question limit reached. Upgrade to premium for unlimited questions!';
      notifyListeners();
      return false;
    }

    try {
      final newQuestionsUsed = _user!.questionsUsed + 1;

      await _firestore.collection('users').doc(userId).update({
        'questionsUsed': newQuestionsUsed,
      });

      _user = _user!.copyWith(questionsUsed: newQuestionsUsed);
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) print('Error incrementing question usage: $e');
      return false;
    }
  }

  Future<void> resetDailyQuestions(String userId) async {
    if (_user == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'questionsUsed': 0,
      });

      _user = _user!.copyWith(questionsUsed: 0);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) print('Error resetting daily questions: $e');
    }
  }

  Future<bool> purchasePremium() async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _iapService.purchasePremium();

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('Error purchasing premium: $e');
      return false;
    }
  }

  Future<bool> purchaseQuestionPack(String packId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _iapService.purchaseQuestionPack(packId);

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('Error purchasing question pack: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _iapService.restorePurchases();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('Error restoring purchases: $e');
    }
  }

  void _handlePurchaseSuccess(PurchaseDetails purchaseDetails) async {
    if (_user == null) return;

    try {
      if (purchaseDetails.productID == IAPService.premiumSubscriptionId) {
        // Premium subscription purchased
        await _upgradeToPremium(_user!.id);

        // Track achievement
        await _achievementService.trackPremiumUpgrade(_user!.id);
      } else if (purchaseDetails.productID.contains('question_pack')) {
        // Question pack purchased
        await _addQuestionPack(_user!.id, purchaseDetails.productID);
      }

      if (kDebugMode) {
        print('Purchase successful: ${purchaseDetails.productID}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling purchase success: $e');
      }
    }
  }

  void _handlePurchaseError(String error) {
    _error = error;
    notifyListeners();
    if (kDebugMode) print('Purchase error: $error');
  }

  void _handlePurchaseRestored(PurchaseDetails purchaseDetails) async {
    if (_user == null) return;

    try {
      if (purchaseDetails.productID == IAPService.premiumSubscriptionId) {
        await _upgradeToPremium(_user!.id);
      }

      if (kDebugMode) print('Purchase restored: ${purchaseDetails.productID}');
    } catch (e) {
      if (kDebugMode) print('Error handling purchase restore: $e');
    }
  }

  Future<void> _upgradeToPremium(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isPremium': true,
        'maxQuestions': -1, // Unlimited questions
      });

      _user = _user!.copyWith(
        isPremium: true,
        maxQuestions: -1,
      );

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error upgrading to premium: $e');
    }
  }

  Future<void> _addQuestionPack(String userId, String packId) async {
    try {
      int additionalQuestions = 0;

      switch (packId) {
        case IAPService.questionPack50Id:
          additionalQuestions = 50;
          break;
        case IAPService.questionPack100Id:
          additionalQuestions = 100;
          break;
        case IAPService.questionPack500Id:
          additionalQuestions = 500;
          break;
      }

      final newMaxQuestions = _user!.maxQuestions + additionalQuestions;

      await _firestore.collection('users').doc(userId).update({
        'maxQuestions': newMaxQuestions,
      });

      _user = _user!.copyWith(maxQuestions: newMaxQuestions);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error adding question pack: $e');
    }
  }

  // Premium feature access checks
  bool canAccessAdvancedAnalytics() => isPremium;

  bool canAccessUnlimitedAI() => isPremium;

  bool canAccessPrioritySupport() => isPremium;

  bool canAccessCustomPrompts() => isPremium;

  bool canAccessVoiceFeatures() => isPremium;

  bool canExportData() => isPremium;

  // IAP Product information
  String get premiumPrice => _iapService.premiumPrice;

  String get questionPack50Price => _iapService.questionPack50Price;

  String get questionPack100Price => _iapService.questionPack100Price;

  String get questionPack500Price => _iapService.questionPack500Price;

  bool get hasIAPProducts => _iapService.hasPremiumProduct;

  List<ProductDetails> get availableProducts => _iapService.products;

  // Helper methods for UI
  String getQuestionLimitText() {
    if (isPremium) return 'Unlimited questions';
    return '$questionsRemaining questions remaining today';
  }

  Color getQuestionLimitColor() {
    if (isPremium) return const Color(0xFF4CAF50); // Green
    if (questionsRemaining > 5) return const Color(0xFF2196F3); // Blue
    if (questionsRemaining > 0) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  String getPremiumBenefits() {
    return '''
• Unlimited AI questions
• Advanced analytics & insights
• Custom study plans
• Priority customer support
• Export your data
• Voice interaction features
• Early access to new features
''';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _iapService.dispose();
    super.dispose();
  }
}