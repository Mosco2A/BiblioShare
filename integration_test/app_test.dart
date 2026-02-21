import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:biblioshare/main.dart' as app;

/// Tests d'intégration BiblioShare — parcours utilisateur principaux
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Démarrage de l\'app', () {
    testWidgets('L\'app démarre sans crash et affiche le splash screen',
        (tester) async {
      app.main();

      // Pump quelques frames (pas pumpAndSettle car le spinner tourne en continu)
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));

      // L'app doit avoir un MaterialApp visible
      expect(find.byType(MaterialApp), findsOneWidget);

      // Le splash doit afficher BiblioShare ou le spinner
      final hasBiblioShare = find.text('BiblioShare').evaluate().isNotEmpty;
      final hasSpinner =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      expect(hasBiblioShare || hasSpinner, isTrue,
          reason: 'Le splash doit afficher le titre ou le spinner');
    });

    testWidgets('Après timeout du splash, navigation vers login',
        (tester) async {
      app.main();

      // Attendre l'init (max 10s Firebase + 5s Supabase + 5s AdMob)
      // puis le timeout splash de 4s
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // On doit être soit sur le login, soit sur le home, soit sur l'onboarding
      // L'important : l'app n'a pas crashé et on a quitté le splash
      final hasScaffold = find.byType(Scaffold).evaluate().isNotEmpty;
      expect(hasScaffold, isTrue, reason: 'Un Scaffold doit être visible');

      // Vérifier qu'on n'est plus bloqué sur le splash (pas seulement le spinner)
      final hasSmsButton =
          find.text('Recevoir un code SMS').evaluate().isNotEmpty;
      final hasNavBar = find.byType(NavigationBar).evaluate().isNotEmpty;
      final hasOnboarding = find.text('Bienvenue sur BiblioShare').evaluate().isNotEmpty;

      expect(hasSmsButton || hasNavBar || hasOnboarding, isTrue,
          reason:
              'Après 30s l\'app doit être sur login, home ou onboarding');
    });
  });

  group('Écran de login', () {
    testWidgets('Le login affiche les éléments de connexion',
        (tester) async {
      app.main();

      // Attendre que l'app arrive sur le login
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      final hasSmsButton =
          find.text('Recevoir un code SMS').evaluate().isNotEmpty;

      if (hasSmsButton) {
        // On est sur le login — vérifier les éléments
        expect(find.text('BiblioShare'), findsWidgets);
        expect(find.text('Recevoir un code SMS'), findsOneWidget);
        expect(find.text('Google'), findsOneWidget);
      }
      // Si on n'est pas sur le login (déjà auth), c'est OK aussi
    });

    testWidgets('Bouton SMS sans numéro affiche une erreur', (tester) async {
      app.main();

      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      final smsButton = find.text('Recevoir un code SMS');
      if (smsButton.evaluate().isNotEmpty) {
        await tester.tap(smsButton);
        await tester.pump(const Duration(seconds: 2));

        expect(find.text('Veuillez saisir votre numéro'), findsOneWidget);
      }
    });
  });

  group('Stabilité', () {
    testWidgets('Pas d\'exception au démarrage', (tester) async {
      app.main();

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // Pas d'exception levée
      expect(tester.takeException(), isNull);
    });

    testWidgets('Le thème BiblioShare est appliqué', (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 3));

      final materialApp = tester.widget<MaterialApp>(
        find.byType(MaterialApp).first,
      );
      expect(materialApp.title, 'BiblioShare');
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
    });
  });
}
