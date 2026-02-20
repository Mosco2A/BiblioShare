/// Résultat d'un scan d'étagère complet (retourné par Claude Vision)
class ScanResult {
  final List<ShelfScanResult> shelves;
  final ScanStats stats;

  const ScanResult({required this.shelves, required this.stats});

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      shelves: (json['etageres'] as List<dynamic>?)
              ?.map((e) =>
                  ShelfScanResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stats: ScanStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// Tous les livres détectés, toutes étagères confondues
  List<DetectedBook> get allBooks =>
      shelves.expand((s) => s.books).toList();
}

/// Une étagère détectée dans la photo
class ShelfScanResult {
  final int number;
  final List<DetectedBook> books;

  const ShelfScanResult({required this.number, required this.books});

  factory ShelfScanResult.fromJson(Map<String, dynamic> json) {
    return ShelfScanResult(
      number: json['numero'] as int? ?? 1,
      books: (json['livres'] as List<dynamic>?)
              ?.map(
                  (e) => DetectedBook.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Un livre individuel détecté par le scan
class DetectedBook {
  final int position;
  final String detectedTitle;
  final String? detectedAuthor;
  final String? detectedPublisher;
  final int confidence; // 0-100
  final DetectionStatus status;
  final String? appearance;
  final List<String> alternativeCandidates;

  // Champs enrichis (remplis après l'appel Google Books)
  final String? isbn13;
  final String? coverUrl;
  final int? pageCount;
  final String? description;
  final List<String>? genres;

  // État de validation par l'utilisateur
  final bool confirmed;
  final bool rejected;

  const DetectedBook({
    required this.position,
    required this.detectedTitle,
    this.detectedAuthor,
    this.detectedPublisher,
    required this.confidence,
    this.status = DetectionStatus.complete,
    this.appearance,
    this.alternativeCandidates = const [],
    this.isbn13,
    this.coverUrl,
    this.pageCount,
    this.description,
    this.genres,
    this.confirmed = false,
    this.rejected = false,
  });

  factory DetectedBook.fromJson(Map<String, dynamic> json) {
    return DetectedBook(
      position: json['position'] as int? ?? 0,
      detectedTitle: json['titre_detecte'] as String? ?? 'Inconnu',
      detectedAuthor: json['auteur_detecte'] as String?,
      detectedPublisher: json['editeur_detecte'] as String?,
      confidence: json['confiance'] as int? ?? 0,
      status: _parseStatus(json['statut'] as String?),
      appearance: json['apparence'] as String?,
      alternativeCandidates:
          (json['candidats_alternatifs'] as List<dynamic>?)
                  ?.cast<String>() ??
              [],
      isbn13: json['isbn_13'] as String?,
      coverUrl: json['cover_url'] as String?,
      pageCount: json['page_count'] as int?,
      description: json['description'] as String?,
      genres:
          (json['genres'] as List<dynamic>?)?.cast<String>(),
    );
  }

  DetectedBook copyWith({
    String? detectedTitle,
    String? detectedAuthor,
    String? detectedPublisher,
    int? confidence,
    DetectionStatus? status,
    String? isbn13,
    String? coverUrl,
    int? pageCount,
    String? description,
    List<String>? genres,
    bool? confirmed,
    bool? rejected,
  }) {
    return DetectedBook(
      position: position,
      detectedTitle: detectedTitle ?? this.detectedTitle,
      detectedAuthor: detectedAuthor ?? this.detectedAuthor,
      detectedPublisher: detectedPublisher ?? this.detectedPublisher,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      appearance: appearance,
      alternativeCandidates: alternativeCandidates,
      isbn13: isbn13 ?? this.isbn13,
      coverUrl: coverUrl ?? this.coverUrl,
      pageCount: pageCount ?? this.pageCount,
      description: description ?? this.description,
      genres: genres ?? this.genres,
      confirmed: confirmed ?? this.confirmed,
      rejected: rejected ?? this.rejected,
    );
  }

  static DetectionStatus _parseStatus(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'COMPLET':
        return DetectionStatus.complete;
      case 'PARTIEL':
        return DetectionStatus.partial;
      case 'ILLISIBLE':
        return DetectionStatus.unreadable;
      default:
        return DetectionStatus.complete;
    }
  }

  bool get isHighConfidence => confidence >= 70;
  bool get needsUserInput =>
      status != DetectionStatus.complete || confidence < 50;
}

enum DetectionStatus { complete, partial, unreadable }

/// Stats globales du scan
class ScanStats {
  final int totalBooks;
  final int highConfidence;
  final int partial;
  final int unreadable;

  const ScanStats({
    this.totalBooks = 0,
    this.highConfidence = 0,
    this.partial = 0,
    this.unreadable = 0,
  });

  factory ScanStats.fromJson(Map<String, dynamic> json) {
    return ScanStats(
      totalBooks: json['total_livres'] as int? ?? 0,
      highConfidence: json['identifies_confiance_haute'] as int? ?? 0,
      partial: json['partiels'] as int? ?? 0,
      unreadable: json['illisibles'] as int? ?? 0,
    );
  }
}
