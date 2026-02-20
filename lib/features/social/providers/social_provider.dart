import 'package:flutter/foundation.dart';

import '../../../shared/models/friendship_model.dart';
import '../../../shared/models/user_model.dart';
import '../services/social_service.dart';

/// Provider pour le module social (amis, recherche, feed)
class SocialProvider extends ChangeNotifier {
  List<FriendshipModel> _friends = [];
  List<FriendshipModel> _pendingRequests = [];
  List<Map<String, dynamic>> _feed = [];
  List<UserModel> _searchResults = [];
  bool _loading = false;
  String? _error;

  List<FriendshipModel> get friends => _friends;
  List<FriendshipModel> get pendingRequests => _pendingRequests;
  List<Map<String, dynamic>> get feed => _feed;
  List<UserModel> get searchResults => _searchResults;
  bool get loading => _loading;
  String? get error => _error;

  int get friendCount => _friends.length;
  int get pendingCount => _pendingRequests.length;

  /// Charge les amis et les demandes en attente
  Future<void> loadFriends(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        SocialService.getFriends(userId),
        SocialService.getPendingRequests(userId),
      ]);
      _friends = results[0];
      _pendingRequests = results[1];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Charge le fil social
  Future<void> loadFeed(String userId) async {
    _loading = true;
    notifyListeners();

    try {
      _feed = await SocialService.getFeed(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Recherche des utilisateurs
  Future<void> searchUsers(String query) async {
    if (query.length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _searchResults = await SocialService.searchUsers(query);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  /// Envoie une demande d'ami
  Future<void> sendFriendRequest(
    String requesterId,
    String receiverId, {
    String source = 'search',
  }) async {
    try {
      final friendship = await SocialService.sendFriendRequest(
        requesterId,
        receiverId,
        source: source,
      );
      _pendingRequests.add(friendship);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Accepte une demande d'ami
  Future<void> acceptRequest(String friendshipId) async {
    try {
      await SocialService.acceptFriendRequest(friendshipId);
      final request = _pendingRequests.firstWhere((f) => f.id == friendshipId);
      _pendingRequests.removeWhere((f) => f.id == friendshipId);
      _friends.insert(0, FriendshipModel(
        id: request.id,
        requesterId: request.requesterId,
        receiverId: request.receiverId,
        status: FriendshipStatus.accepted,
        groupTags: request.groupTags,
        source: request.source,
        createdAt: request.createdAt,
        acceptedAt: DateTime.now(),
      ));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Refuse une demande
  Future<void> rejectRequest(String friendshipId) async {
    try {
      await SocialService.rejectFriendRequest(friendshipId);
      _pendingRequests.removeWhere((f) => f.id == friendshipId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Supprime un ami
  Future<void> removeFriend(String friendshipId) async {
    try {
      await SocialService.removeFriend(friendshipId);
      _friends.removeWhere((f) => f.id == friendshipId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
}
