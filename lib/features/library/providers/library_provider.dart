import 'package:flutter/foundation.dart';

import '../../../shared/models/book_model.dart';
import '../services/book_service.dart';

/// Provider pour la bibliothèque de livres
class LibraryProvider extends ChangeNotifier {
  List<BookModel> _books = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BookModel> get books => _books;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get bookCount => _books.length;
  bool get isEmpty => _books.isEmpty;

  /// Charger les livres d'un utilisateur
  Future<void> loadBooks(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _books = await BookService.getBooks(userId);
    } catch (e) {
      _errorMessage = 'Impossible de charger la bibliothèque';
      debugPrint('LibraryProvider.loadBooks error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Ajouter un livre localement (après ajout Supabase)
  void addBookLocal(BookModel book) {
    _books.insert(0, book);
    notifyListeners();
  }

  /// Ajouter plusieurs livres localement (après scan)
  void addBooksLocal(List<BookModel> books) {
    _books.insertAll(0, books);
    notifyListeners();
  }

  /// Supprimer un livre
  Future<void> deleteBook(String bookId) async {
    await BookService.deleteBook(bookId);
    _books.removeWhere((b) => b.id == bookId);
    notifyListeners();
  }

  /// Rechercher dans la bibliothèque locale
  List<BookModel> searchLocal(String query) {
    final lower = query.toLowerCase();
    return _books.where((b) {
      return b.title.toLowerCase().contains(lower) ||
          b.authorsDisplay.toLowerCase().contains(lower) ||
          (b.isbn13?.contains(lower) ?? false);
    }).toList();
  }
}
