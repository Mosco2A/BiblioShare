/// Modele relation d'amitie BiblioShare (table `friendships`)
class FriendshipModel {
  final String id;
  final String requesterId;
  final String receiverId;
  final FriendshipStatus status;
  final List<String> groupTags;
  final String source;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  const FriendshipModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    this.groupTags = const [],
    this.source = 'search',
    required this.createdAt,
    this.acceptedAt,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      receiverId: json['receiver_id'] as String,
      status: _parseStatus(json['status'] as String?),
      groupTags: (json['group_tags'] as List<dynamic>?)?.cast<String>() ?? [],
      source: json['source'] as String? ?? 'search',
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requester_id': requesterId,
      'receiver_id': receiverId,
      'status': status.name,
      'group_tags': groupTags,
      'source': source,
    };
  }

  /// Retourne l'ID de l'autre personne
  String otherUserId(String myId) =>
      requesterId == myId ? receiverId : requesterId;

  bool get isPending => status == FriendshipStatus.pending;
  bool get isAccepted => status == FriendshipStatus.accepted;

  static FriendshipStatus _parseStatus(String? raw) {
    return switch (raw) {
      'accepted' => FriendshipStatus.accepted,
      'blocked' => FriendshipStatus.blocked,
      _ => FriendshipStatus.pending,
    };
  }
}

enum FriendshipStatus { pending, accepted, blocked }
