import 'package:flutter/foundation.dart';

import '../../../shared/models/book_model.dart';
import '../../../shared/models/scan_result_model.dart';
import '../../library/services/book_service.dart';
import '../services/scan_service.dart';

enum ScanState { idle, scanning, enriching, results, error }

/// Provider pour le workflow de scan d'étagère
class ScanProvider extends ChangeNotifier {
  ScanState _state = ScanState.idle;
  ScanResult? _scanResult;
  List<DetectedBook> _detectedBooks = [];
  String? _errorMessage;
  Uint8List? _photoBytes;

  ScanState get state => _state;
  ScanResult? get scanResult => _scanResult;
  List<DetectedBook> get detectedBooks => _detectedBooks;
  String? get errorMessage => _errorMessage;
  Uint8List? get photoBytes => _photoBytes;

  int get confirmedCount => _detectedBooks.where((b) => b.confirmed).length;
  int get rejectedCount => _detectedBooks.where((b) => b.rejected).length;
  int get pendingCount =>
      _detectedBooks.where((b) => !b.confirmed && !b.rejected).length;

  /// Lancer l'analyse d'une photo d'étagère
  Future<void> analyzePhoto(Uint8List imageBytes) async {
    _photoBytes = imageBytes;
    _state = ScanState.scanning;
    _errorMessage = null;
    notifyListeners();

    try {
      // Étape 1 : analyse par Claude Vision
      _scanResult = await ScanService.analyzeShelfPhoto(imageBytes);
      _detectedBooks = _scanResult!.allBooks;
      _state = ScanState.enriching;
      notifyListeners();

      // Étape 2 : enrichissement Google Books en parallèle
      _detectedBooks = await ScanService.enrichAllBooks(_detectedBooks);
      _state = ScanState.results;
    } catch (e) {
      _state = ScanState.error;
      _errorMessage = 'Erreur lors du scan : $e';
    }
    notifyListeners();
  }

  /// Confirmer un livre détecté
  void confirmBook(int index) {
    if (index >= 0 && index < _detectedBooks.length) {
      _detectedBooks[index] =
          _detectedBooks[index].copyWith(confirmed: true, rejected: false);
      notifyListeners();
    }
  }

  /// Rejeter un livre détecté
  void rejectBook(int index) {
    if (index >= 0 && index < _detectedBooks.length) {
      _detectedBooks[index] =
          _detectedBooks[index].copyWith(confirmed: false, rejected: true);
      notifyListeners();
    }
  }

  /// Confirmer tous les livres à haute confiance
  void confirmAllHighConfidence() {
    _detectedBooks = _detectedBooks.map((b) {
      if (b.isHighConfidence && !b.rejected) {
        return b.copyWith(confirmed: true);
      }
      return b;
    }).toList();
    notifyListeners();
  }

  /// Corriger manuellement un livre détecté
  void updateBook(int index, {String? title, String? author}) {
    if (index >= 0 && index < _detectedBooks.length) {
      _detectedBooks[index] = _detectedBooks[index].copyWith(
        detectedTitle: title,
        detectedAuthor: author,
      );
      notifyListeners();
    }
  }

  /// Ajouter les livres confirmés à la bibliothèque Supabase
  Future<int> saveConfirmedBooks(String userId) async {
    final confirmed = _detectedBooks.where((b) => b.confirmed).toList();
    if (confirmed.isEmpty) return 0;

    final books = confirmed.map((d) {
      return BookModel(
        id: '', // Sera généré par Supabase
        userId: userId,
        isbn13: d.isbn13,
        title: d.detectedTitle,
        authors: d.detectedAuthor != null
            ? [BookAuthor(name: d.detectedAuthor!)]
            : [],
        publisher: d.detectedPublisher,
        coverUrl: d.coverUrl,
        pageCount: d.pageCount,
        description: d.description,
        genres: d.genres ?? [],
        scanConfidence: d.confidence,
        dateAdded: DateTime.now(),
      );
    }).toList();

    final saved = await BookService.addBooks(books);
    return saved.length;
  }

  /// Réinitialiser pour un nouveau scan
  void reset() {
    _state = ScanState.idle;
    _scanResult = null;
    _detectedBooks = [];
    _errorMessage = null;
    _photoBytes = null;
    notifyListeners();
  }
}
