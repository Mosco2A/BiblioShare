import '../../../core/services/supabase_service.dart';
import '../../../shared/models/friendship_model.dart';
import '../../../shared/models/user_model.dart';

/// Service CRUD pour le module social (amis, invitations, feed)
class SocialService {
  SocialService._();

  static final _friendships = SupabaseService.client.from('friendships');
  static final _invitations = SupabaseService.client.from('invitations');
  static final _feed = SupabaseService.client.from('social_feed');
  static final _users = SupabaseService.client.from('users');

  // ──────────── AMIS ────────────

  /// Recupere la liste d'amis acceptes
  static Future<List<FriendshipModel>> getFriends(String userId) async {
    final response = await _friendships
        .select()
        .or('requester_id.eq.$userId,receiver_id.eq.$userId')
        .eq('status', 'accepted')
        .order('accepted_at', ascending: false);
    return (response as List)
        .map((j) => FriendshipModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Recupere les demandes en attente (recues)
  static Future<List<FriendshipModel>> getPendingRequests(
      String userId) async {
    final response = await _friendships
        .select()
        .eq('receiver_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (response as List)
        .map((j) => FriendshipModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Envoie une demande d'ami
  static Future<FriendshipModel> sendFriendRequest(
    String requesterId,
    String receiverId, {
    String source = 'search',
  }) async {
    final response = await _friendships
        .insert({
          'requester_id': requesterId,
          'receiver_id': receiverId,
          'status': 'pending',
          'source': source,
        })
        .select()
        .single();
    return FriendshipModel.fromJson(response);
  }

  /// Accepte une demande d'ami
  static Future<void> acceptFriendRequest(String friendshipId) async {
    await _friendships.update({
      'status': 'accepted',
      'accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', friendshipId);
  }

  /// Refuse/bloque une demande
  static Future<void> rejectFriendRequest(String friendshipId) async {
    await _friendships.delete().eq('id', friendshipId);
  }

  /// Supprime un ami
  static Future<void> removeFriend(String friendshipId) async {
    await _friendships.delete().eq('id', friendshipId);
  }

  // ──────────── RECHERCHE UTILISATEURS ────────────

  /// Recherche un utilisateur par username ou nom
  static Future<List<UserModel>> searchUsers(String query) async {
    final response = await _users
        .select()
        .or('username.ilike.%$query%,display_name.ilike.%$query%')
        .limit(20);
    return (response as List)
        .map((j) => UserModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Recupere le profil d'un utilisateur
  static Future<UserModel?> getUserProfile(String userId) async {
    final response =
        await _users.select().eq('id', userId).maybeSingle();
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  // ──────────── INVITATIONS ────────────

  /// Cree une invitation
  static Future<void> createInvitation({
    required String inviterId,
    required String channel,
    String? phone,
    String? email,
  }) async {
    await _invitations.insert({
      'inviter_id': inviterId,
      'channel': channel,
      'recipient_phone': phone,
      'recipient_email': email,
      'status': 'sent',
      'sent_at': DateTime.now().toIso8601String(),
    });
  }

  /// Compte les invitations envoyees
  static Future<int> invitationCount(String userId) async {
    final response = await _invitations
        .select('id')
        .eq('inviter_id', userId);
    return (response as List).length;
  }

  /// Compte les amis qui se sont inscrits via invitation
  static Future<int> convertedInvitations(String userId) async {
    final response = await _invitations
        .select('id')
        .eq('inviter_id', userId)
        .eq('status', 'registered');
    return (response as List).length;
  }

  // ──────────── FIL SOCIAL ────────────

  /// Recupere le fil d'activite des amis
  static Future<List<Map<String, dynamic>>> getFeed(
    String userId, {
    int limit = 30,
    int offset = 0,
  }) async {
    // Recupere les IDs des amis
    final friends = await getFriends(userId);
    if (friends.isEmpty) return [];

    final friendIds = friends.map((f) => f.otherUserId(userId)).toList();

    final response = await _feed
        .select()
        .inFilter('user_id', friendIds)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Publie une activite sur le fil
  static Future<void> postActivity({
    required String userId,
    required String actionType,
    String? bookId,
    Map<String, dynamic>? metadata,
  }) async {
    await _feed.insert({
      'user_id': userId,
      'action_type': actionType,
      'book_id': bookId,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
