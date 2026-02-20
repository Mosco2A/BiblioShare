import '../../../core/services/supabase_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/user_settings_model.dart';

/// Service de gestion du profil utilisateur
class ProfileService {
  ProfileService._();

  /// Récupère le profil complet
  static Future<UserModel?> getProfile(String userId) async {
    final data = await SupabaseService.getUserProfile(userId);
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  /// Met à jour le profil
  static Future<void> updateProfile(
      String userId, Map<String, dynamic> updates) async {
    await SupabaseService.updateUserProfile(userId, updates);
  }

  /// Récupère les paramètres utilisateur
  static Future<UserSettingsModel?> getSettings(String userId) async {
    try {
      final data = await SupabaseService.client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserSettingsModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Met à jour les paramètres
  static Future<void> updateSettings(
      String userId, Map<String, dynamic> updates) async {
    updates['user_id'] = userId;
    await SupabaseService.client
        .from('user_settings')
        .upsert(updates, onConflict: 'user_id');
  }

  /// Vérifie la disponibilité d'un username
  static Future<bool> isUsernameAvailable(String username) async {
    final data = await SupabaseService.client
        .from('users')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return data == null;
  }
}
