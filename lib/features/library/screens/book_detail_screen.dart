import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/book_model.dart';
import '../providers/library_provider.dart';

/// Écran de détail d'un livre enrichi
class BookDetailScreen extends StatelessWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final book = library.books.where((b) => b.id == bookId).firstOrNull;

    if (book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Livre introuvable')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header avec couverture
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _CoverHeader(book: book),
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleAction(context, value, book),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Modifier'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'lend',
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz),
                      title: Text('Prêter'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'recommend',
                    child: ListTile(
                      leading: Icon(Icons.favorite_outline),
                      title: Text('Recommander'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading:
                          Icon(Icons.delete_outline, color: AppColors.error),
                      title: Text('Supprimer',
                          style: TextStyle(color: AppColors.error)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + Auteur
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ).animate().fadeIn(duration: 300.ms),
                  if (book.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      book.subtitle!,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    book.authorsDisplay,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primaryLight,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Badges rapides
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (book.pageCount != null)
                        _InfoChip(
                            icon: Icons.menu_book, label: '${book.pageCount} p.'),
                      if (book.publisher != null)
                        _InfoChip(
                            icon: Icons.business, label: book.publisher!),
                      if (book.format != null)
                        _InfoChip(icon: Icons.straighten, label: book.format!),
                      if (book.language != 'fr')
                        _InfoChip(
                            icon: Icons.language,
                            label: book.language.toUpperCase()),
                      if (book.isbn13 != null)
                        _InfoChip(
                            icon: Icons.qr_code, label: book.isbn13!),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Boutons d'action principaux
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push(
                            '/book/${book.id}/review',
                          ),
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('Noter / Avis'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/book/${book.id}/lend',
                            extra: {'title': book.title},
                          ),
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('Prêter'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Notes communautaires
                  if (book.goodreadsRating != null ||
                      book.babelioRating != null) ...[
                    Text('Notes communautaires',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (book.goodreadsRating != null)
                          _RatingBadge(
                            source: 'Goodreads',
                            rating: book.goodreadsRating!,
                          ),
                        if (book.goodreadsRating != null &&
                            book.babelioRating != null)
                          const SizedBox(width: 16),
                        if (book.babelioRating != null)
                          _RatingBadge(
                            source: 'Babelio',
                            rating: book.babelioRating!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  if (book.description != null) ...[
                    Text('Synopsis',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      book.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Genres & Thèmes
                  if (book.genres.isNotEmpty) ...[
                    Text('Genres',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: book.genres
                          .map((g) => Chip(
                                label: Text(g),
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                side: BorderSide.none,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Infos détaillées
                  Text('Informations',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Éditeur', value: book.publisher),
                  _DetailRow(label: 'Collection', value: book.collection),
                  _DetailRow(label: 'ISBN-13', value: book.isbn13),
                  _DetailRow(label: 'ISBN-10', value: book.isbn10),
                  _DetailRow(label: 'Langue', value: book.language),
                  _DetailRow(
                    label: 'Pages',
                    value: book.pageCount?.toString(),
                  ),
                  _DetailRow(label: 'Format', value: book.format),
                  _DetailRow(label: 'État', value: _conditionLabel(book.condition)),
                  _DetailRow(
                    label: 'Ajouté le',
                    value: _formatDate(book.dateAdded),
                  ),
                  if (book.scanConfidence != null)
                    _DetailRow(
                      label: 'Confiance scan',
                      value: '${book.scanConfidence}%',
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action, BookModel book) {
    switch (action) {
      case 'edit':
        _showEditDialog(context, book);
        break;
      case 'lend':
        context.push('/book/${book.id}/lend', extra: {'title': book.title});
        break;
      case 'recommend':
        context.push('/book/${book.id}/recommend', extra: {'title': book.title});
        break;
      case 'delete':
        _confirmDelete(context, book);
        break;
    }
  }

  void _showEditDialog(BuildContext context, BookModel book) {
    final titleController = TextEditingController(text: book.title);
    final conditionValues = ['new', 'good', 'fair', 'poor'];
    String selectedCondition = book.condition;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Modifier le livre'),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCondition,
                decoration: const InputDecoration(
                  labelText: 'État du livre',
                  prefixIcon: Icon(Icons.auto_awesome),
                ),
                items: conditionValues.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(_conditionLabel(c)),
                )).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedCondition = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await context.read<LibraryProvider>().updateBookLocal(
                    book.id,
                    title: titleController.text.trim(),
                    condition: selectedCondition,
                  );
                } catch (_) {}
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, BookModel book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce livre ?'),
        content: Text(
            'Supprimer "${book.title}" de ta bibliothèque ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<LibraryProvider>().deleteBook(book.id);
              if (context.mounted) context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _conditionLabel(String condition) {
    return switch (condition) {
      'new' => 'Neuf',
      'good' => 'Bon état',
      'fair' => 'Correct',
      'poor' => 'Usé',
      _ => condition,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Header avec couverture du livre
class _CoverHeader extends StatelessWidget {
  final BookModel book;

  const _CoverHeader({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Hero(
            tag: 'book-cover-${book.id}',
            child: book.coverUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book.coverUrl!,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, st) => _placeholder(),
                    ),
                  )
                : _placeholder(),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 180,
      width: 120,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.book, size: 48, color: Colors.white70),
          const SizedBox(height: 8),
          Text(
            book.title,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Chip d'info rapide
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Badge de note communautaire
class _RatingBadge extends StatelessWidget {
  final String source;
  final double rating;

  const _RatingBadge({required this.source, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 18, color: AppColors.starFilled),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.secondaryDark,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            source,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Ligne de détail clé/valeur
class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
