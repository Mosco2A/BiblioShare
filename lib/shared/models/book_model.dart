/// Modèle livre BiblioShare (synchronisé avec Supabase `books`)
class BookModel {
  final String id;
  final String userId;

  // Identification
  final String? isbn10;
  final String? isbn13;
  final String title;
  final String? originalTitle;
  final String? subtitle;
  final List<BookAuthor> authors;
  final String? publisher;
  final String? collection;
  final DateTime? publicationDate;
  final String language;

  // Détails physiques
  final int? pageCount;
  final String? format; // 'poche', 'grand_format', 'epub'

  // Contenu
  final String? description;
  final List<String> genres;
  final List<String> themes;
  final List<String> keywords;
  final String? coverUrl;

  // Communauté
  final double? goodreadsRating;
  final double? babelioRating;

  // Possession
  final String condition; // 'new', 'good', 'fair', 'poor'
  final bool nonLendable;
  final DateTime dateAdded;

  // Scan
  final int? scanConfidence;
  final String? scanPhotoUrl;
  final ShelfPosition? shelfPosition;

  const BookModel({
    required this.id,
    required this.userId,
    this.isbn10,
    this.isbn13,
    required this.title,
    this.originalTitle,
    this.subtitle,
    this.authors = const [],
    this.publisher,
    this.collection,
    this.publicationDate,
    this.language = 'fr',
    this.pageCount,
    this.format,
    this.description,
    this.genres = const [],
    this.themes = const [],
    this.keywords = const [],
    this.coverUrl,
    this.goodreadsRating,
    this.babelioRating,
    this.condition = 'good',
    this.nonLendable = false,
    required this.dateAdded,
    this.scanConfidence,
    this.scanPhotoUrl,
    this.shelfPosition,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      isbn10: json['isbn_10'] as String?,
      isbn13: json['isbn_13'] as String?,
      title: json['title'] as String,
      originalTitle: json['original_title'] as String?,
      subtitle: json['subtitle'] as String?,
      authors: _parseAuthors(json['authors']),
      publisher: json['publisher'] as String?,
      collection: json['collection'] as String?,
      publicationDate: json['publication_date'] != null
          ? DateTime.tryParse(json['publication_date'] as String)
          : null,
      language: json['language'] as String? ?? 'fr',
      pageCount: json['page_count'] as int?,
      format: json['format'] as String?,
      description: json['description'] as String?,
      genres: (json['genres'] as List<dynamic>?)?.cast<String>() ?? [],
      themes: (json['themes'] as List<dynamic>?)?.cast<String>() ?? [],
      keywords: (json['keywords'] as List<dynamic>?)?.cast<String>() ?? [],
      coverUrl: json['cover_url'] as String?,
      goodreadsRating: (json['goodreads_rating'] as num?)?.toDouble(),
      babelioRating: (json['babelio_rating'] as num?)?.toDouble(),
      condition: json['condition'] as String? ?? 'good',
      nonLendable: json['non_lendable'] as bool? ?? false,
      dateAdded: DateTime.parse(
        json['date_added'] as String? ?? DateTime.now().toIso8601String(),
      ),
      scanConfidence: json['scan_confidence'] as int?,
      scanPhotoUrl: json['scan_photo_url'] as String?,
      shelfPosition: json['shelf_position'] != null
          ? ShelfPosition.fromJson(
              json['shelf_position'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'isbn_10': isbn10,
      'isbn_13': isbn13,
      'title': title,
      'original_title': originalTitle,
      'subtitle': subtitle,
      'authors': authors.map((a) => a.toJson()).toList(),
      'publisher': publisher,
      'collection': collection,
      'publication_date': publicationDate?.toIso8601String().split('T').first,
      'language': language,
      'page_count': pageCount,
      'format': format,
      'description': description,
      'genres': genres,
      'themes': themes,
      'keywords': keywords,
      'cover_url': coverUrl,
      'goodreads_rating': goodreadsRating,
      'babelio_rating': babelioRating,
      'condition': condition,
      'non_lendable': nonLendable,
      'scan_confidence': scanConfidence,
      'scan_photo_url': scanPhotoUrl,
      'shelf_position': shelfPosition?.toJson(),
    };
  }

  /// JSON pour insertion (sans id ni date_added, générés par Supabase)
  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id');
    json.remove('date_added');
    return json;
  }

  BookModel copyWith({
    String? isbn10,
    String? isbn13,
    String? title,
    String? originalTitle,
    String? subtitle,
    List<BookAuthor>? authors,
    String? publisher,
    String? collection,
    DateTime? publicationDate,
    String? language,
    int? pageCount,
    String? format,
    String? description,
    List<String>? genres,
    List<String>? themes,
    List<String>? keywords,
    String? coverUrl,
    double? goodreadsRating,
    double? babelioRating,
    String? condition,
    bool? nonLendable,
    int? scanConfidence,
    String? scanPhotoUrl,
    ShelfPosition? shelfPosition,
  }) {
    return BookModel(
      id: id,
      userId: userId,
      isbn10: isbn10 ?? this.isbn10,
      isbn13: isbn13 ?? this.isbn13,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      subtitle: subtitle ?? this.subtitle,
      authors: authors ?? this.authors,
      publisher: publisher ?? this.publisher,
      collection: collection ?? this.collection,
      publicationDate: publicationDate ?? this.publicationDate,
      language: language ?? this.language,
      pageCount: pageCount ?? this.pageCount,
      format: format ?? this.format,
      description: description ?? this.description,
      genres: genres ?? this.genres,
      themes: themes ?? this.themes,
      keywords: keywords ?? this.keywords,
      coverUrl: coverUrl ?? this.coverUrl,
      goodreadsRating: goodreadsRating ?? this.goodreadsRating,
      babelioRating: babelioRating ?? this.babelioRating,
      condition: condition ?? this.condition,
      nonLendable: nonLendable ?? this.nonLendable,
      dateAdded: dateAdded,
      scanConfidence: scanConfidence ?? this.scanConfidence,
      scanPhotoUrl: scanPhotoUrl ?? this.scanPhotoUrl,
      shelfPosition: shelfPosition ?? this.shelfPosition,
    );
  }

  static List<BookAuthor> _parseAuthors(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .map((e) => BookAuthor.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Nom d'affichage des auteurs (ex: "Albert Camus, Isaac Asimov")
  String get authorsDisplay {
    if (authors.isEmpty) return 'Auteur inconnu';
    return authors.map((a) => a.displayName).join(', ');
  }
}

/// Auteur d'un livre
class BookAuthor {
  final String name;
  final String? role; // 'auteur', 'traducteur', 'illustrateur'

  const BookAuthor({required this.name, this.role});

  factory BookAuthor.fromJson(Map<String, dynamic> json) {
    return BookAuthor(
      name: json['name'] as String? ?? 'Inconnu',
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'role': role};

  String get displayName => name;
}

/// Position d'un livre sur l'étagère
class ShelfPosition {
  final int shelf;
  final int position;

  const ShelfPosition({required this.shelf, required this.position});

  factory ShelfPosition.fromJson(Map<String, dynamic> json) {
    return ShelfPosition(
      shelf: json['shelf'] as int? ?? 1,
      position: json['position'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {'shelf': shelf, 'position': position};
}
