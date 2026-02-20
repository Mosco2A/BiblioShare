import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/social_provider.dart';

/// Ecran recherche et ajout d'amis
class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final userId = context.read<AuthProvider>().userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Trouver des amis')),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou @username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          social.clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => social.searchUsers(value.trim()),
            ),
          ),

          // Options d'invitation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: share_plus — partager lien d'invitation
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Inviter par lien'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: SMS invitation via url_launcher
                    },
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('Inviter par SMS'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Resultats
          Expanded(
            child: social.searchResults.isEmpty
                ? Center(
                    child: Text(
                      _controller.text.length < 2
                          ? 'Tape au moins 2 caracteres'
                          : 'Aucun resultat',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textHint),
                    ),
                  )
                : ListView.builder(
                    itemCount: social.searchResults.length,
                    itemBuilder: (ctx, i) {
                      final user = social.searchResults[i];
                      final isMe = user.id == userId;
                      final alreadyFriend = social.friends
                          .any((f) => f.otherUserId(userId!) == user.id);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          child: user.photoUrl == null
                              ? const Icon(Icons.person,
                                  color: AppColors.primary)
                              : null,
                        ),
                        title: Text(user.displayName),
                        subtitle: Text(
                          user.username.isNotEmpty
                              ? '@${user.username}'
                              : user.bio ?? '',
                        ),
                        trailing: isMe
                            ? const Chip(label: Text('Toi'))
                            : alreadyFriend
                                ? const Icon(Icons.check,
                                    color: AppColors.success)
                                : IconButton(
                                    icon: const Icon(Icons.person_add),
                                    color: AppColors.primary,
                                    onPressed: () async {
                                      try {
                                        await social.sendFriendRequest(
                                          userId!,
                                          user.id,
                                        );
                                        if (!ctx.mounted) return;
                                        ScaffoldMessenger.of(ctx)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Demande envoyee a ${user.displayName}'),
                                            backgroundColor:
                                                AppColors.success,
                                            behavior:
                                                SnackBarBehavior.floating,
                                          ),
                                        );
                                      } catch (e) {
                                        if (!ctx.mounted) return;
                                        ScaffoldMessenger.of(ctx)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Erreur : $e'),
                                            backgroundColor:
                                                AppColors.error,
                                            behavior:
                                                SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
