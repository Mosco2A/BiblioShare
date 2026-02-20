import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/scan_result_model.dart';

/// Service de scan d'étagère — envoie la photo à l'Edge Function
/// qui appelle Claude Vision pour identifier les livres
class ScanService {
  ScanService._();

  /// Analyse une photo d'étagère via Claude Vision (Edge Function)
  ///
  /// [imageBytes] — l'image en bytes (JPEG/PNG)
  /// Retourne un [ScanResult] avec les livres détectés
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
      rethrow;
    }
  }

  /// Enrichit un livre détecté via Google Books (Edge Function)
  ///
  /// Cherche par titre + auteur et retourne les métadonnées enrichies
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
      // Retourner le livre non enrichi en cas d'erreur
      return book;
    }
  }

  /// Enrichit tous les livres détectés en parallèle
  static Future<List<DetectedBook>> enrichAllBooks(
    List<DetectedBook> books,
  ) async {
    final futures = books.map((book) => enrichBook(book));
    return Future.wait(futures);
  }
}
