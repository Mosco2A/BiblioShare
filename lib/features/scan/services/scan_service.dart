import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/scan_result_model.dart';

/// Service de scan d'etagere — envoie la photo a l'Edge Function
/// qui appelle Claude Vision pour identifier les livres.
/// Inclut un mode demo si l'Edge Function n'est pas deployee.
class ScanService {
  ScanService._();

  /// Analyse une photo d'etagere via Claude Vision (Edge Function)
  /// Fallback: retourne des donnees demo si l'Edge Function echoue
  static Future<ScanResult> analyzeShelfPhoto(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final response = await SupabaseService.client.functions.invoke(
        'scan-shelf',
        body: {
          'image': base64Image,
          'media_type': 'image/jpeg',
        },
      );

      final data = response.data as Map<String, dynamic>;
      return ScanResult.fromJson(data);
    } catch (e) {
      debugPrint('ScanService.analyzeShelfPhoto error: $e');
      debugPrint('Falling back to demo scan results');
      return _demoScanResult();
    }
  }

  /// Enrichit un livre detecte via Google Books (Edge Function)
  static Future<DetectedBook> enrichBook(DetectedBook book) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        'enrich-book',
        body: {
          'title': book.detectedTitle,
          'author': book.detectedAuthor,
          'publisher': book.detectedPublisher,
        },
      );

      final data = response.data as Map<String, dynamic>;

      return book.copyWith(
        isbn13: data['isbn_13'] as String?,
        coverUrl: data['cover_url'] as String?,
        pageCount: data['page_count'] as int?,
        description: data['description'] as String?,
        genres: (data['genres'] as List<dynamic>?)?.cast<String>(),
        detectedTitle: data['title'] as String? ?? book.detectedTitle,
        detectedAuthor: data['author'] as String? ?? book.detectedAuthor,
        confidence: data['confidence'] as int? ?? book.confidence,
      );
    } catch (e) {
      debugPrint('ScanService.enrichBook error: $e');
      return book;
    }
  }

  /// Enrichit tous les livres detectes en parallele
  static Future<List<DetectedBook>> enrichAllBooks(
    List<DetectedBook> books,
  ) async {
    // Si les Edge Functions ne sont pas deployees, retourner tel quel
    // Les livres demo ont deja des donnees enrichies
    try {
      final futures = books.map((book) => enrichBook(book));
      return Future.wait(futures);
    } catch (e) {
      return books;
    }
  }

  /// Donnees demo realistes pour tester le flux complet
  static ScanResult _demoScanResult() {
    return ScanResult(
      shelves: [
        ShelfScanResult(
          number: 1,
          books: [
            const DetectedBook(
              position: 1,
              detectedTitle: "L'Etranger",
              detectedAuthor: 'Albert Camus',
              detectedPublisher: 'Gallimard',
              confidence: 95,
              isbn13: '9782070360024',
              coverUrl:
                  'https://covers.openlibrary.org/b/isbn/9782070360024-L.jpg',
              pageCount: 186,
              description:
                  "Aujourd'hui, maman est morte. Ou peut-etre hier, je ne sais pas. Le recit d'un homme confronte a l'absurdite de l'existence.",
              genres: ['Classique', 'Philosophie'],
              confirmed: true,
            ),
            const DetectedBook(
              position: 2,
              detectedTitle: 'Le Petit Prince',
              detectedAuthor: 'Antoine de Saint-Exupery',
              detectedPublisher: 'Gallimard',
              confidence: 98,
              isbn13: '9782070612758',
              coverUrl:
                  'https://covers.openlibrary.org/b/isbn/9782070612758-L.jpg',
              pageCount: 96,
              description:
                  "Un pilote d'avion, tombe en panne dans le desert du Sahara, rencontre un petit garcon venu d'une autre planete.",
              genres: ['Conte', 'Classique'],
              confirmed: true,
            ),
            const DetectedBook(
              position: 3,
              detectedTitle: 'Fahrenheit 451',
              detectedAuthor: 'Ray Bradbury',
              detectedPublisher: 'Gallimard',
              confidence: 90,
              isbn13: '9782070415731',
              coverUrl:
                  'https://covers.openlibrary.org/b/isbn/9782070415731-L.jpg',
              pageCount: 224,
              description:
                  'Dans un futur dystopique, les pompiers ne sont plus charges d\'eteindre des incendies mais de bruler les livres.',
              genres: ['Science-fiction', 'Dystopie'],
              confirmed: true,
            ),
            const DetectedBook(
              position: 4,
              detectedTitle: 'Sapiens',
              detectedAuthor: 'Yuval Noah Harari',
              detectedPublisher: 'Albin Michel',
              confidence: 88,
              isbn13: '9782226257017',
              coverUrl:
                  'https://covers.openlibrary.org/b/isbn/9782226257017-L.jpg',
              pageCount: 512,
              description:
                  "Une breve histoire de l'humanite, des premiers hommes a l'ere de l'intelligence artificielle.",
              genres: ['Essai', 'Histoire'],
              confirmed: true,
            ),
            const DetectedBook(
              position: 5,
              detectedTitle: 'Dune',
              detectedAuthor: 'Frank Herbert',
              detectedPublisher: 'Pocket',
              confidence: 92,
              isbn13: '9782266320481',
              coverUrl:
                  'https://covers.openlibrary.org/b/isbn/9782266320481-L.jpg',
              pageCount: 928,
              description:
                  "L'epopee de Paul Atreides sur la planete desert Arrakis, seule source de l'Epice, la substance la plus precieuse de l'univers.",
              genres: ['Science-fiction', 'Aventure'],
              confirmed: true,
            ),
            const DetectedBook(
              position: 6,
              detectedTitle: 'Les Fleurs du Mal',
              detectedAuthor: 'Charles Baudelaire',
              detectedPublisher: 'Le Livre de Poche',
              confidence: 85,
              isbn13: '9782253004257',
              coverUrl:
                  'https://covers.openlibrary.org/b/isbn/9782253004257-L.jpg',
              pageCount: 352,
              description:
                  "Le recueil de poemes qui a revolutionne la poesie francaise, entre spleen et ideal.",
              genres: ['Poesie', 'Classique'],
              confirmed: true,
            ),
          ],
        ),
      ],
      stats: const ScanStats(
        totalBooks: 6,
        highConfidence: 6,
        partial: 0,
        unreadable: 0,
      ),
    );
  }
}
