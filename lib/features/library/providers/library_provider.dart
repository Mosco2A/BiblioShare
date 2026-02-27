import 'package:flutter/foundation.dart';

import '../../../core/services/seed_data_service.dart';
import '../../../shared/models/book_model.dart';
import '../services/book_service.dart';

/// Provider pour la bibliotheque de livres
class LibraryProvider extends ChangeNotifier {
  List<BookModel> _books = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;

  List<BookModel> get books => _books;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get bookCount => _books.length;
  bool get isEmpty => _books.isEmpty;

  /// Charger les livres d'un utilisateur
  Future<void> loadBooks(String userId) async {
    if (_currentUserId == userId && _books.isNotEmpty) return;
    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _books = await BookService.getBooks(userId)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('LibraryProvider.loadBooks error: $e');
      // Fallback : charger les données de démo si la liste est vide
      if (_books.isEmpty) {
        _books = SeedDataService.getDemoBooks(userId);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Forcer le rechargement
  Future<void> refresh(String userId) async {
    _currentUserId = null;
    await loadBooks(userId);
  }

  /// Ajouter un livre localement (apres ajout Supabase)
  void addBookLocal(BookModel book) {
    _books.insert(0, book);
    notifyListeners();
  }

  /// Ajouter plusieurs livres localement (apres scan)
  void addBooksLocal(List<BookModel> books) {
    _books.insertAll(0, books);
    notifyListeners();
  }

  /// Ajouter un livre a Supabase et localement
  Future<BookModel?> addBook(BookModel book) async {
    try {
      final saved = await BookService.addBook(book);
      _books.insert(0, saved);
      notifyListeners();
      return saved;
    } catch (e) {
      debugPrint('LibraryProvider.addBook error: $e');
      // Ajouter localement meme si Supabase echoue
      _books.insert(0, book);
      notifyListeners();
      return book;
    }
  }

  /// Ajouter plusieurs livres a Supabase et localement
  Future<int> addBooks(List<BookModel> books) async {
    if (books.isEmpty) return 0;
    try {
      final saved = await BookService.addBooks(books)
          .timeout(const Duration(seconds: 5));
      _books.insertAll(0, saved);
      notifyListeners();
      return saved.length;
    } catch (e) {
      debugPrint('LibraryProvider.addBooks error: $e');
      // Ajouter localement meme si Supabase echoue
      _books.insertAll(0, books);
      notifyListeners();
      return books.length;
    }
  }

  /// Supprimer un livre
  Future<void> deleteBook(String bookId) async {
    try {
      await BookService.deleteBook(bookId);
    } catch (e) {
      debugPrint('LibraryProvider.deleteBook error: $e');
    }
    _books.removeWhere((b) => b.id == bookId);
    notifyListeners();
  }

  /// Mettre a jour un livre localement
  Future<void> updateBookLocal(String bookId, {String? title, String? condition}) async {
    final index = _books.indexWhere((b) => b.id == bookId);
    if (index == -1) return;

    _books[index] = _books[index].copyWith(
      title: title,
      condition: condition,
    );
    notifyListeners();

    // Try to update in Supabase too
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (condition != null) updates['condition'] = condition;
      if (updates.isNotEmpty) {
        await BookService.updateBook(bookId, updates);
      }
    } catch (e) {
      debugPrint('LibraryProvider.updateBookLocal error: $e');
    }
  }

  /// Rechercher dans la bibliotheque locale
  List<BookModel> searchLocal(String query) {
    final lower = query.toLowerCase();
    return _books.where((b) {
      return b.title.toLowerCase().contains(lower) ||
          b.authorsDisplay.toLowerCase().contains(lower) ||
          (b.isbn13?.contains(lower) ?? false);
    }).toList();
  }
}
