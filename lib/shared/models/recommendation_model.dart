/// Modele recommandation BiblioShare (table `recommendations`)
class RecommendationModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String bookId;

  final String? messageText;
  final bool messageGeneratedByAi;
  final bool includesLoanOffer;

  final RecoStatus status;
  final bool receiverThanks;
  final double? receiverRating;
  final String? discussionThreadId;

  final int? matchScore;
  final List<String> matchReasons;
  final String triggerType;
  final String sentVia;

  final DateTime createdAt;
  final DateTime? seenAt;
  final DateTime? finishedAt;

  const RecommendationModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.bookId,
    this.messageText,
    this.messageGeneratedByAi = false,
    this.includesLoanOffer = false,
    this.status = RecoStatus.sent,
    this.receiverThanks = false,
    this.receiverRating,
    this.discussionThreadId,
    this.matchScore,
    this.matchReasons = const [],
    this.triggerType = 'manual',
    this.sentVia = 'in_app',
    required this.createdAt,
    this.seenAt,
    this.finishedAt,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      bookId: json['book_id'] as String,
      messageText: json['message_text'] as String?,
      messageGeneratedByAi:
          json['message_generated_by_ai'] as bool? ?? false,
      includesLoanOffer: json['includes_loan_offer'] as bool? ?? false,
      status: _parseStatus(json['status'] as String?),
      receiverThanks: json['receiver_thanks'] as bool? ?? false,
      receiverRating: (json['receiver_rating'] as num?)?.toDouble(),
      discussionThreadId: json['discussion_thread_id'] as String?,
      matchScore: json['match_score'] as int?,
      matchReasons:
          (json['match_reasons'] as List<dynamic>?)?.cast<String>() ?? [],
      triggerType: json['trigger_type'] as String? ?? 'manual',
      sentVia: json['sent_via'] as String? ?? 'in_app',
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      seenAt: json['seen_at'] != null
          ? DateTime.tryParse(json['seen_at'] as String)
          : null,
      finishedAt: json['finished_at'] != null
          ? DateTime.tryParse(json['finished_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'book_id': bookId,
      'message_text': messageText,
      'message_generated_by_ai': messageGeneratedByAi,
      'includes_loan_offer': includesLoanOffer,
      'status': status.name,
      'match_score': matchScore,
      'match_reasons': matchReasons,
      'trigger_type': triggerType,
      'sent_via': sentVia,
    };
  }

  bool get isSeen => seenAt != null;
  bool get isFinished => finishedAt != null;

  static RecoStatus _parseStatus(String? raw) {
    return switch (raw) {
      'seen' => RecoStatus.seen,
      'wishlisted' => RecoStatus.wishlisted,
      'borrowed' => RecoStatus.borrowed,
      'reading' => RecoStatus.reading,
      'finished' => RecoStatus.finished,
      'declined_politely' => RecoStatus.declinedPolitely,
      'expired' => RecoStatus.expired,
      _ => RecoStatus.sent,
    };
  }
}

enum RecoStatus {
  sent,
  seen,
  wishlisted,
  borrowed,
  reading,
  finished,
  declinedPolitely,
  expired,
}
