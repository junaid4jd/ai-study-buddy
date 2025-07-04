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

  User? get user => _user;

  UserModel? get userModel => _userModel;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData();
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    }
    notifyListeners();
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

        // Update last login time
        await _firestore.collection('users').doc(_user!.uid).update({
          'lastLoginAt': Timestamp.fromDate(DateTime.now()),
        });

        await _loadUserData();
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
        print('Error resetting password: $e');
      }
      rethrow;
    }
  }

  Future<void> updateProfile(String displayName) async {
    try {
      if (_user != null) {
        await _user!.updateDisplayName(displayName);
        await _firestore.collection('users').doc(_user!.uid).update({
          'displayName': displayName,
        });
        await _loadUserData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
    }
  }

  Future<void> updateUserStats(Map<String, dynamic> stats) async {
    try {
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'studyStats': stats,
        });
        await _loadUserData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user stats: $e');
      }
    }
  }

  Future<void> incrementQuestionCount() async {
    try {
      if (_user != null && _userModel != null) {
        final newCount = _userModel!.questionsUsed + 1;
        await _firestore.collection('users').doc(_user!.uid).update({
          'questionsUsed': newCount,
        });
        await _loadUserData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error incrementing question count: $e');
      }
    }
  }

  bool canAskQuestion() {
    if (_userModel == null) return false;
    return _userModel!.isPremium ||
        _userModel!.questionsUsed < _userModel!.maxQuestions;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}