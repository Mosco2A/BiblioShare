import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/recommendation_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/social_provider.dart';
import '../services/recommendation_service.dart';

/// Ecran "Recommander un livre a un ami" (Module 7)
class RecommendScreen extends StatefulWidget {
  final String bookId;
  final String? bookTitle;

  const RecommendScreen({
    super.key,
    required this.bookId,
    this.bookTitle,
  });

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  final _messageController = TextEditingController();
  bool _includesLoanOffer = false;
  String? _selectedFriendId;
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final userId = context.read<AuthProvider>().userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommander'),
      ),
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
            ).animate().fadeIn(duration: 200.ms),
            const SizedBox(height: 24),

            // Choisir un ami
            Text('A qui veux-tu recommander ce livre ?',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            if (social.friends.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tu n\'as pas encore d\'amis. Invite des amis pour pouvoir leur recommander des livres !',
                ),
              )
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

            // Message
            Text('Ton message',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Dis a ton ami pourquoi il devrait lire ce livre...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Proposer le pret
            SwitchListTile(
              title: const Text('Proposer de lui preter'),
              subtitle:
                  const Text('Ajoute "Je te le prete quand tu veux !"'),
              value: _includesLoanOffer,
              onChanged: (v) => setState(() => _includesLoanOffer = v),
              activeTrackColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Envoyer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedFriendId != null && !_sending
                    ? () => _send(context)
                    : null,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Envoyer la recommandation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(BuildContext context) async {
    setState(() => _sending = true);

    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() => _sending = false);
      return;
    }

    try {
      await RecommendationService.send(RecommendationModel(
        id: '',
        senderId: userId,
        receiverId: _selectedFriendId!,
        bookId: widget.bookId,
        messageText: _messageController.text.isNotEmpty
            ? _messageController.text.trim()
            : null,
        includesLoanOffer: _includesLoanOffer,
        triggerType: 'manual',
        sentVia: 'in_app',
        createdAt: DateTime.now(),
      ));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recommandation envoyee !'),
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
