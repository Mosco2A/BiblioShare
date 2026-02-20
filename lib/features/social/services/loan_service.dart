import '../../../core/services/supabase_service.dart';
import '../../../shared/models/loan_model.dart';

/// Service CRUD pour les prets de livres (table `loans`)
class LoanService {
  LoanService._();

  static final _table = SupabaseService.client.from('loans');
  static final _messages = SupabaseService.client.from('loan_messages');

  // ──────────── CRUD ────────────

  /// Cree un nouveau pret
  static Future<LoanModel> createLoan(LoanModel loan) async {
    final data = loan.toJson();
    data['requested_at'] = DateTime.now().toIso8601String();
    data['status'] = 'requested';

    final response = await _table.insert(data).select().single();
    return LoanModel.fromJson(response);
  }

  /// Accepte une demande de pret
  static Future<void> acceptLoan(String loanId) async {
    await _table.update({
      'status': 'accepted',
      'accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', loanId);
  }

  /// Active le pret (livre remis)
  static Future<void> activateLoan(String loanId, {DateTime? dueDate}) async {
    final due = dueDate ?? DateTime.now().add(const Duration(days: 30));
    await _table.update({
      'status': 'active',
      'lent_at': DateTime.now().toIso8601String(),
      'due_date': due.toIso8601String().split('T').first,
      'original_due_date': due.toIso8601String().split('T').first,
    }).eq('id', loanId);
  }

  /// Declare le retour (en attente de confirmation)
  static Future<void> declareReturn(String loanId) async {
    await _table.update({
      'status': 'return_pending',
      'returned_at': DateTime.now().toIso8601String(),
    }).eq('id', loanId);
  }

  /// Confirme le retour
  static Future<void> confirmReturn(String loanId, {String? conditionAfter}) async {
    final data = <String, dynamic>{
      'status': 'returned',
      'confirmed_returned_at': DateTime.now().toIso8601String(),
    };
    if (conditionAfter != null) data['condition_after'] = conditionAfter;
    await _table.update(data).eq('id', loanId);
  }

  /// Refuse un pret
  static Future<void> rejectLoan(String loanId) async {
    await _table.update({'status': 'cancelled'}).eq('id', loanId);
  }

  /// Demande une prolongation
  static Future<void> requestExtension(String loanId) async {
    await _table
        .update({'status': 'extension_requested'})
        .eq('id', loanId);
  }

  /// Accepte la prolongation (+14 jours par defaut)
  static Future<void> acceptExtension(String loanId, {int days = 14}) async {
    // Recupere le pret
    final response = await _table.select().eq('id', loanId).single();
    final loan = LoanModel.fromJson(response);
    final newDue =
        (loan.dueDate ?? DateTime.now()).add(Duration(days: days));

    await _table.update({
      'status': 'active',
      'due_date': newDue.toIso8601String().split('T').first,
    }).eq('id', loanId);
  }

  // ──────────── QUERIES ────────────

  /// Prets en cours (en tant que proprietaire)
  static Future<List<LoanModel>> getActiveLoansAsOwner(String userId) async {
    final response = await _table
        .select()
        .eq('owner_id', userId)
        .inFilter('status', ['requested', 'accepted', 'active', 'overdue', 'extension_requested', 'return_pending'])
        .order('lent_at', ascending: false);
    return _parseList(response);
  }

  /// Emprunts en cours
  static Future<List<LoanModel>> getActiveLoansAsBorrower(
      String userId) async {
    final response = await _table
        .select()
        .eq('borrower_id', userId)
        .inFilter('status', ['requested', 'accepted', 'active', 'overdue', 'extension_requested', 'return_pending'])
        .order('lent_at', ascending: false);
    return _parseList(response);
  }

  /// Historique complet
  static Future<List<LoanModel>> getLoanHistory(String userId) async {
    final response = await _table
        .select()
        .or('owner_id.eq.$userId,borrower_id.eq.$userId')
        .order('requested_at', ascending: false);
    return _parseList(response);
  }

  /// Pret specifique
  static Future<LoanModel?> getLoan(String loanId) async {
    final response =
        await _table.select().eq('id', loanId).maybeSingle();
    if (response == null) return null;
    return LoanModel.fromJson(response);
  }

  /// Verifie si un livre est actuellement prete
  static Future<bool> isBookLent(String bookId) async {
    final response = await _table
        .select('id')
        .eq('book_id', bookId)
        .inFilter('status', ['active', 'overdue', 'extension_requested'])
        .limit(1);
    return (response as List).isNotEmpty;
  }

  // ──────────── MESSAGES ────────────

  /// Envoie un message lie a un pret
  static Future<void> sendMessage(
    String loanId,
    String senderId,
    String message,
  ) async {
    await _messages.insert({
      'loan_id': loanId,
      'sender_id': senderId,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Recupere les messages d'un pret
  static Future<List<Map<String, dynamic>>> getMessages(
      String loanId) async {
    final response = await _messages
        .select()
        .eq('loan_id', loanId)
        .order('created_at');
    return (response as List).cast<Map<String, dynamic>>();
  }

  // ──────────── HELPERS ────────────

  static List<LoanModel> _parseList(dynamic response) {
    return (response as List)
        .map((j) => LoanModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
