import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/book_model.dart';
import '../../../shared/models/review_model.dart';

/// Carte de progression de lecture pour un livre en cours
class ReadingProgressCard extends StatelessWidget {
  final BookModel book;
  final ReviewModel review;
  final VoidCallback? onUpdatePage;
  final VoidCallback? onMarkFinished;

  const ReadingProgressCard({
    super.key,
    required this.book,
    required this.review,
    this.onUpdatePage,
    this.onMarkFinished,
  });

  @override
  Widget build(BuildContext context) {
    final currentPage = review.currentPage ?? 0;
    final totalPages = book.pageCount ?? 0;
    final progress =
        totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;
    final pagesLeft = totalPages > 0 ? totalPages - currentPage : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onUpdatePage,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Couverture
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.coverUrl != null
                    ? Image.network(
                        book.coverUrl!,
                        width: 48,
                        height: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, st) => _coverPlaceholder(),
                      )
                    : _coverPlaceholder(),
              ),
              const SizedBox(width: 12),

              // Infos + progression
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      book.authorsDisplay,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),

                    // Barre de progression
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 0.8
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          totalPages > 0
                              ? 'Page $currentPage / $totalPages'
                              : 'Page $currentPage',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        if (totalPages > 0)
                          Text(
                            '${(progress * 100).round()}% — $pagesLeft p. restantes',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textHint,
                                  fontSize: 11,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action rapide
              if (onMarkFinished != null)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  color: AppColors.success,
                  tooltip: 'Marquer comme termine',
                  onPressed: onMarkFinished,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 48,
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.book, size: 24, color: AppColors.primary),
    );
  }
}

/// Dialog rapide pour mettre a jour la page en cours
class UpdatePageDialog extends StatefulWidget {
  final int currentPage;
  final int? totalPages;

  const UpdatePageDialog({
    super.key,
    required this.currentPage,
    this.totalPages,
  });

  @override
  State<UpdatePageDialog> createState() => _UpdatePageDialogState();
}

class _UpdatePageDialogState extends State<UpdatePageDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.currentPage.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Progression'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Page actuelle',
              suffixText:
                  widget.totalPages != null ? '/ ${widget.totalPages}' : null,
              prefixIcon: const Icon(Icons.bookmark_outline),
            ),
          ),
          if (widget.totalPages != null) ...[
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primary,
                thumbColor: AppColors.primary,
                inactiveTrackColor:
                    AppColors.primary.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: (int.tryParse(_controller.text) ?? widget.currentPage)
                    .toDouble()
                    .clamp(0, widget.totalPages!.toDouble()),
                min: 0,
                max: widget.totalPages!.toDouble(),
                divisions: widget.totalPages,
                onChanged: (v) {
                  setState(() {
                    _controller.text = v.round().toString();
                  });
                },
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final page = int.tryParse(_controller.text);
            if (page != null && page >= 0) {
              Navigator.pop(context, page);
            }
          },
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
