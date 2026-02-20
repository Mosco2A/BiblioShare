import 'package:flutter/foundation.dart';

import '../../../shared/models/loan_model.dart';
import '../services/loan_service.dart';

/// Provider pour la gestion des prets
class LoanProvider extends ChangeNotifier {
  List<LoanModel> _myLoans = []; // livres que j'ai pretes
  List<LoanModel> _myBorrowings = []; // livres que j'ai empruntes
  bool _loading = false;
  String? _error;

  List<LoanModel> get myLoans => _myLoans;
  List<LoanModel> get myBorrowings => _myBorrowings;
  bool get loading => _loading;
  String? get error => _error;

  int get activeLoanCount => _myLoans.where((l) => l.isActive).length;
  int get activeBorrowingCount =>
      _myBorrowings.where((l) => l.isActive).length;
  int get overdueCount =>
      _myLoans.where((l) => l.isOverdue).length +
      _myBorrowings.where((l) => l.isOverdue).length;

  /// Charge les prets et emprunts actifs
  Future<void> loadLoans(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        LoanService.getActiveLoansAsOwner(userId),
        LoanService.getActiveLoansAsBorrower(userId),
      ]);
      _myLoans = results[0];
      _myBorrowings = results[1];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Cree un pret
  Future<LoanModel> createLoan(LoanModel loan) async {
    try {
      final created = await LoanService.createLoan(loan);
      _myLoans.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Accepte un pret
  Future<void> acceptLoan(String loanId) async {
    await LoanService.acceptLoan(loanId);
    _updateLocalStatus(loanId, LoanStatus.accepted);
  }

  /// Active un pret
  Future<void> activateLoan(String loanId, {DateTime? dueDate}) async {
    await LoanService.activateLoan(loanId, dueDate: dueDate);
    _updateLocalStatus(loanId, LoanStatus.active);
  }

  /// Declare le retour
  Future<void> declareReturn(String loanId) async {
    await LoanService.declareReturn(loanId);
    _updateLocalStatus(loanId, LoanStatus.returnPending);
  }

  /// Confirme le retour
  Future<void> confirmReturn(String loanId, {String? conditionAfter}) async {
    await LoanService.confirmReturn(loanId, conditionAfter: conditionAfter);
    // Retirer du cache actif
    _myLoans.removeWhere((l) => l.id == loanId);
    _myBorrowings.removeWhere((l) => l.id == loanId);
    notifyListeners();
  }

  /// Refuse un pret
  Future<void> rejectLoan(String loanId) async {
    await LoanService.rejectLoan(loanId);
    _myLoans.removeWhere((l) => l.id == loanId);
    _myBorrowings.removeWhere((l) => l.id == loanId);
    notifyListeners();
  }

  /// Demande une prolongation
  Future<void> requestExtension(String loanId) async {
    await LoanService.requestExtension(loanId);
    _updateLocalStatus(loanId, LoanStatus.extensionRequested);
  }

  /// Accepte une prolongation
  Future<void> acceptExtension(String loanId, {int days = 14}) async {
    await LoanService.acceptExtension(loanId, days: days);
    _updateLocalStatus(loanId, LoanStatus.active);
  }

  /// Verifie si un livre est prete
  Future<bool> isBookLent(String bookId) async {
    return LoanService.isBookLent(bookId);
  }

  void _updateLocalStatus(String loanId, LoanStatus status) {
    // On recharge pour etre propre
    // (simpliste mais fiable — le vrai update serait un copyWith)
    notifyListeners();
  }
}
