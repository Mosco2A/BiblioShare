import '../../../core/services/supabase_service.dart';
import '../../../shared/models/book_model.dart';

/// Service CRUD pour les livres dans Supabase
class BookService {
  BookService._();

  static final _table = SupabaseService.client.from('books');

  /// Récupère tous les livres d'un utilisateur
  static Future<List<BookModel>> getBooks(String userId) async {
    final response = await _table
        .select()
        .eq('user_id', userId)
        .order('date_added', ascending: false);

    return (response as List)
        .map((json) => BookModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Récupère un livre par son ID
  static Future<BookModel?> getBook(String bookId) async {
    final response =
        await _table.select().eq('id', bookId).maybeSingle();
    if (response == null) return null;
    return BookModel.fromJson(response);
  }

  /// Ajoute un livre
  static Future<BookModel> addBook(BookModel book) async {
    final response =
        await _table.insert(book.toInsertJson()).select().single();
    return BookModel.fromJson(response);
  }

  /// Ajoute plusieurs livres d'un coup (batch insert après scan)
  static Future<List<BookModel>> addBooks(List<BookModel> books) async {
    if (books.isEmpty) return [];
    final response = await _table
        .insert(books.map((b) => b.toInsertJson()).toList())
        .select();
    return (response as List)
        .map((json) => BookModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Met à jour un livre
  static Future<void> updateBook(
    String bookId,
    Map<String, dynamic> updates,
  ) async {
    await _table.update(updates).eq('id', bookId);
  }

  /// Supprime un livre
  static Future<void> deleteBook(String bookId) async {
    await _table.delete().eq('id', bookId);
  }

  /// Recherche de livres par texte (full-text search PostgreSQL)
  static Future<List<BookModel>> searchBooks(
    String userId,
    String query,
  ) async {
    final response = await _table
        .select()
        .eq('user_id', userId)
        .textSearch('search_vector', query, config: 'french')
        .limit(20);

    return (response as List)
        .map((json) => BookModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Compte le nombre de livres d'un utilisateur
  static Future<int> countBooks(String userId) async {
    final response = await SupabaseService.client
        .from('books')
        .select('id')
        .eq('user_id', userId);
    return (response as List).length;
  }

  /// Vérifie si un livre avec cet ISBN existe déjà dans la bibliothèque
  static Future<bool> bookExistsByIsbn(
    String userId,
    String isbn13,
  ) async {
    final response = await _table
        .select('id')
        .eq('user_id', userId)
        .eq('isbn_13', isbn13)
        .maybeSingle();
    return response != null;
  }
}
