import 'package:flutter/foundation.dart';

import '../../../shared/models/user_model.dart';
import '../../../shared/models/user_settings_model.dart';
import '../services/profile_service.dart';

/// Provider pour le profil et les paramètres
class ProfileProvider extends ChangeNotifier {
  UserModel? _profile;
  UserSettingsModel? _settings;
  bool _isLoading = false;

  UserModel? get profile => _profile;
  UserSettingsModel? get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    _profile = await ProfileService.getProfile(userId);
    _settings = await ProfileService.getSettings(userId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(
      String userId, Map<String, dynamic> updates) async {
    await ProfileService.updateProfile(userId, updates);
    _profile = await ProfileService.getProfile(userId);
    notifyListeners();
  }

  Future<void> updateSettings(
      String userId, Map<String, dynamic> updates) async {
    await ProfileService.updateSettings(userId, updates);
    _settings = await ProfileService.getSettings(userId);
    notifyListeners();
  }

  Future<bool> checkUsername(String username) async {
    return await ProfileService.isUsernameAvailable(username);
  }
}
