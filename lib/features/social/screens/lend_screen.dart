import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/loan_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/social_provider.dart';

/// Ecran "Preter un livre" (Module 8)
class LendScreen extends StatefulWidget {
  final String bookId;
  final String? bookTitle;

  const LendScreen({
    super.key,
    required this.bookId,
    this.bookTitle,
  });

  @override
  State<LendScreen> createState() => _LendScreenState();
}

class _LendScreenState extends State<LendScreen> {
  String? _selectedFriendId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final _notesController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final userId = context.read<AuthProvider>().userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Preter un livre')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Livre
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.book, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.bookTitle ?? widget.bookId,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Choisir un ami
            Text('A qui preter ?',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            if (social.friends.isEmpty)
              const Text('Aucun ami — invite des amis d\'abord !')
            else
              ...social.friends.map((f) {
                final friendId = f.otherUserId(userId!);
                final isSelected = _selectedFriendId == friendId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor:
                        AppColors.primary.withValues(alpha: 0.05),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.15),
                      child: const Icon(Icons.person,
                          color: AppColors.primary, size: 20),
                    ),
                    title: Text(friendId),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                    onTap: () =>
                        setState(() => _selectedFriendId = friendId),
                  ),
                );
              }),
            const SizedBox(height: 24),

            // Date de retour
            Text('Date de retour prevue',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _dueDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textHint),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_dueDate.day.toString().padLeft(2, '0')}/${_dueDate.month.toString().padLeft(2, '0')}/${_dueDate.year}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    Text(
                      '${_dueDate.difference(DateTime.now()).inDays} jours',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Raccourcis duree
            Wrap(
              spacing: 8,
              children: [
                _DurationChip(
                  label: '2 sem.',
                  onTap: () => setState(() =>
                      _dueDate = DateTime.now().add(const Duration(days: 14))),
                ),
                _DurationChip(
                  label: '1 mois',
                  onTap: () => setState(() =>
                      _dueDate = DateTime.now().add(const Duration(days: 30))),
                ),
                _DurationChip(
                  label: '2 mois',
                  onTap: () => setState(() =>
                      _dueDate = DateTime.now().add(const Duration(days: 60))),
                ),
                _DurationChip(
                  label: '3 mois',
                  onTap: () => setState(() =>
                      _dueDate = DateTime.now().add(const Duration(days: 90))),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Notes
            Text('Notes (optionnel)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Ex: Ne plie pas les pages stp :)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // Valider
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedFriendId != null && !_sending
                    ? () => _createLoan(context)
                    : null,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.swap_horiz),
                label: const Text('Confirmer le pret'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createLoan(BuildContext context) async {
    setState(() => _sending = true);

    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() => _sending = false);
      return;
    }

    try {
      await context.read<LoanProvider>().createLoan(LoanModel(
            id: '',
            bookId: widget.bookId,
            ownerId: userId,
            borrowerId: _selectedFriendId,
            status: LoanStatus.requested,
            dueDate: _dueDate,
            notes: _notesController.text.isNotEmpty
                ? _notesController.text.trim()
                : null,
          ));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pret enregistre !'),
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
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DurationChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
