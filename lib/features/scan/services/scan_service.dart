import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

import '../../../shared/models/scan_result_model.dart';

/// Service de scan d'étagère — OCR local (ML Kit) + Google Books API.
/// Analyse réellement la photo pour détecter les livres sur l'étagère.
class ScanService {
  ScanService._();

  static const _googleBooksBase =
      'https://www.googleapis.com/books/v1/volumes';

  /// Analyse une photo d'étagère :
  /// 1. OCR avec Google ML Kit (local, gratuit)
  /// 2. Extraction des titres candidats
  /// 3. Recherche Google Books API pour chaque candidat
  static Future<ScanResult> analyzeShelfPhoto(Uint8List imageBytes) async {
    // Écrire l'image dans un fichier temporaire pour ML Kit
    final tempDir = Directory.systemTemp;
    final tempFile = File(
      '${tempDir.path}/biblioshare_scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(imageBytes);

    try {
      // OCR avec ML Kit
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      debugPrint(
        'ScanService: OCR terminé — ${recognizedText.blocks.length} blocs détectés',
      );
      debugPrint('ScanService: Texte brut = ${recognizedText.text}');

      // Extraire les candidats de titres de livres
      final candidates = _extractBookCandidates(recognizedText);
      debugPrint('ScanService: ${candidates.length} candidats extraits');

      if (candidates.isEmpty) {
        return ScanResult(
          shelves: [const ShelfScanResult(number: 1, books: [])],
          stats: const ScanStats(totalBooks: 0),
        );
      }

      // Rechercher chaque candidat sur Google Books (max 15)
      final limitedCandidates = candidates.take(15).toList();
      final books = <DetectedBook>[];
      final seenIsbns = <String>{};

      for (int i = 0; i < limitedCandidates.length; i++) {
        final candidate = limitedCandidates[i];
        try {
          final book = await _searchGoogleBooks(candidate, i + 1);
          if (book != null) {
            // Dédupliquer par ISBN
            if (book.isbn13 != null && seenIsbns.contains(book.isbn13)) {
              continue;
            }
            if (book.isbn13 != null) seenIsbns.add(book.isbn13!);
            books.add(book);
          }
        } catch (e) {
          debugPrint('ScanService: Erreur Google Books pour "$candidate": $e');
        }
      }

      debugPrint('ScanService: ${books.length} livres trouvés via Google Books');

      final highConf = books.where((b) => b.confidence >= 70).length;
      final partial =
          books.where((b) => b.confidence >= 30 && b.confidence < 70).length;

      return ScanResult(
        shelves: [ShelfScanResult(number: 1, books: books)],
        stats: ScanStats(
          totalBooks: books.length,
          highConfidence: highConf,
          partial: partial,
          unreadable: 0,
        ),
      );
    } finally {
      // Nettoyage du fichier temporaire
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// Extraire les titres candidats depuis le texte OCR.
  /// Chaque TextBlock sur une étagère correspond souvent à un dos de livre.
  static List<String> _extractBookCandidates(RecognizedText text) {
    final candidates = <String>[];
    final seen = <String>{};

    for (final block in text.blocks) {
      // Recombiner les lignes du bloc
      final lines = block.lines.map((l) => l.text.trim()).toList();

      // Stratégie 1 : le bloc entier comme un candidat
      final fullBlock = lines.join(' ').trim();
      if (fullBlock.length >= 3 && !_isNoise(fullBlock)) {
        final normalized = _normalize(fullBlock);
        if (!seen.contains(normalized)) {
          seen.add(normalized);
          candidates.add(fullBlock);
        }
      }

      // Stratégie 2 : chaque ligne individuelle (si le bloc a plusieurs lignes)
      // Utile quand un bloc contient titre + auteur séparés
      if (lines.length > 1) {
        for (final line in lines) {
          if (line.length >= 4 && !_isNoise(line)) {
            final normalized = _normalize(line);
            if (!seen.contains(normalized)) {
              seen.add(normalized);
              candidates.add(line);
            }
          }
        }
      }
    }

    // Trier : les textes les plus longs en premier (plus probable d'être des titres)
    candidates.sort((a, b) => b.length.compareTo(a.length));

    return candidates;
  }

  /// Filtrer le bruit (numéros, texte trop court, prix, etc.)
  static bool _isNoise(String text) {
    final trimmed = text.trim();
    // Que des chiffres
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return true;
    // Prix (ex: "12,90 €", "$9.99")
    if (RegExp(r'^\d+[,.\s]?\d*\s*[€$£]$').hasMatch(trimmed)) return true;
    // ISBN seul
    if (RegExp(r'^\d{10,13}$').hasMatch(trimmed.replaceAll('-', ''))) {
      return true;
    }
    // Trop court
    if (trimmed.length < 3) return true;
    return false;
  }

  /// Normaliser pour déduplication
  static String _normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Rechercher un titre sur Google Books API (gratuit, pas de clé nécessaire)
  static Future<DetectedBook?> _searchGoogleBooks(
    String query,
    int position,
  ) async {
    final url = Uri.parse(
      '$_googleBooksBase?q=${Uri.encodeComponent(query)}&maxResults=3',
    );

    final response = await http.get(url).timeout(
          const Duration(seconds: 8),
        );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return null;

    // Prendre le meilleur résultat
    final volume =
        items[0]['volumeInfo'] as Map<String, dynamic>? ?? {};

    final title = volume['title'] as String?;
    if (title == null) return null;

    // Calculer la confiance basée sur la similarité OCR ↔ titre trouvé
    final confidence = _computeConfidence(query, title);

    // Extraire ISBN-13
    final isbn13 = _extractIsbn13(volume);

    // Extraire URL couverture (préférer grande image)
    final imageLinks = volume['imageLinks'] as Map<String, dynamic>?;
    String? coverUrl = imageLinks?['thumbnail'] as String?;
    // Google Books retourne des URLs http, convertir en https
    if (coverUrl != null && coverUrl.startsWith('http:')) {
      coverUrl = coverUrl.replaceFirst('http:', 'https:');
    }

    final authors = volume['authors'] as List<dynamic>?;
    final categories = volume['categories'] as List<dynamic>?;

    return DetectedBook(
      position: position,
      detectedTitle: title,
      detectedAuthor: authors?.isNotEmpty == true ? authors!.first as String : null,
      detectedPublisher: volume['publisher'] as String?,
      confidence: confidence,
      isbn13: isbn13,
      coverUrl: coverUrl,
      pageCount: volume['pageCount'] as int?,
      description: volume['description'] as String?,
      genres: categories?.cast<String>(),
    );
  }

  /// Calcule un score de confiance (0-100) entre le texte OCR et le titre trouvé
  static int _computeConfidence(String ocrText, String bookTitle) {
    final a = ocrText.toLowerCase().trim();
    final b = bookTitle.toLowerCase().trim();

    // Match exact
    if (a == b) return 98;

    // Le titre contient le texte OCR ou vice-versa
    if (b.contains(a) || a.contains(b)) return 85;

    // Calculer les mots en commun
    final wordsA = a.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    final wordsB = b.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();

    if (wordsA.isEmpty || wordsB.isEmpty) return 40;

    final common = wordsA.intersection(wordsB).length;
    final total = wordsA.union(wordsB).length;
    final ratio = common / total;

    return (ratio * 90).round().clamp(20, 95);
  }

  /// Extraire ISBN-13 depuis les identifiers Google Books
  static String? _extractIsbn13(Map<String, dynamic> volume) {
    final identifiers =
        volume['industryIdentifiers'] as List<dynamic>?;
    if (identifiers == null) return null;

    // Préférer ISBN_13
    for (final id in identifiers) {
      final idMap = id as Map<String, dynamic>;
      if (idMap['type'] == 'ISBN_13') return idMap['identifier'] as String?;
    }
    // Fallback sur ISBN_10
    for (final id in identifiers) {
      final idMap = id as Map<String, dynamic>;
      if (idMap['type'] == 'ISBN_10') return idMap['identifier'] as String?;
    }
    return null;
  }

  /// Enrichir un livre déjà détecté via Google Books (utilisé si besoin)
  static Future<DetectedBook> enrichBook(DetectedBook book) async {
    try {
      final query = '${book.detectedTitle} ${book.detectedAuthor ?? ''}';
      final url = Uri.parse(
        '$_googleBooksBase?q=${Uri.encodeComponent(query)}&maxResults=1',
      );

      final response =
          await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return book;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) return book;

      final volume =
          items[0]['volumeInfo'] as Map<String, dynamic>? ?? {};

      final imageLinks = volume['imageLinks'] as Map<String, dynamic>?;
      String? coverUrl = imageLinks?['thumbnail'] as String?;
      if (coverUrl != null && coverUrl.startsWith('http:')) {
        coverUrl = coverUrl.replaceFirst('http:', 'https:');
      }

      return book.copyWith(
        isbn13: _extractIsbn13(volume) ?? book.isbn13,
        coverUrl: coverUrl ?? book.coverUrl,
        pageCount: (volume['pageCount'] as int?) ?? book.pageCount,
        description:
            (volume['description'] as String?) ?? book.description,
        genres: (volume['categories'] as List<dynamic>?)?.cast<String>() ??
            book.genres,
        confidence: book.confidence,
      );
    } catch (e) {
      debugPrint('ScanService.enrichBook error: $e');
      return book;
    }
  }

  /// Enrichir tous les livres en parallèle
  static Future<List<DetectedBook>> enrichAllBooks(
    List<DetectedBook> books,
  ) async {
    try {
      final futures = books.map(enrichBook);
      return Future.wait(futures);
    } catch (e) {
      return books;
    }
  }
}
