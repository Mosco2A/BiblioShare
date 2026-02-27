import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:biblioshare/features/library/providers/library_provider.dart';
import 'package:biblioshare/features/social/providers/social_provider.dart';
import 'package:biblioshare/features/social/providers/loan_provider.dart';

import 'test_app.dart';

/// Tests d'acceptance utilisateur — BiblioShare
///
/// Simulent un vrai utilisateur connecté qui utilise l'app :
/// 1. Vérifier que le home s'affiche avec les 4 onglets
/// 2. Naviguer dans la bibliothèque et consulter des livres
/// 3. Vérifier le scanner
/// 4. Vérifier le social (amis, prêts)
/// 5. Vérifier le profil et la déconnexion
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Helper : attendre qu'un widget apparaisse
  Future<bool> waitFor(
    WidgetTester tester,
    Finder finder, {
    int seconds = 15,
  }) async {
    for (int i = 0; i < seconds; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  // ════════════════════════════════════════════════════════════
  // PARCOURS 1 : Home — 4 onglets visibles après connexion
  // ════════════════════════════════════════════════════════════

  group('Parcours 1 — Home et navigation', () {
    testWidgets(
      'Le home affiche les 4 onglets après connexion',
      (tester) async {
        await initTestApp();

        final homeReady = await waitFor(
          tester,
          find.byType(NavigationBar),
        );
        expect(homeReady, isTrue,
            reason: 'Le home doit s\'afficher avec la NavigationBar');

        // 4 onglets dans la NavigationBar
        expect(find.text('Bibliothèque'), findsOneWidget);
        expect(find.text('Scanner'), findsOneWidget);
        expect(find.text('Social'), findsOneWidget);
        expect(find.text('Profil'), findsOneWidget);

        // Attendre que les chargements async (Supabase fallback → seed)
        // se terminent pour éviter des dispose pendant l'async
        await tester.pump(const Duration(seconds: 6));
      },
    );
  });

  // ════════════════════════════════════════════════════════════
  // PARCOURS 2 : Bibliothèque — livres seed visibles
  // ════════════════════════════════════════════════════════════

  group('Parcours 2 — Bibliothèque', () {
    testWidgets(
      'La bibliothèque affiche les livres seed avec titres et auteurs',
      (tester) async {
        final authProvider = await initTestApp();
        await waitFor(tester, find.byType(NavigationBar));

        // SliverAppBar.large rend le titre 2 fois (expanded + collapsed)
        expect(find.text('Ma Bibliothèque'), findsWidgets);

        // Charger les livres via le provider
        final libraryProvider = tester
            .element(find.byType(NavigationBar))
            .read<LibraryProvider>();
        await libraryProvider
            .loadBooks(authProvider.userId ?? 'test-user-acceptance');
        await tester.pump(const Duration(seconds: 2));

        // Des livres OU l'état vide
        final hasBooks = find.byType(ListTile).evaluate().isNotEmpty;
        final hasEmptyState =
            find.text('Aucun livre pour l\'instant').evaluate().isNotEmpty;

        expect(hasBooks || hasEmptyState, isTrue,
            reason: 'Doit afficher les livres ou l\'état vide');

        if (hasBooks) {
          final knownTitles = [
            "L'Étranger",
            'Le Petit Prince',
            'Les Misérables',
            'Germinal',
            'Madame Bovary',
          ];
          final foundTitles = knownTitles
              .where((t) => find.text(t).evaluate().isNotEmpty)
              .toList();

          expect(foundTitles, isNotEmpty,
              reason: 'Au moins un livre seed doit être visible');

          final tileCount = find.byType(ListTile).evaluate().length;
          expect(tileCount, greaterThanOrEqualTo(3),
              reason: 'Au moins 3 livres seed doivent être listés');
        }
      },
    );

    testWidgets(
      'Taper sur un livre ouvre sa page de détail',
      (tester) async {
        final authProvider = await initTestApp();
        await waitFor(tester, find.byType(NavigationBar));

        final libraryProvider = tester
            .element(find.byType(NavigationBar))
            .read<LibraryProvider>();
        await libraryProvider
            .loadBooks(authProvider.userId ?? 'test-user-acceptance');
        await tester.pump(const Duration(seconds: 2));

        final listTiles = find.byType(ListTile);
        if (listTiles.evaluate().isEmpty) return;

        // Taper sur le premier livre
        await tester.tap(listTiles.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Page de détail : Scaffold visible
        final hasScaffold = find.byType(Scaffold).evaluate().isNotEmpty;
        expect(hasScaffold, isTrue,
            reason: 'La page de détail doit avoir un Scaffold');

        // On doit être sur le détail (menu popup) OU "Livre introuvable"
        final hasPopupMenu =
            find.byType(PopupMenuButton<String>).evaluate().isNotEmpty;
        final hasNotFound =
            find.text('Livre introuvable').evaluate().isNotEmpty;
        expect(hasPopupMenu || hasNotFound, isTrue,
            reason: 'Doit afficher le détail ou "Livre introuvable"');
      },
    );
  });

  // ════════════════════════════════════════════════════════════
  // PARCOURS 3 : Scanner — invitation à scanner visible
  // ════════════════════════════════════════════════════════════

  group('Parcours 3 — Scanner', () {
    testWidgets(
      'L\'onglet Scanner invite à scanner une étagère',
      (tester) async {
        await initTestApp();
        await waitFor(tester, find.byType(NavigationBar));

        await tester.tap(find.text('Scanner'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text('Scanne ton étagère'), findsOneWidget);
        expect(
          find.textContaining('BiblioShare identifie chaque livre'),
          findsOneWidget,
        );
        expect(find.text('Ouvrir la caméra'), findsOneWidget);
      },
    );
  });

  // ════════════════════════════════════════════════════════════
  // PARCOURS 4 : Social — amis et prêts
  // ════════════════════════════════════════════════════════════

  group('Parcours 4 — Social', () {
    testWidgets(
      'L\'onglet Social affiche les sections amis/prêts',
      (tester) async {
        final authProvider = await initTestApp();
        await waitFor(tester, find.byType(NavigationBar));

        await tester.tap(find.text('Social'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Charger les données sociales
        final socialProvider = tester
            .element(find.byType(NavigationBar))
            .read<SocialProvider>();
        final loanProvider = tester
            .element(find.byType(NavigationBar))
            .read<LoanProvider>();
        final userId = authProvider.userId ?? 'test-user-acceptance';
        await socialProvider.loadFriends(userId);
        await loanProvider.loadLoans(userId);
        await tester.pump(const Duration(seconds: 2));

        // Le titre "Social" (dans le SliverAppBar + nav bar)
        expect(find.text('Social'), findsWidgets);

        // Bouton ajouter un ami
        expect(find.byIcon(Icons.person_add_outlined), findsOneWidget);

        // Soit des amis seed, soit l'état vide
        final hasFriendSection =
            find.textContaining('Mes amis').evaluate().isNotEmpty;
        final hasEmptyState =
            find.text('Aucun ami pour l\'instant').evaluate().isNotEmpty;

        expect(hasFriendSection || hasEmptyState, isTrue,
            reason: 'Doit afficher les amis ou l\'état vide');

        if (hasFriendSection) {
          // Scroller pour faire apparaître les amis (les demandes en attente
          // peuvent pousser les amis hors de l'écran)
          await tester.drag(
            find.byType(CustomScrollView).last,
            const Offset(0, -300),
          );
          await tester.pumpAndSettle(const Duration(seconds: 1));

          final knownFriends = [
            'Marie Dupont',
            'Thomas Martin',
            'Sophie Bernard',
          ];
          final foundFriends = knownFriends
              .where((n) => find.text(n).evaluate().isNotEmpty)
              .toList();

          expect(foundFriends, isNotEmpty,
              reason: 'Au moins un ami seed doit être visible');
        }
      },
    );
  });

  // ════════════════════════════════════════════════════════════
  // PARCOURS 5 : Profil — infos utilisateur et stats
  // ════════════════════════════════════════════════════════════

  group('Parcours 5 — Profil', () {
    testWidgets(
      'L\'onglet Profil affiche nom, avatar, stats et bouton déconnexion',
      (tester) async {
        await initTestApp();
        await waitFor(tester, find.byType(NavigationBar));

        // Naviguer vers Profil
        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Titre "Mon Profil" (SliverAppBar.large = 2 instances)
        expect(find.text('Mon Profil'), findsWidgets);

        // Avatar
        expect(find.byType(CircleAvatar), findsWidgets);

        // Nom utilisateur
        final hasName = find.text('Utilisateur Test').evaluate().isNotEmpty ||
            find.text('Utilisateur').evaluate().isNotEmpty;
        expect(hasName, isTrue,
            reason: 'Le profil doit afficher le nom de l\'utilisateur');

        // Stats
        expect(find.text('Livres'), findsOneWidget);
        expect(find.text('Genres'), findsOneWidget);
        expect(find.text('Auteurs'), findsOneWidget);

        // Bouton de déconnexion
        expect(find.text('Se déconnecter'), findsOneWidget);

        // Bouton paramètres
        expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'Depuis le Profil, on peut revenir aux autres onglets',
      (tester) async {
        await initTestApp();
        await waitFor(tester, find.byType(NavigationBar));

        // Aller sur Profil
        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.text('Mon Profil'), findsWidgets);

        // La NavigationBar doit être visible et tappable
        expect(find.byType(NavigationBar), findsOneWidget);

        // Revenir à Bibliothèque depuis le profil
        await tester.tap(find.text('Bibliothèque'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.text('Ma Bibliothèque'), findsWidgets);

        // Retour sur Profil
        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.text('Mon Profil'), findsWidgets);

        // Aller sur Social depuis le profil
        await tester.tap(find.text('Social'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.text('Social'), findsWidgets);
      },
    );
  });

  // ════════════════════════════════════════════════════════════
  // PARCOURS 6 : Scanner depuis la bibliothèque (FAB)
  // ════════════════════════════════════════════════════════════

  group('Parcours 6 — Scanner depuis la bibliothèque', () {
    testWidgets(
      'Le bouton scanner (FAB) est visible quand il y a des livres',
      (tester) async {
        final authProvider = await initTestApp();
        await waitFor(tester, find.byType(NavigationBar));

        // Charger les livres seed
        final libraryProvider = tester
            .element(find.byType(NavigationBar))
            .read<LibraryProvider>();
        await libraryProvider
            .loadBooks(authProvider.userId ?? 'test-user-acceptance');
        await tester.pump(const Duration(seconds: 2));

        final hasBooks = find.byType(ListTile).evaluate().isNotEmpty;
        if (hasBooks) {
          // Le FAB caméra doit être visible
          expect(find.byType(FloatingActionButton), findsOneWidget);
          expect(find.byIcon(Icons.photo_camera), findsWidgets);
        }
      },
    );
  });

  // ════════════════════════════════════════════════════════════
  // PARCOURS 7 : Navigation complète sans crash
  // ════════════════════════════════════════════════════════════

  group('Parcours 7 — Navigation complète', () {
    testWidgets(
      'Naviguer entre les 4 onglets aller-retour sans crash',
      (tester) async {
        await initTestApp();
        await waitFor(tester, find.byType(NavigationBar));

        // 1. Bibliothèque (déjà dessus)
        expect(find.text('Ma Bibliothèque'), findsWidgets);

        // 2. Scanner
        await tester.tap(find.text('Scanner'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.text('Scanne ton étagère'), findsOneWidget);

        // 3. Social
        await tester.tap(find.text('Social'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.text('Social'), findsWidgets);

        // 4. Profil
        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.text('Mon Profil'), findsWidgets);

        // Retour : Profil → Scanner → Bibliothèque
        await tester.tap(find.text('Scanner'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(find.text('Scanne ton étagère'), findsOneWidget);

        await tester.tap(find.text('Bibliothèque'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(find.text('Ma Bibliothèque'), findsWidgets);

        // Aucune exception
        expect(tester.takeException(), isNull);
      },
    );
  });

  // ════════════════════════════════════════════════════════════
  // PARCOURS 8 : Détail livre — actions disponibles
  // ════════════════════════════════════════════════════════════

  group('Parcours 8 — Détail livre complet', () {
    testWidgets(
      'Le détail d\'un livre affiche couverture, infos et actions',
      (tester) async {
        final authProvider = await initTestApp();
        await waitFor(tester, find.byType(NavigationBar));

        final libraryProvider = tester
            .element(find.byType(NavigationBar))
            .read<LibraryProvider>();
        await libraryProvider
            .loadBooks(authProvider.userId ?? 'test-user-acceptance');
        await tester.pump(const Duration(seconds: 2));

        final listTiles = find.byType(ListTile);
        if (listTiles.evaluate().isEmpty) return;

        // Ouvrir le premier livre
        await tester.tap(listTiles.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Le menu actions doit être présent
        final hasPopupMenu =
            find.byType(PopupMenuButton<String>).evaluate().isNotEmpty;
        if (hasPopupMenu) {
          // Boutons d'action principaux visibles directement sur la page
          expect(find.text('Noter / Avis'), findsOneWidget);
          // "Prêter" est un bouton d'action + sera dans le popup
          expect(find.text('Prêter'), findsWidgets);

          // Ouvrir le popup menu
          await tester.tap(find.byType(PopupMenuButton<String>));
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Vérifier les items du popup (Modifier, Prêter, Recommander, Supprimer)
          expect(find.text('Modifier'), findsOneWidget);
          expect(find.text('Recommander'), findsOneWidget);
          expect(find.text('Supprimer'), findsOneWidget);

          // Fermer le menu en tapant ailleurs
          await tester.tapAt(Offset.zero);
          await tester.pumpAndSettle();
        }
      },
    );
  });

  // ════════════════════════════════════════════════════════════
  // PARCOURS 9 : Thème et identité visuelle
  // ════════════════════════════════════════════════════════════

  group('Parcours 9 — Thème et design', () {
    testWidgets(
      'L\'app applique le thème BiblioShare correctement',
      (tester) async {
        await initTestApp();
        await waitFor(tester, find.byType(MaterialApp));

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp).first,
        );
        expect(materialApp.title, 'BiblioShare');
        expect(materialApp.debugShowCheckedModeBanner, isFalse);
        expect(materialApp.theme, isNotNull);
        expect(materialApp.darkTheme, isNotNull);
      },
    );
  });
}
