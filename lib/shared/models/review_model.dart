/// Modèle avis/note BiblioShare (synchronisé avec Supabase `reviews`)
class ReviewModel {
  final String id;
  final String userId;
  final String bookId;

  // Notes
  final double? ratingGlobal;
  final double? ratingStory;
  final double? ratingWriting;
  final double? ratingDepth;
  final double? ratingEmotion;
  final double? ratingPacing;
  final double? ratingOriginality;

  // Avis
  final String? reviewText;
  final String visibility; // 'private', 'friends', 'public'
  final List<String> tags;
  final String? privateNotes;

  // Lecture
  final ReadingStatus readingStatus;
  final int? currentPage;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  // Méta
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.bookId,
    this.ratingGlobal,
    this.ratingStory,
    this.ratingWriting,
    this.ratingDepth,
    this.ratingEmotion,
    this.ratingPacing,
    this.ratingOriginality,
    this.reviewText,
    this.visibility = 'friends',
    this.tags = const [],
    this.privateNotes,
    this.readingStatus = ReadingStatus.unread,
    this.currentPage,
    this.startedAt,
    this.finishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      ratingGlobal: (json['rating_global'] as num?)?.toDouble(),
      ratingStory: (json['rating_story'] as num?)?.toDouble(),
      ratingWriting: (json['rating_writing'] as num?)?.toDouble(),
      ratingDepth: (json['rating_depth'] as num?)?.toDouble(),
      ratingEmotion: (json['rating_emotion'] as num?)?.toDouble(),
      ratingPacing: (json['rating_pacing'] as num?)?.toDouble(),
      ratingOriginality: (json['rating_originality'] as num?)?.toDouble(),
      reviewText: json['review_text'] as String?,
      visibility: json['visibility'] as String? ?? 'friends',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      privateNotes: json['private_notes'] as String?,
      readingStatus: _parseStatus(json['reading_status'] as String?),
      currentPage: json['current_page'] as int?,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      finishedAt: json['finished_at'] != null
          ? DateTime.tryParse(json['finished_at'] as String)
          : null,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'book_id': bookId,
      'rating_global': ratingGlobal,
      'rating_story': ratingStory,
      'rating_writing': ratingWriting,
      'rating_depth': ratingDepth,
      'rating_emotion': ratingEmotion,
      'rating_pacing': ratingPacing,
      'rating_originality': ratingOriginality,
      'review_text': reviewText,
      'visibility': visibility,
      'tags': tags,
      'private_notes': privateNotes,
      'reading_status': readingStatus.name,
      'current_page': currentPage,
      'started_at': startedAt?.toIso8601String().split('T').first,
      'finished_at': finishedAt?.toIso8601String().split('T').first,
    };
  }

  ReviewModel copyWith({
    double? ratingGlobal,
    double? ratingStory,
    double? ratingWriting,
    double? ratingDepth,
    double? ratingEmotion,
    double? ratingPacing,
    double? ratingOriginality,
    String? reviewText,
    String? visibility,
    List<String>? tags,
    String? privateNotes,
    ReadingStatus? readingStatus,
    int? currentPage,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return ReviewModel(
      id: id,
      userId: userId,
      bookId: bookId,
      ratingGlobal: ratingGlobal ?? this.ratingGlobal,
      ratingStory: ratingStory ?? this.ratingStory,
      ratingWriting: ratingWriting ?? this.ratingWriting,
      ratingDepth: ratingDepth ?? this.ratingDepth,
      ratingEmotion: ratingEmotion ?? this.ratingEmotion,
      ratingPacing: ratingPacing ?? this.ratingPacing,
      ratingOriginality: ratingOriginality ?? this.ratingOriginality,
      reviewText: reviewText ?? this.reviewText,
      visibility: visibility ?? this.visibility,
      tags: tags ?? this.tags,
      privateNotes: privateNotes ?? this.privateNotes,
      readingStatus: readingStatus ?? this.readingStatus,
      currentPage: currentPage ?? this.currentPage,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get hasRating => ratingGlobal != null;
  bool get hasReview => reviewText != null && reviewText!.isNotEmpty;
  bool get isFinished => readingStatus == ReadingStatus.finished;
  bool get isReading => readingStatus == ReadingStatus.reading;

  double? get progressPercent {
    if (currentPage == null) return null;
    // Nécessite le total pages du livre — calculé côté UI
    return null;
  }

  static ReadingStatus _parseStatus(String? raw) {
    return switch (raw) {
      'reading' => ReadingStatus.reading,
      'finished' => ReadingStatus.finished,
      'abandoned' => ReadingStatus.abandoned,
      _ => ReadingStatus.unread,
    };
  }
}

enum ReadingStatus { unread, reading, finished, abandoned }
