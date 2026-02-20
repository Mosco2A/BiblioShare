import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/loan_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/loan_provider.dart';

/// Ecran dashboard des prets (Module 8)
class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLoans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    await context.read<LoanProvider>().loadLoans(userId);
  }

  @override
  Widget build(BuildContext context) {
    final loanProvider = context.watch<LoanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes prets'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upload_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text('Pretes (${loanProvider.activeLoanCount})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text('Empruntes (${loanProvider.activeBorrowingCount})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: loanProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Onglet prets
                _LoanList(
                  loans: loanProvider.myLoans,
                  emptyMessage: 'Aucun livre prete pour le moment',
                  emptyIcon: Icons.upload_outlined,
                  isOwner: true,
                ),
                // Onglet emprunts
                _LoanList(
                  loans: loanProvider.myBorrowings,
                  emptyMessage: 'Aucun emprunt en cours',
                  emptyIcon: Icons.download_outlined,
                  isOwner: false,
                ),
              ],
            ),
    );
  }
}

class _LoanList extends StatelessWidget {
  final List<LoanModel> loans;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool isOwner;

  const _LoanList({
    required this.loans,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon,
                size: 64, color: AppColors.textHint.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userId = context.read<AuthProvider>().userId;
        if (userId == null) return;
        await context.read<LoanProvider>().loadLoans(userId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: loans.length,
        itemBuilder: (ctx, i) {
          return _LoanCard(loan: loans[i], isOwner: isOwner)
              .animate()
              .fadeIn(delay: (50 * i).ms, duration: 200.ms);
        },
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final LoanModel loan;
  final bool isOwner;

  const _LoanCard({required this.loan, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(loan.status);
    final daysLeft = loan.daysRemaining;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: loan.isOverdue
              ? AppColors.error.withValues(alpha: 0.5)
              : Colors.transparent,
          width: loan.isOverdue ? 2 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icone statut
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(statusInfo.icon, color: statusInfo.color, size: 20),
                ),
                const SizedBox(width: 12),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.bookId, // idealement on resoudrait le titre
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isOwner
                            ? 'Prete a ${loan.borrowerName}'
                            : 'Emprunte a ${loan.ownerId}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Badge statut
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusInfo.label,
                    style: TextStyle(
                      color: statusInfo.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // Date de retour
            if (daysLeft != null && loan.isActive) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    daysLeft < 0
                        ? Icons.warning_amber
                        : daysLeft <= 3
                            ? Icons.access_time
                            : Icons.calendar_today,
                    size: 14,
                    color: daysLeft < 0
                        ? AppColors.error
                        : daysLeft <= 3
                            ? AppColors.warning
                            : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    daysLeft < 0
                        ? 'En retard de ${-daysLeft} jour${-daysLeft > 1 ? 's' : ''}'
                        : daysLeft == 0
                            ? 'Retour prevu aujourd\'hui'
                            : 'Retour dans $daysLeft jour${daysLeft > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: daysLeft < 0
                              ? AppColors.error
                              : daysLeft <= 3
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],

            // Actions
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActions(context),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final provider = context.read<LoanProvider>();
    final actions = <Widget>[];

    switch (loan.status) {
      case LoanStatus.requested:
        if (isOwner) {
          actions.add(TextButton(
            onPressed: () => provider.acceptLoan(loan.id),
            child: const Text('Accepter'),
          ));
          actions.add(TextButton(
            onPressed: () => provider.rejectLoan(loan.id),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Refuser'),
          ));
        }
      case LoanStatus.accepted:
        if (isOwner) {
          actions.add(TextButton(
            onPressed: () => provider.activateLoan(loan.id),
            child: const Text('Livre remis'),
          ));
        }
      case LoanStatus.active:
      case LoanStatus.overdue:
        if (!isOwner) {
          actions.add(TextButton(
            onPressed: () => provider.declareReturn(loan.id),
            child: const Text('Rendre'),
          ));
          actions.add(TextButton(
            onPressed: () => provider.requestExtension(loan.id),
            child: const Text('Prolonger'),
          ));
        }
      case LoanStatus.extensionRequested:
        if (isOwner) {
          actions.add(TextButton(
            onPressed: () => provider.acceptExtension(loan.id),
            child: const Text('Accorder +14j'),
          ));
        }
      case LoanStatus.returnPending:
        if (isOwner) {
          actions.add(TextButton(
            onPressed: () => provider.confirmReturn(loan.id),
            child: const Text('Confirmer retour'),
          ));
        }
      default:
        break;
    }

    return actions;
  }

  _StatusInfo _statusInfo(LoanStatus status) {
    return switch (status) {
      LoanStatus.requested => _StatusInfo(
          'Demande', Icons.hourglass_top, AppColors.warning),
      LoanStatus.accepted => _StatusInfo(
          'Accepte', Icons.check_circle_outline, AppColors.success),
      LoanStatus.active =>
          _StatusInfo('En cours', Icons.menu_book, AppColors.primary),
      LoanStatus.extensionRequested => _StatusInfo(
          'Prolongation', Icons.update, AppColors.warning),
      LoanStatus.overdue =>
          _StatusInfo('En retard', Icons.warning_amber, AppColors.error),
      LoanStatus.returnPending => _StatusInfo(
          'Retour declare', Icons.assignment_return, AppColors.secondary),
      LoanStatus.returned =>
          _StatusInfo('Rendu', Icons.check_circle, AppColors.success),
      LoanStatus.disputed =>
          _StatusInfo('Litige', Icons.gavel, AppColors.error),
      LoanStatus.cancelled =>
          _StatusInfo('Annule', Icons.cancel, AppColors.textHint),
    };
  }
}

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusInfo(this.label, this.icon, this.color);
}
