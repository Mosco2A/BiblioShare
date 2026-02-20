import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/scan_result_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/scan_provider.dart';

/// Écran de validation des résultats du scan
class ScanResultsScreen extends StatelessWidget {
  const ScanResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scanProvider = context.watch<ScanProvider>();
    final books = scanProvider.detectedBooks;

    return Scaffold(
      appBar: AppBar(
        title: Text('${books.length} livres détectés'),
        actions: [
          TextButton(
            onPressed: () => scanProvider.confirmAllHighConfidence(),
            child: const Text('Tout confirmer'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de résumé
          _SummaryBar(
            total: books.length,
            confirmed: scanProvider.confirmedCount,
            rejected: scanProvider.rejectedCount,
            pending: scanProvider.pendingCount,
          ),

          // Liste des livres détectés
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              itemBuilder: (context, index) {
                return _DetectedBookCard(
                  book: books[index],
                  index: index,
                  onConfirm: () => scanProvider.confirmBook(index),
                  onReject: () => scanProvider.rejectBook(index),
                  onEdit: () => _showEditDialog(context, scanProvider, index),
                ).animate().fadeIn(delay: (50 * index).ms, duration: 300.ms);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: scanProvider.confirmedCount > 0
                ? () => _saveBooks(context)
                : null,
            child: Text(
              'Ajouter ${scanProvider.confirmedCount} livre${scanProvider.confirmedCount > 1 ? 's' : ''} à ma bibliothèque',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveBooks(BuildContext context) async {
    final scanProvider = context.read<ScanProvider>();
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final count = await scanProvider.saveConfirmedBooks(userId);
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Fermer le dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count livre${count > 1 ? 's' : ''} ajouté${count > 1 ? 's' : ''} !'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Retourner à la home
      context.go('/home');
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement : $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditDialog(
    BuildContext context,
    ScanProvider scanProvider,
    int index,
  ) {
    final book = scanProvider.detectedBooks[index];
    final titleController = TextEditingController(text: book.detectedTitle);
    final authorController =
        TextEditingController(text: book.detectedAuthor ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Corriger le livre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                prefixIcon: Icon(Icons.book),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(
                labelText: 'Auteur',
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              scanProvider.updateBook(
                index,
                title: titleController.text,
                author: authorController.text.isEmpty
                    ? null
                    : authorController.text,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

/// Barre de résumé en haut
class _SummaryBar extends StatelessWidget {
  final int total;
  final int confirmed;
  final int rejected;
  final int pending;

  const _SummaryBar({
    required this.total,
    required this.confirmed,
    required this.rejected,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surfaceVariant,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _chip(context, '$confirmed', 'confirmé${confirmed > 1 ? 's' : ''}',
              AppColors.success),
          _chip(context, '$pending', 'en attente', AppColors.warning),
          _chip(context, '$rejected', 'rejeté${rejected > 1 ? 's' : ''}',
              AppColors.error),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Carte d'un livre détecté
class _DetectedBookCard extends StatelessWidget {
  final DetectedBook book;
  final int index;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onEdit;

  const _DetectedBookCard({
    required this.book,
    required this.index,
    required this.onConfirm,
    required this.onReject,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = book.confirmed;
    final isRejected = book.rejected;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isConfirmed
              ? AppColors.success
              : isRejected
                  ? AppColors.error.withValues(alpha: 0.3)
                  : Colors.transparent,
          width: isConfirmed ? 2 : 1,
        ),
      ),
      child: Opacity(
        opacity: isRejected ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Couverture ou placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.coverUrl != null
                    ? Image.network(
                        book.coverUrl!,
                        width: 56,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, st) =>
                            _coverPlaceholder(context),
                      )
                    : _coverPlaceholder(context),
              ),
              const SizedBox(width: 12),

              // Infos livre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.detectedTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.detectedAuthor != null)
                      Text(
                        book.detectedAuthor!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    const SizedBox(height: 4),
                    // Badge de confiance
                    _ConfidenceBadge(
                      confidence: book.confidence,
                      status: book.status,
                    ),
                    if (book.detectedPublisher != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          book.detectedPublisher!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textHint,
                              ),
                        ),
                      ),
                  ],
                ),
              ),

              // Actions
              Column(
                children: [
                  if (!isConfirmed && !isRejected) ...[
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      color: AppColors.success,
                      onPressed: onConfirm,
                      tooltip: 'Confirmer',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined),
                      color: AppColors.error,
                      onPressed: onReject,
                      tooltip: 'Rejeter',
                    ),
                  ] else if (isConfirmed) ...[
                    const Icon(Icons.check_circle, color: AppColors.success),
                  ],
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: onEdit,
                    tooltip: 'Corriger',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder(BuildContext context) {
    return Container(
      width: 56,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.book, color: AppColors.primary, size: 28),
    );
  }
}

/// Badge de confiance d'identification
class _ConfidenceBadge extends StatelessWidget {
  final int confidence;
  final DetectionStatus status;

  const _ConfidenceBadge({
    required this.confidence,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    if (status == DetectionStatus.unreadable) {
      color = AppColors.error;
      label = 'Illisible';
    } else if (status == DetectionStatus.partial) {
      color = AppColors.warning;
      label = 'Partiel — $confidence%';
    } else if (confidence >= 80) {
      color = AppColors.success;
      label = '$confidence%';
    } else if (confidence >= 50) {
      color = AppColors.warning;
      label = '$confidence%';
    } else {
      color = AppColors.error;
      label = '$confidence%';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
