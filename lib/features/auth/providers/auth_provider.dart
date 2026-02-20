import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  authenticated,
  onboarding,
}

/// Provider d'authentification — écoute Firebase Auth et sync Supabase
class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  User? _firebaseUser;
  UserModel? _userProfile;
  StreamSubscription<User?>? _authSubscription;
  bool _isLoading = false;

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAnonymous => _firebaseUser?.isAnonymous ?? false;
  String? get userId => _firebaseUser?.uid;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authSubscription = AuthService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;

    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _userProfile = null;
    } else {
      // Sync avec Supabase
      await _syncWithSupabase(user);

      // Vérifier si onboarding terminé
      if (_userProfile != null && _userProfile!.onboardingCompleted) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.onboarding;
      }
    }

    notifyListeners();
  }

  Future<void> _syncWithSupabase(User user) async {
    try {
      // Tenter de sync via Edge Function
      await SupabaseService.syncUser(
        firebaseUid: user.uid,
        displayName: user.displayName,
        email: user.email,
        phone: user.phoneNumber,
        photoUrl: user.photoURL,
        authProviders: AuthService.linkedProviders,
      );

      // Charger le profil
      final profileData = await SupabaseService.getUserProfile(user.uid);
      if (profileData != null) {
        _userProfile = UserModel.fromJson(profileData);
      }
    } catch (e) {
      debugPrint('Supabase sync error: $e');
      // Continue sans profil Supabase — sera créé plus tard
    }
  }

  // ── Actions ──

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (userId == null) return;
    await SupabaseService.completeOnboarding(userId!);
    _userProfile = _userProfile?.copyWith(onboardingCompleted: true);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    _status = AuthStatus.unauthenticated;
    _firebaseUser = null;
    _userProfile = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (userId == null) return;
    final profileData = await SupabaseService.getUserProfile(userId!);
    if (profileData != null) {
      _userProfile = UserModel.fromJson(profileData);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
