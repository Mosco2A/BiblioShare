import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/friendship_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/social_provider.dart';

/// Ecran liste d'amis (Module 6)
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    await context.read<SocialProvider>().loadFriends(userId);
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes amis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => context.push('/friends/search'),
            tooltip: 'Ajouter un ami',
          ),
        ],
      ),
      body: social.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFriends,
              child: CustomScrollView(
                slivers: [
                  // Demandes en attente
                  if (social.pendingRequests.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        label:
                            '${social.pendingCount} demande${social.pendingCount > 1 ? 's' : ''} en attente',
                        color: AppColors.warning,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _PendingRequestTile(
                          friendship: social.pendingRequests[i],
                          onAccept: () => social
                              .acceptRequest(social.pendingRequests[i].id),
                          onReject: () => social
                              .rejectRequest(social.pendingRequests[i].id),
                        ).animate().fadeIn(
                            delay: (50 * i).ms, duration: 200.ms),
                        childCount: social.pendingRequests.length,
                      ),
                    ),
                  ],

                  // Liste d'amis
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      label: '${social.friendCount} ami${social.friendCount > 1 ? 's' : ''}',
                      color: AppColors.primary,
                    ),
                  ),
                  if (social.friends.isEmpty)
                    SliverToBoxAdapter(
                      child: _EmptyFriends(
                        onAdd: () => context.push('/friends/search'),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _FriendTile(
                          friendship: social.friends[i],
                          myId: context.read<AuthProvider>().userId!,
                          onTap: () => context.push(
                            '/friends/${social.friends[i].otherUserId(context.read<AuthProvider>().userId!)}',
                          ),
                        ).animate().fadeIn(
                            delay: (30 * i).ms, duration: 200.ms),
                        childCount: social.friends.length,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: color),
      ),
    );
  }
}

class _PendingRequestTile extends StatelessWidget {
  final FriendshipModel friendship;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _PendingRequestTile({
    required this.friendship,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.warning.withValues(alpha: 0.2),
        child: const Icon(Icons.person, color: AppColors.warning),
      ),
      title: Text(friendship.requesterId),
      subtitle: const Text('Veut devenir ton ami'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check),
            color: AppColors.success,
            onPressed: onAccept,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: AppColors.error,
            onPressed: onReject,
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendshipModel friendship;
  final String myId;
  final VoidCallback onTap;

  const _FriendTile({
    required this.friendship,
    required this.myId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final friendId = friendship.otherUserId(myId);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: const Icon(Icons.person, color: AppColors.primary),
      ),
      title: Text(friendId),
      subtitle: friendship.groupTags.isNotEmpty
          ? Text(friendship.groupTags.join(', '))
          : null,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyFriends({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.people_outline,
                size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Pas encore d\'amis',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Invite tes amis lecteurs pour partager vos bibliotheques !',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add),
              label: const Text('Trouver des amis'),
            ),
          ],
        ),
      ),
    );
  }
}
