import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      _user = _auth.currentUser;

      // Listen to auth state changes
      _auth.authStateChanges().listen((User? user) {
        _user = user;
        if (user != null) {
          // Load user data in background without blocking
          _loadUserDataInBackground();
        } else {
          _userModel = null;
        }
        notifyListeners();
      });

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing auth: $e');
      }
      _isInitialized = true; // Still mark as initialized
    }
    notifyListeners();
  }

  // Load user data in background without blocking UI
  void _loadUserDataInBackground() async {
    if (_user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    }
  }


  Future<bool> signUpWithEmail(String email, String password,
      String displayName) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await result.user!.updateDisplayName(displayName);

        // Create user document in Firestore
        final userModel = UserModel(
          id: result.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(result.user!.uid).set(
            userModel.toFirestore());

        _user = result.user;
        _userModel = userModel;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error signing up: $e');
      }
    }
    return false;
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        _user = result.user;

        // Update last login time in background
        _updateLastLoginInBackground();

        // Load user data in background
        _loadUserDataInBackground();

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error signing in: $e');
      }
    }
    return false;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userModel = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending password reset email: $e');
      }
      throw e;
    }
  }

  Future<void> updateProfile(String displayName) async {
    try {
      if (_user != null) {
        await _user!.updateDisplayName(displayName);
        await _firestore.collection('users').doc(_user!.uid).update({
          'displayName': displayName,
        });
        _loadUserDataInBackground();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
    }
  }

  /// Update FirebaseAuth and Firestore displayName for current user
  Future<void> updateDisplayName(String displayName) async {
    try {
      if (_user != null) {
        await _user!.updateDisplayName(displayName);
        await _user!.reload();
        _user = _auth.currentUser;

        // Update in Firestore as well
        await _firestore.collection('users').doc(_user!.uid).update({
          'displayName': displayName,
        });

        _loadUserDataInBackground();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating display name: $e');
      }
      throw e;
    }
  }

  Future<void> incrementQuestionCount() async {
    try {
      if (_user != null && _userModel != null) {
        final newCount = _userModel!.questionsUsed + 1;
        await _firestore.collection('users').doc(_user!.uid).update({
          'questionsUsed': newCount,
        });
        _loadUserDataInBackground();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error incrementing question count: $e');
      }
    }
  }

  bool canAskQuestion() {
    if (_userModel == null)
      return true; // Allow questions if user data not loaded yet
    return _userModel!.isPremium ||
        _userModel!.questionsUsed < _userModel!.maxQuestions;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _updateLastLoginInBackground() async {
    if (_user == null) return;

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating last login: $e');
      }
    }
  }
}