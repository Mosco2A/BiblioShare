import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

/// Singleton d'accès au client Supabase
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  /// Sync un utilisateur Firebase vers Supabase
  /// Appelle l'Edge Function sync-user avec le Firebase JWT
  static Future<Map<String, dynamic>?> syncUser({
    required String firebaseUid,
    required String? displayName,
    required String? email,
    required String? phone,
    required String? photoUrl,
    required List<String> authProviders,
  }) async {
    try {
      final response = await client.functions.invoke(
        'sync-user',
        body: {
          'firebase_uid': firebaseUid,
          'display_name': displayName ?? 'Utilisateur',
          'email': email,
          'phone': phone,
          'photo_url': photoUrl,
          'auth_providers': authProviders,
        },
      );
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      // Edge function not deployed yet — log and continue
      // ignore: avoid_print
      print('SupabaseService.syncUser error: $e');
      return null;
    }
  }

  /// Récupère le profil utilisateur depuis Supabase
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await client.from('users').select().eq('id', userId).maybeSingle();
      return response;
    } catch (e) {
      // ignore: avoid_print
      print('SupabaseService.getUserProfile error: $e');
      return null;
    }
  }

  /// Met à jour le profil utilisateur
  static Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await client.from('users').update(data).eq('id', userId);
  }

  /// Marque l'onboarding comme terminé
  static Future<void> completeOnboarding(String userId) async {
    await updateUserProfile(userId, {'onboarding_completed': true});
  }
}
