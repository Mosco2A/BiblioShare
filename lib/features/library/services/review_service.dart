import '../../../core/services/supabase_service.dart';
import '../../../shared/models/review_model.dart';

/// Service CRUD pour les avis/notes dans Supabase
class ReviewService {
  ReviewService._();

  static final _table = SupabaseService.client.from('reviews');

  /// Récupère l'avis d'un utilisateur pour un livre
  static Future<ReviewModel?> getReview(String userId, String bookId) async {
    final response = await _table
        .select()
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .maybeSingle();
    if (response == null) return null;
    return ReviewModel.fromJson(response);
  }

  /// Récupère tous les avis d'un utilisateur
  static Future<List<ReviewModel>> getUserReviews(String userId) async {
    final response = await _table
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return (response as List)
        .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Crée ou met à jour un avis (upsert sur user_id + book_id)
  static Future<ReviewModel> upsertReview(ReviewModel review) async {
    final data = review.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();

    final response = await _table
        .upsert(data, onConflict: 'user_id,book_id')
        .select()
        .single();
    return ReviewModel.fromJson(response);
  }

  /// Met à jour le statut de lecture
  static Future<void> updateReadingStatus(
    String userId,
    String bookId,
    ReadingStatus status, {
    int? currentPage,
  }) async {
    final data = <String, dynamic>{
      'reading_status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (status == ReadingStatus.reading && currentPage != null) {
      data['current_page'] = currentPage;
      data['started_at'] ??= DateTime.now().toIso8601String().split('T').first;
    }

    if (status == ReadingStatus.finished) {
      data['finished_at'] = DateTime.now().toIso8601String().split('T').first;
    }

    // Upsert — crée l'entrée si elle n'existe pas
    await _table.upsert({
      'user_id': userId,
      'book_id': bookId,
      ...data,
    }, onConflict: 'user_id,book_id');
  }

  /// Met à jour la progression de lecture
  static Future<void> updateProgress(
    String userId,
    String bookId,
    int currentPage,
  ) async {
    await _table.upsert({
      'user_id': userId,
      'book_id': bookId,
      'current_page': currentPage,
      'reading_status': 'reading',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,book_id');
  }

  /// Récupère les livres "en cours de lecture"
  static Future<List<ReviewModel>> getCurrentlyReading(String userId) async {
    final response = await _table
        .select()
        .eq('user_id', userId)
        .eq('reading_status', 'reading')
        .order('updated_at', ascending: false);
    return (response as List)
        .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Compte les livres terminés cette année
  static Future<int> booksFinishedThisYear(String userId) async {
    final year = DateTime.now().year;
    final response = await _table
        .select('id')
        .eq('user_id', userId)
        .eq('reading_status', 'finished')
        .gte('finished_at', '$year-01-01');
    return (response as List).length;
  }
}
