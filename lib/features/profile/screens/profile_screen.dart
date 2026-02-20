import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../auth/providers/auth_provider.dart';
import '../../library/providers/library_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      context.read<ProfileProvider>().loadProfile(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile ?? authProvider.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: profile?.photoUrl != null
                        ? NetworkImage(profile!.photoUrl!)
                        : null,
                    child: profile?.photoUrl == null
                        ? Text(
                            (profile?.displayName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Text(
                    profile?.displayName ?? 'Utilisateur',
                    style: context.textTheme.headlineSmall,
                  ),

                  if (profile?.username.isNotEmpty ?? false)
                    Text(
                      '@${profile!.username}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                  if (profile?.bio != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      profile!.bio!,
                      style: context.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Stats from library
                  Builder(builder: (context) {
                    final library = context.watch<LibraryProvider>();
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatColumn(label: 'Livres', value: '${library.bookCount}'),
                            _StatColumn(label: 'Genres', value: '${_uniqueGenresCount(library)}'),
                            _StatColumn(label: 'Auteurs', value: '${_uniqueAuthorsCount(library)}'),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Actions
                  ElevatedButton.icon(
                    onPressed: () => context.push('/edit-profile'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier le profil'),
                  ),

                  const SizedBox(height: 12),

                  // Anonymous banner
                  if (authProvider.isAnonymous)
                    Card(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Compte invité',
                              style: context.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Crée ton compte pour accéder à tout BiblioShare !',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                // Sign out and redirect to login to create a real account
                                context.read<AuthProvider>().signOut();
                              },
                              child: const Text('Créer mon compte'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

int _uniqueGenresCount(LibraryProvider library) {
  final genres = <String>{};
  for (final book in library.books) {
    genres.addAll(book.genres);
  }
  return genres.length;
}

int _uniqueAuthorsCount(LibraryProvider library) {
  final authors = <String>{};
  for (final book in library.books) {
    for (final author in book.authors) {
      authors.add(author.name);
    }
  }
  return authors.length;
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: context.textTheme.headlineSmall?.copyWith(
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
