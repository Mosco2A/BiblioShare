import '../../../core/services/supabase_service.dart';
import '../../../shared/models/recommendation_model.dart';

/// Service CRUD pour les recommandations de livres
class RecommendationService {
  RecommendationService._();

  static final _table = SupabaseService.client.from('recommendations');

  /// Envoie une recommandation
  static Future<RecommendationModel> send(RecommendationModel reco) async {
    final data = reco.toJson();
    data['created_at'] = DateTime.now().toIso8601String();

    final response = await _table.insert(data).select().single();
    return RecommendationModel.fromJson(response);
  }

  /// Recupere les recos envoyees par un utilisateur
  static Future<List<RecommendationModel>> getSent(String userId) async {
    final response = await _table
        .select()
        .eq('sender_id', userId)
        .order('created_at', ascending: false);
    return _parseList(response);
  }

  /// Recupere les recos recues par un utilisateur
  static Future<List<RecommendationModel>> getReceived(String userId) async {
    final response = await _table
        .select()
        .eq('receiver_id', userId)
        .order('created_at', ascending: false);
    return _parseList(response);
  }

  /// Met a jour le statut d'une reco
  static Future<void> updateStatus(String recoId, RecoStatus status) async {
    final data = <String, dynamic>{'status': status.name};
    if (status == RecoStatus.seen) {
      data['seen_at'] = DateTime.now().toIso8601String();
    }
    if (status == RecoStatus.finished) {
      data['finished_at'] = DateTime.now().toIso8601String();
    }
    await _table.update(data).eq('id', recoId);
  }

  /// Marque le remerciement
  static Future<void> sendThanks(String recoId) async {
    await _table.update({'receiver_thanks': true}).eq('id', recoId);
  }

  /// Nombre de recos envoyees qui ont abouti a une lecture
  static Future<int> successfulRecos(String userId) async {
    final response = await _table
        .select('id')
        .eq('sender_id', userId)
        .inFilter('status', ['reading', 'finished']);
    return (response as List).length;
  }

  static List<RecommendationModel> _parseList(dynamic response) {
    return (response as List)
        .map((j) => RecommendationModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
