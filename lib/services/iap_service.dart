import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();

  factory IAPService() => _instance;

  IAPService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs
  static const String premiumSubscriptionId = 'ai_study_buddy_premium';
  static const String questionPack50Id = 'question_pack_50';
  static const String questionPack100Id = 'question_pack_100';
  static const String questionPack500Id = 'question_pack_500';

  // Available products
  static const Set<String> _productIds = {
    premiumSubscriptionId,
    questionPack50Id,
    questionPack100Id,
    questionPack500Id,
  };

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Getters
  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  // Callbacks
  Function(PurchaseDetails)? onPurchaseSuccess;
  Function(String)? onPurchaseError;
  Function(PurchaseDetails)? onPurchaseRestored;

  Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;

    try {
      _isLoading = true;

      // Add timeout to prevent hanging
      await Future.any([
        _initializeWithTimeout(),
        Future.delayed(const Duration(seconds: 10)), // 10 second timeout
      ]);

    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('IAP initialization error: $e');
    } finally {
      _isLoading = false;
      _isInitialized = true;
    }
  }

  Future<void> _initializeWithTimeout() async {
    // Check if in-app purchases are available
    _isAvailable = await _inAppPurchase.isAvailable();

    if (!_isAvailable) {
      _error = 'In-app purchases not available on this device';
      if (kDebugMode) print('IAP not available');
      return;
    }

    // Setup purchase listener
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        if (kDebugMode) print('Purchase stream closed');
      },
      onError: (error) {
        if (kDebugMode) print('Purchase stream error: $error');
        _error = error.toString();
      },
    );

    // Load available products
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_productIds)
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Product loading timed out'),
      );

      if (response.notFoundIDs.isNotEmpty) {
        if (kDebugMode) print('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;

      if (kDebugMode) {
        print('Loaded ${_products.length} products');
        for (final product in _products) {
          print('Product: ${product.id} - ${product.title} - ${product.price}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading products: $e');
      _error = e.toString();
    }
  }

  Future<bool> purchasePremium() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final product = _products.firstWhere(
            (p) => p.id == premiumSubscriptionId,
        orElse: () => throw Exception('Premium subscription not found'),
      );

      return await _purchaseProduct(product);
    } catch (e) {
      if (kDebugMode) print('Purchase premium error: $e');
      onPurchaseError?.call(e.toString());
      return false;
    }
  }

  Future<bool> purchaseQuestionPack(String packId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final product = _products.firstWhere(
            (p) => p.id == packId,
        orElse: () => throw Exception('Question pack not found: $packId'),
      );

      return await _purchaseProduct(product);
    } catch (e) {
      if (kDebugMode) print('Purchase question pack error: $e');
      onPurchaseError?.call(e.toString());
      return false;
    }
  }

  Future<bool> _purchaseProduct(ProductDetails product) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: product);

      bool success = false;

      if (product.id == premiumSubscriptionId) {
        // Subscription purchase
        success =
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // Consumable purchase (question packs)
        success =
        await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }

      return success;
    } catch (e) {
      if (kDebugMode) print('Purchase error: $e');
      onPurchaseError?.call(e.toString());
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      if (kDebugMode) print('Restore purchases error: $e');
      onPurchaseError?.call('Failed to restore purchases: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  void _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      // Purchase successful
      if (kDebugMode) {
        print('Purchase successful: ${purchaseDetails.productID}');
      }

      await _verifyPurchase(purchaseDetails);
      onPurchaseSuccess?.call(purchaseDetails);
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      // Purchase error
      if (kDebugMode) print('Purchase error: ${purchaseDetails.error}');
      onPurchaseError?.call(
          purchaseDetails.error?.message ?? 'Purchase failed');
    } else if (purchaseDetails.status == PurchaseStatus.restored) {
      // Purchase restored
      if (kDebugMode) print('Purchase restored: ${purchaseDetails.productID}');
      onPurchaseRestored?.call(purchaseDetails);
    }

    // Complete the purchase (important for consumables)
    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // In a real app, you should verify the purchase with your backend server
    // This is crucial for security to prevent fraudulent purchases

    if (Platform.isIOS) {
      // iOS receipt verification
      final receipt = purchaseDetails.verificationData.serverVerificationData;
      // Send receipt to your server for verification
      if (kDebugMode) print('iOS receipt: $receipt');
    } else if (Platform.isAndroid) {
      // Android purchase token verification
      final purchaseToken = purchaseDetails.verificationData
          .serverVerificationData;
      // Send purchase token to your server for verification
      if (kDebugMode) print('Android purchase token: $purchaseToken');
    }
  }

  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  String getProductPrice(String productId) {
    final product = getProduct(productId);
    return product?.price ?? 'N/A';
  }

  String getProductTitle(String productId) {
    final product = getProduct(productId);
    return product?.title ?? 'Product';
  }

  String getProductDescription(String productId) {
    final product = getProduct(productId);
    return product?.description ?? '';
  }

  // Helper methods for specific products
  String get premiumPrice => getProductPrice(premiumSubscriptionId);

  String get questionPack50Price => getProductPrice(questionPack50Id);

  String get questionPack100Price => getProductPrice(questionPack100Id);

  String get questionPack500Price => getProductPrice(questionPack500Id);

  bool get hasPremiumProduct => getProduct(premiumSubscriptionId) != null;

  bool get hasQuestionPacks =>
      _products.any((p) => p.id.contains('question_pack'));

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  void clearError() {
    _error = null;
  }
}