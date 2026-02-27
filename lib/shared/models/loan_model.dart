/// Modele pret de livre BiblioShare (table `loans`)
class LoanModel {
  final String id;
  final String bookId;
  final String ownerId;
  final String? borrowerId;
  final Map<String, dynamic>? borrowerExternal;

  final LoanStatus status;

  final DateTime? requestedAt;
  final DateTime? acceptedAt;
  final DateTime? lentAt;
  final DateTime? dueDate;
  final DateTime? originalDueDate;
  final DateTime? returnedAt;

  final String? conditionBefore;
  final String? conditionAfter;
  final String? photoBeforeUrl;
  final String? photoAfterUrl;
  final String? notes;
  final int reminderCount;
  final int escalationLevel;

  const LoanModel({
    required this.id,
    required this.bookId,
    required this.ownerId,
    this.borrowerId,
    this.borrowerExternal,
    required this.status,
    this.requestedAt,
    this.acceptedAt,
    this.lentAt,
    this.dueDate,
    this.originalDueDate,
    this.returnedAt,
    this.conditionBefore,
    this.conditionAfter,
    this.photoBeforeUrl,
    this.photoAfterUrl,
    this.notes,
    this.reminderCount = 0,
    this.escalationLevel = 0,
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: json['id'] as String,
      bookId: json['book_id'] as String,
      ownerId: json['owner_id'] as String,
      borrowerId: json['borrower_id'] as String?,
      borrowerExternal: json['borrower_external'] as Map<String, dynamic>?,
      status: _parseStatus(json['status'] as String?),
      requestedAt: _tryParse(json['requested_at']),
      acceptedAt: _tryParse(json['accepted_at']),
      lentAt: _tryParse(json['lent_at']),
      dueDate: _tryParse(json['due_date']),
      originalDueDate: _tryParse(json['original_due_date']),
      returnedAt: _tryParse(json['returned_at']),
      conditionBefore: json['condition_before'] as String?,
      conditionAfter: json['condition_after'] as String?,
      photoBeforeUrl: json['photo_before_url'] as String?,
      photoAfterUrl: json['photo_after_url'] as String?,
      notes: json['notes'] as String?,
      reminderCount: json['reminder_count'] as int? ?? 0,
      escalationLevel: json['escalation_level'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'owner_id': ownerId,
      'borrower_id': borrowerId,
      'borrower_external': borrowerExternal,
      'status': status.name,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'original_due_date': originalDueDate?.toIso8601String().split('T').first,
      'condition_before': conditionBefore,
      'notes': notes,
    };
  }

  /// Nombre de jours restants (negatif = en retard)
  int? get daysRemaining {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  bool get isOverdue =>
      status == LoanStatus.overdue ||
      (status == LoanStatus.active &&
          dueDate != null &&
          DateTime.now().isAfter(dueDate!));

  bool get isActive =>
      status == LoanStatus.active || status == LoanStatus.overdue;

  String get borrowerName {
    if (borrowerExternal != null) {
      return borrowerExternal!['name'] as String? ?? 'Inconnu';
    }
    return borrowerId ?? 'Inconnu';
  }

  static DateTime? _tryParse(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value as String);
  }

  static LoanStatus _parseStatus(String? raw) {
    return switch (raw) {
      'requested' => LoanStatus.requested,
      'accepted' => LoanStatus.accepted,
      'active' => LoanStatus.active,
      'extension_requested' => LoanStatus.extensionRequested,
      'overdue' => LoanStatus.overdue,
      'return_pending' => LoanStatus.returnPending,
      'returned' => LoanStatus.returned,
      'disputed' => LoanStatus.disputed,
      'cancelled' => LoanStatus.cancelled,
      _ => LoanStatus.requested,
    };
  }
}

enum LoanStatus {
  requested,
  accepted,
  active,
  extensionRequested,
  overdue,
  returnPending,
  returned,
  disputed,
  cancelled,
}
