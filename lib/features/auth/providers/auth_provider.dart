import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  authenticated,
  onboarding,
}

/// Provider d'authentification — ecoute Firebase Auth et sync Supabase
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
      // Tenter de sync avec Supabase
      await _syncWithSupabase(user);

      // Verifier onboarding : profil Supabase OU fallback local
      final onboardingDone = _userProfile?.onboardingCompleted ??
          await _getLocalOnboardingStatus(user.uid);

      if (onboardingDone) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.onboarding;
      }
    }

    notifyListeners();
  }

  Future<void> _syncWithSupabase(User user) async {
    try {
      // D'abord essayer de charger le profil existant
      final profileData = await SupabaseService.getUserProfile(user.uid);

      if (profileData != null) {
        _userProfile = UserModel.fromJson(profileData);
      } else {
        // Pas de profil → creer directement dans Supabase
        await _createSupabaseProfile(user);
      }
    } catch (e) {
      debugPrint('Supabase sync error: $e');
      // Continuer sans profil Supabase — fallback local
    }
  }

  /// Cree le profil utilisateur directement dans la table users
  Future<void> _createSupabaseProfile(User user) async {
    try {
      final username = _generateUsername(user);
      final data = {
        'id': user.uid,
        'display_name': user.displayName ?? 'Utilisateur',
        'username': username,
        'email': user.email,
        'phone': user.phoneNumber,
        'photo_url': user.photoURL,
        'auth_providers': AuthService.linkedProviders,
        'onboarding_completed': false,
        'locale': 'fr',
        'timezone': 'Europe/Paris',
      };

      await SupabaseService.client.from('users').upsert(data);

      // Recharger le profil
      final profileData = await SupabaseService.getUserProfile(user.uid);
      if (profileData != null) {
        _userProfile = UserModel.fromJson(profileData);
      }
    } catch (e) {
      debugPrint('Create Supabase profile error: $e');
    }
  }

  String _generateUsername(User user) {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '')
          .substring(0, (user.displayName!.length).clamp(0, 15));
    }
    return 'user_${user.uid.substring(0, 8)}';
  }

  // ── Onboarding local fallback ──

  Future<bool> _getLocalOnboardingStatus(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('onboarding_done_$uid') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _setLocalOnboardingStatus(String uid, bool done) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done_$uid', done);
    } catch (e) {
      debugPrint('SharedPreferences error: $e');
    }
  }

  // ── Actions ──

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (userId == null) return;

    // Sauvegarder en local d'abord (toujours fiable)
    await _setLocalOnboardingStatus(userId!, true);

    // Tenter de mettre a jour Supabase
    try {
      await SupabaseService.completeOnboarding(userId!);
      _userProfile = _userProfile?.copyWith(onboardingCompleted: true);
    } catch (e) {
      debugPrint('completeOnboarding Supabase error: $e');
    }

    // Passer a authenticated dans tous les cas
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
    try {
      final profileData = await SupabaseService.getUserProfile(userId!);
      if (profileData != null) {
        _userProfile = UserModel.fromJson(profileData);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('refreshProfile error: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
