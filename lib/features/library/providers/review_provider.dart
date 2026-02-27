import 'package:flutter/foundation.dart';

import '../../../shared/models/review_model.dart';
import '../services/review_service.dart';

/// Provider pour les avis et le journal de lecture
class ReviewProvider extends ChangeNotifier {
  final Map<String, ReviewModel> _reviews = {};
  List<ReviewModel> _currentlyReading = [];
  bool _loading = false;

  bool get loading => _loading;
  List<ReviewModel> get currentlyReading => _currentlyReading;

  /// Recupere un avis existant (cache local ou Supabase)
  Future<ReviewModel?> loadReview(String userId, String bookId) async {
    final key = '$userId:$bookId';
    if (_reviews.containsKey(key)) return _reviews[key];

    final review = await ReviewService.getReview(userId, bookId);
    if (review != null) {
      _reviews[key] = review;
    }
    return review;
  }

  /// Sauvegarde un avis (upsert)
  Future<void> saveReview(ReviewModel review) async {
    final saved = await ReviewService.upsertReview(review);
    final key = '${saved.userId}:${saved.bookId}';
    _reviews[key] = saved;
    notifyListeners();
  }

  /// Met a jour le statut de lecture
  Future<void> updateReadingStatus(
    String userId,
    String bookId,
    ReadingStatus status, {
    int? currentPage,
  }) async {
    await ReviewService.updateReadingStatus(
      userId,
      bookId,
      status,
      currentPage: currentPage,
    );
    // Invalider le cache
    _reviews.remove('$userId:$bookId');
    notifyListeners();
  }

  /// Met a jour la progression
  Future<void> updateProgress(
    String userId,
    String bookId,
    int currentPage,
  ) async {
    await ReviewService.updateProgress(userId, bookId, currentPage);
    _reviews.remove('$userId:$bookId');
    notifyListeners();
  }

  /// Charge les livres en cours de lecture
  Future<void> loadCurrentlyReading(String userId) async {
    _loading = true;
    notifyListeners();

    try {
      _currentlyReading = await ReviewService.getCurrentlyReading(userId);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Nombre de livres termines cette annee
  Future<int> booksFinishedThisYear(String userId) async {
    return ReviewService.booksFinishedThisYear(userId);
  }

  /// Recupere l'avis depuis le cache (synchrone)
  ReviewModel? getCachedReview(String userId, String bookId) {
    return _reviews['$userId:$bookId'];
  }
}
