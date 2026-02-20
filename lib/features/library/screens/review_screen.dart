import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/book_model.dart';
import '../../../shared/models/review_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../providers/review_provider.dart';

/// Ecran notation / avis post-lecture (Module 5)
class ReviewScreen extends StatefulWidget {
  final String bookId;

  const ReviewScreen({super.key, required this.bookId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _ratingGlobal = 0;
  double _ratingStory = 0;
  double _ratingWriting = 0;
  double _ratingDepth = 0;
  double _ratingEmotion = 0;
  double _ratingPacing = 0;
  double _ratingOriginality = 0;

  final _reviewController = TextEditingController();
  final _notesController = TextEditingController();
  String _visibility = 'friends';
  final List<String> _tags = [];
  final _tagController = TextEditingController();
  bool _showDetailedRatings = false;
  bool _saving = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadExistingReview();
    }
  }

  Future<void> _loadExistingReview() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    final reviewProvider = context.read<ReviewProvider>();
    final existing = await reviewProvider.loadReview(userId, widget.bookId);
    if (existing != null && mounted) {
      setState(() {
        _ratingGlobal = existing.ratingGlobal ?? 0;
        _ratingStory = existing.ratingStory ?? 0;
        _ratingWriting = existing.ratingWriting ?? 0;
        _ratingDepth = existing.ratingDepth ?? 0;
        _ratingEmotion = existing.ratingEmotion ?? 0;
        _ratingPacing = existing.ratingPacing ?? 0;
        _ratingOriginality = existing.ratingOriginality ?? 0;
        _reviewController.text = existing.reviewText ?? '';
        _notesController.text = existing.privateNotes ?? '';
        _visibility = existing.visibility;
        _tags
          ..clear()
          ..addAll(existing.tags);
        _showDetailedRatings = existing.ratingStory != null;
      });
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final book = library.books.where((b) => b.id == widget.bookId).firstOrNull;

    if (book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Livre introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon avis'),
        actions: [
          if (_ratingGlobal > 0)
            TextButton(
              onPressed: _saving ? null : () => _save(context, book),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tete livre
            _BookHeader(book: book)
                .animate()
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 24),

            // Note globale
            Center(
              child: Column(
                children: [
                  Text(
                    'Ta note globale',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _StarRating(
                    rating: _ratingGlobal,
                    size: 44,
                    onChanged: (v) => setState(() => _ratingGlobal = v),
                  ),
                  if (_ratingGlobal > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _ratingLabel(_ratingGlobal),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            const SizedBox(height: 24),

            // Notes detaillees (toggle)
            _SectionToggle(
              label: 'Notes detaillees',
              subtitle: 'Histoire, ecriture, rythme...',
              expanded: _showDetailedRatings,
              onToggle: () =>
                  setState(() => _showDetailedRatings = !_showDetailedRatings),
            ),
            if (_showDetailedRatings) ...[
              const SizedBox(height: 12),
              _DetailedRatingRow(
                icon: Icons.auto_stories,
                label: 'Histoire / Intrigue',
                rating: _ratingStory,
                onChanged: (v) => setState(() => _ratingStory = v),
              ),
              _DetailedRatingRow(
                icon: Icons.edit_note,
                label: "Style d'ecriture",
                rating: _ratingWriting,
                onChanged: (v) => setState(() => _ratingWriting = v),
              ),
              _DetailedRatingRow(
                icon: Icons.psychology,
                label: 'Profondeur / Reflexion',
                rating: _ratingDepth,
                onChanged: (v) => setState(() => _ratingDepth = v),
              ),
              _DetailedRatingRow(
                icon: Icons.favorite,
                label: 'Emotion / Attachement',
                rating: _ratingEmotion,
                onChanged: (v) => setState(() => _ratingEmotion = v),
              ),
              _DetailedRatingRow(
                icon: Icons.speed,
                label: 'Rythme / Page-turner',
                rating: _ratingPacing,
                onChanged: (v) => setState(() => _ratingPacing = v),
              ),
              _DetailedRatingRow(
                icon: Icons.lightbulb_outline,
                label: 'Originalite',
                rating: _ratingOriginality,
                onChanged: (v) => setState(() => _ratingOriginality = v),
              ),
            ],
            const SizedBox(height: 24),

            // Avis texte
            Text('Ton avis', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText:
                    'Quelques mots sur ce livre...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            Text('Tes tags', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._tags.map(
                  (tag) => InputChip(
                    label: Text(tag),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                ..._suggestedTags
                    .where((t) => !_tags.contains(t))
                    .map(
                      (tag) => ActionChip(
                        label: Text('+ $tag'),
                        onPressed: () => setState(() => _tags.add(tag)),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Ajouter un tag...',
                      isDense: true,
                    ),
                    onSubmitted: _addCustomTag,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addCustomTag(_tagController.text),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Notes privees
            Text('Notes privees',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Visibles uniquement par toi',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tes notes personnelles, citations, pages...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 24),

            // Visibilite
            Text('Visibilite de l\'avis',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'private',
                  label: Text('Prive'),
                  icon: Icon(Icons.lock_outline),
                ),
                ButtonSegment(
                  value: 'friends',
                  label: Text('Amis'),
                  icon: Icon(Icons.people_outline),
                ),
                ButtonSegment(
                  value: 'public',
                  label: Text('Public'),
                  icon: Icon(Icons.public),
                ),
              ],
              selected: {_visibility},
              onSelectionChanged: (v) =>
                  setState(() => _visibility = v.first),
            ),
            const SizedBox(height: 32),

            // Boutons action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _ratingGlobal > 0 && !_saving
                            ? () => _save(context, book)
                            : null,
                    child: Text(
                      _visibility == 'private'
                          ? 'Garder en prive'
                          : 'Publier l\'avis',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Plus tard'),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _addCustomTag(String text) {
    final tag = text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
    _tagController.clear();
  }

  Future<void> _save(BuildContext context, BookModel book) async {
    setState(() => _saving = true);

    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() => _saving = false);
      return;
    }

    final review = ReviewModel(
      id: '', // sera genere par Supabase
      userId: userId,
      bookId: widget.bookId,
      ratingGlobal: _ratingGlobal > 0 ? _ratingGlobal : null,
      ratingStory: _ratingStory > 0 ? _ratingStory : null,
      ratingWriting: _ratingWriting > 0 ? _ratingWriting : null,
      ratingDepth: _ratingDepth > 0 ? _ratingDepth : null,
      ratingEmotion: _ratingEmotion > 0 ? _ratingEmotion : null,
      ratingPacing: _ratingPacing > 0 ? _ratingPacing : null,
      ratingOriginality: _ratingOriginality > 0 ? _ratingOriginality : null,
      reviewText: _reviewController.text.isEmpty
          ? null
          : _reviewController.text.trim(),
      visibility: _visibility,
      tags: _tags,
      privateNotes: _notesController.text.isEmpty
          ? null
          : _notesController.text.trim(),
      readingStatus: ReadingStatus.finished,
      finishedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await context.read<ReviewProvider>().saveReview(review);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avis enregistre !'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _ratingLabel(double rating) {
    if (rating >= 4.5) return 'Coup de coeur !';
    if (rating >= 4) return 'Excellent';
    if (rating >= 3) return 'Bien';
    if (rating >= 2) return 'Moyen';
    return 'Decevant';
  }

  static const _suggestedTags = [
    'coup-de-coeur',
    'fait-reflechir',
    'page-turner',
    'a-relire',
    'offrir-absolument',
    'decevant',
    'classique',
    'feel-good',
  ];
}

/// En-tete compact du livre
class _BookHeader extends StatelessWidget {
  final BookModel book;

  const _BookHeader({required this.book});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: book.coverUrl != null
              ? Image.network(
                  book.coverUrl!,
                  width: 50,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, st) => _placeholder(),
                )
              : _placeholder(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                book.authorsDisplay,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      width: 50,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.book, color: AppColors.primary),
    );
  }
}

/// Etoiles interactives (demi-etoiles possibles)
class _StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final ValueChanged<double> onChanged;

  const _StarRating({
    required this.rating,
    required this.size,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        final halfValue = index + 0.5;

        IconData icon;
        Color color;

        if (rating >= starValue) {
          icon = Icons.star;
          color = AppColors.starFilled;
        } else if (rating >= halfValue) {
          icon = Icons.star_half;
          color = AppColors.starFilled;
        } else {
          icon = Icons.star_border;
          color = AppColors.starEmpty;
        }

        return GestureDetector(
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox;
            final localPos = box.globalToLocal(details.globalPosition);
            final starWidth = size + 4; // gap
            final tapX = localPos.dx - (index * starWidth);
            // Demi gauche = 0.5, demi droit = 1.0
            if (tapX < starWidth / 2) {
              onChanged(halfValue);
            } else {
              onChanged(starValue);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(icon, size: size, color: color),
          ),
        );
      }),
    );
  }
}

/// Toggle pour section depliable
class _SectionToggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool expanded;
  final VoidCallback onToggle;

  const _SectionToggle({
    required this.label,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne de note detaillee (icone + label + etoiles)
class _DetailedRatingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double rating;
  final ValueChanged<double> onChanged;

  const _DetailedRatingRow({
    required this.icon,
    required this.label,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          _StarRating(
            rating: rating,
            size: 24,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
