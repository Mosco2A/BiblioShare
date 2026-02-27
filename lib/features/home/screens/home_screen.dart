import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/services/seed_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../library/providers/library_provider.dart';
import '../../social/providers/loan_provider.dart';
import '../../social/providers/social_provider.dart';

/// Écran principal avec navigation par onglets
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _booksLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_booksLoaded) {
      _booksLoaded = true;
      final auth = context.read<AuthProvider>();
      if (auth.userId != null) {
        final userId = auth.userId!;
        // Différer le chargement après le build pour éviter
        // setState() during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<LibraryProvider>().loadBooks(userId);
          context.read<SocialProvider>().loadFriends(userId);
          context.read<LoanProvider>().loadLoans(userId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _LibraryTab(),
          _ScanTab(),
          _SocialTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books, color: AppColors.primary),
            label: 'Bibliothèque',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_camera_outlined),
            selectedIcon: Icon(Icons.photo_camera, color: AppColors.primary),
            label: 'Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Social',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Onglet Bibliothèque — liste des livres ou état vide
class _LibraryTab extends StatelessWidget {
  const _LibraryTab();

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final books = library.books;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: books.isNotEmpty
            ? FloatingActionButton(
                heroTag: 'scan_fab',
                onPressed: () => context.push('/scan'),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.photo_camera, color: Colors.white),
              )
            : null,
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('Ma Bibliothèque'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // TODO: Module 4 — recherche
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () {
                    // TODO: tri / filtre
                  },
                ),
              ],
            ),
            if (books.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  icon: Icons.menu_book_rounded,
                  title: 'Aucun livre pour l\'instant',
                  subtitle:
                      'Scanne une étagère ou ajoute un livre manuellement pour commencer.',
                  buttonLabel: 'Scanner une étagère',
                  onPressed: () => context.push('/scan'),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final book = books[i];
                    return ListTile(
                      onTap: () => context.push('/book/${book.id}'),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: book.coverUrl != null
                            ? Image.network(
                                book.coverUrl!,
                                width: 40,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, e, st) => Container(
                                  width: 40,
                                  height: 56,
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  child: const Icon(Icons.book, size: 20),
                                ),
                              )
                            : Container(
                                width: 40,
                                height: 56,
                                color: AppColors.primary.withValues(alpha: 0.1),
                                child: const Icon(Icons.book, size: 20),
                              ),
                      ),
                      title: Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        book.authorsDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                    );
                  },
                  childCount: books.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Onglet Scanner — accès rapide au scan
class _ScanTab extends StatelessWidget {
  const _ScanTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: _EmptyState(
          icon: Icons.photo_camera_rounded,
          title: 'Scanne ton étagère',
          subtitle:
              'Prends en photo ton étagère et BiblioShare identifie chaque livre automatiquement.',
          buttonLabel: 'Ouvrir la caméra',
          onPressed: () => context.push('/scan'),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
      ),
    );
  }
}

/// Onglet Social — amis et activité
class _SocialTab extends StatelessWidget {
  const _SocialTab();

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final loans = context.watch<LoanProvider>();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Social'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                onPressed: () => context.push('/friends/search'),
              ),
            ],
          ),

          // Demandes en attente
          if (social.pendingRequests.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Demandes en attente (${social.pendingCount})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final req = social.pendingRequests[i];
                  final user = SeedDataService.getUserById(req.requesterId);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        (user?.displayName ?? '?')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user?.displayName ?? req.requesterId),
                    subtitle: Text(user?.bio ?? 'Veut devenir ton ami'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: AppColors.success),
                          onPressed: () => social.acceptRequest(req.id),
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel, color: AppColors.error),
                          onPressed: () => social.rejectRequest(req.id),
                        ),
                      ],
                    ),
                  );
                },
                childCount: social.pendingRequests.length,
              ),
            ),
            const SliverToBoxAdapter(child: Divider()),
          ],

          // Mes amis
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mes amis (${social.friendCount})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/friends'),
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
            ),
          ),
          if (social.friends.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _EmptyState(
                  icon: Icons.people_rounded,
                  title: 'Aucun ami pour l\'instant',
                  subtitle: 'Cherche des amis lecteurs pour partager tes livres.',
                  buttonLabel: 'Chercher un ami',
                  onPressed: () => context.push('/friends/search'),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final f = social.friends[i];
                  final myId = context.read<AuthProvider>().userId!;
                  final friendId = f.otherUserId(myId);
                  final user = SeedDataService.getUserById(friendId);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        (user?.displayName ?? '?')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user?.displayName ?? friendId),
                    subtitle: Text(user?.location ?? ''),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.push('/friends'),
                  );
                },
                childCount: social.friends.length,
              ),
            ),

          // Prêts actifs
          if (loans.activeLoanCount + loans.activeBorrowingCount > 0) ...[
            const SliverToBoxAdapter(child: Divider()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prêts & emprunts actifs',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/loans'),
                      child: const Text('Gérer'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _MiniStat(
                      icon: Icons.arrow_upward,
                      label: 'Prêtés',
                      value: '${loans.activeLoanCount}',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _MiniStat(
                      icon: Icons.arrow_downward,
                      label: 'Empruntés',
                      value: '${loans.activeBorrowingCount}',
                      color: AppColors.accent,
                    ),
                    if (loans.overdueCount > 0) ...[
                      const SizedBox(width: 12),
                      _MiniStat(
                        icon: Icons.warning_amber,
                        label: 'En retard',
                        value: '${loans.overdueCount}',
                        color: AppColors.error,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Onglet Profil
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Mon Profil'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      (auth.userProfile?.displayName ?? 'U')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    auth.userProfile?.displayName ?? 'Utilisateur',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (auth.userProfile?.username != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@${auth.userProfile!.username}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Stats from library
                  Builder(builder: (context) {
                    final library = context.watch<LibraryProvider>();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatCard(label: 'Livres', value: '${library.bookCount}'),
                        _StatCard(label: 'Genres', value: '${_countGenres(library)}'),
                        _StatCard(label: 'Auteurs', value: '${_countAuthors(library)}'),
                      ],
                    );
                  }),
                  const SizedBox(height: 32),
                  if (auth.isAnonymous)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.secondaryDark),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Crée ton compte pour accéder à toutes les fonctionnalités !',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: () => auth.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget état vide réutilisable
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.photo_camera),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

int _countGenres(LibraryProvider library) {
  final genres = <String>{};
  for (final book in library.books) {
    genres.addAll(book.genres);
  }
  return genres.length;
}

int _countAuthors(LibraryProvider library) {
  final authors = <String>{};
  for (final book in library.books) {
    for (final a in book.authors) {
      authors.add(a.name);
    }
  }
  return authors.length;
}

/// Mini-carte de stats
class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
