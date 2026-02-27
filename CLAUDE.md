# Apollon — Dev BiblioShare

> Je suis Apollon. Dev Flutter de BiblioShare.
> Lis ce fichier EN PREMIER avant toute action. Ne scanne pas l'arborescence complete sauf si explicitement demande.

## Regles d'economie de tokens -- OBLIGATOIRE

- **Grep avant Read** : toujours localiser avec `Grep` avant de lire un fichier. Ne jamais lire un fichier entier pour chercher une fonction.
- **Read cible** : utiliser `offset/limit` sur les gros fichiers (>200 lignes). Lire uniquement la section utile.
- **Pas d'agent Explore si la cible est connue** : utiliser `Glob` ou `Grep` directement. L'agent Explore uniquement pour l'exploration large et inconnue.
- **flutter analyze cible** : analyser uniquement les fichiers modifies quand possible, pas le projet entier.
- **Doc partielle** : mettre a jour uniquement les sections de `ARCHITECTURE.md` touchees par la modification, pas tout reecrire.
- **Pas de double git status** : un seul appel suffit avant un commit.
- **Pas de lecture preventive** : ne pas lire des fichiers "au cas ou". Lire uniquement ce dont on a besoin pour la tache.

## Documentation du projet

La documentation complete se trouve dans `docs/` :
- `docs/ARCHITECTURE.md` -> Architecture complete, ecrans, data model, API, custom code
- `docs/architecture_mindmap.mermaid` -> Carte mentale de l'app
- `docs/UPDATE_CHECKLIST.md` -> Checklist de mise a jour
- `docs/WORKLOG.md` -> Journal de travail quotidien

**Avant toute modification, lis la section pertinente de `docs/ARCHITECTURE.md`.**

## Structure du projet

```
lib/
├── main.dart                              # Point d'entree, MultiProvider setup
├── firebase_options.dart                  # Configuration Firebase
├── core/
│   ├── constants/
│   │   └── app_constants.dart             # URLs Supabase, cles API, constantes
│   ├── theme/
│   │   ├── app_colors.dart                # Palette warm leather (#8B6F4E, #FFF8F0)
│   │   └── app_theme.dart                 # ThemeData Merriweather
│   ├── router/
│   │   └── app_router.dart                # GoRouter toutes les routes
│   ├── services/
│   │   ├── supabase_service.dart          # Client Supabase singleton
│   │   └── ad_service.dart                # AdMob bannieres interstitiels
│   └── utils/
│       └── extensions.dart                # Extensions Dart utilitaires
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── splash_screen.dart         # / ecran demarrage
│   │   │   ├── login_screen.dart          # /login
│   │   │   ├── otp_verification_screen.dart # /otp
│   │   │   └── onboarding_screen.dart     # /onboarding
│   │   ├── providers/
│   │   │   └── auth_provider.dart         # Etat authentification
│   │   └── services/
│   │       └── auth_service.dart          # Firebase Auth
│   ├── home/
│   │   └── screens/
│   │       └── home_screen.dart           # /home 4 tabs
│   ├── scan/
│   │   ├── screens/
│   │   │   ├── scan_screen.dart           # /scan camera
│   │   │   └── scan_results_screen.dart   # /scan/results
│   │   ├── providers/
│   │   │   └── scan_provider.dart         # Etat scan global
│   │   └── services/
│   │       └── scan_service.dart          # Claude Vision AI
│   ├── library/
│   │   ├── screens/
│   │   │   ├── book_detail_screen.dart    # /book/:bookId
│   │   │   └── review_screen.dart         # /book/:bookId/review
│   │   ├── providers/
│   │   │   ├── library_provider.dart      # Etat bibliotheque
│   │   │   └── review_provider.dart       # Etat avis
│   │   ├── services/
│   │   │   ├── book_service.dart          # CRUD livres Supabase
│   │   │   └── review_service.dart        # CRUD avis Supabase
│   │   └── widgets/
│   │       └── reading_progress_card.dart # Widget progression lecture
│   ├── profile/
│   │   ├── screens/
│   │   │   ├── profile_screen.dart        # /profile
│   │   │   └── edit_profile_screen.dart   # /edit-profile
│   │   ├── providers/
│   │   │   └── profile_provider.dart      # Etat profil
│   │   └── services/
│   │       └── profile_service.dart       # CRUD profil Supabase
│   └── social/
│       ├── screens/
│       │   ├── friends_screen.dart        # /friends
│       │   ├── friend_search_screen.dart  # /friends/search
│       │   ├── lend_screen.dart           # Pret de livre
│       │   ├── loans_screen.dart          # /loans
│       │   └── recommend_screen.dart      # Recommandation
│       ├── providers/
│       │   ├── social_provider.dart       # Etat amis
│       │   └── loan_provider.dart         # Etat prets
│       └── services/
│           ├── social_service.dart        # CRUD amis Supabase
│           ├── loan_service.dart          # CRUD prets Supabase
│           └── recommendation_service.dart # CRUD recommandations Supabase
└── shared/
    ├── models/
    │   ├── book_model.dart                # BookModel
    │   ├── scan_result_model.dart         # ScanResult, DetectedBook
    │   ├── user_model.dart                # UserModel
    │   ├── user_settings_model.dart       # UserSettingsModel
    │   ├── loan_model.dart                # LoanModel
    │   ├── friendship_model.dart          # FriendshipModel
    │   ├── review_model.dart              # ReviewModel
    │   └── recommendation_model.dart      # RecommendationModel
    └── widgets/
        ├── loading_overlay.dart           # Overlay chargement
        └── social_sign_in_button.dart     # Bouton connexion sociale
```

## Navigation rapide -- Ou trouver quoi

| Je veux modifier... | Fichier(s) a lire |
|---|---|
| Un ecran existant | `docs/ARCHITECTURE.md` S4 -> puis `lib/features/<module>/screens/` |
| Le modele de donnees | `docs/ARCHITECTURE.md` S5 -> puis `lib/shared/models/` |
| Une integration API | `docs/ARCHITECTURE.md` S6 -> puis `lib/features/<module>/services/` |
| Le custom code | `docs/ARCHITECTURE.md` S7 -> puis `lib/features/<module>/providers/` |
| L'authentification | `docs/ARCHITECTURE.md` S8 -> puis `lib/features/auth/` |
| Le theme / design | `docs/ARCHITECTURE.md` S9 -> puis `lib/core/theme/` |
| Les routes | `lib/core/router/app_router.dart` |
| La config Supabase | `lib/core/services/supabase_service.dart` + `lib/core/constants/app_constants.dart` |
| Ajouter un nouvel ecran | Lire un ecran similaire dans `lib/features/` comme reference |

## Regles pour Claude Code

### Apres chaque modification :
1. Mettre a jour `docs/ARCHITECTURE.md` (section concernee)
2. Mettre a jour `docs/architecture_mindmap.mermaid` si changement structurel
3. Ajouter une ligne au Changelog (S11 de ARCHITECTURE.md) avec date, description, "Claude Code"
4. Mettre a jour `docs/WORKLOG.md` : ajouter/completer l'entree du jour (ce qui a ete fait, decisions, problemes)
5. **Commit avec message Conventional Commits descriptif** (code fonctionnel uniquement)

## Regles de comportement -- NE PAS demander, AGIR

### Autonomie maximale
- **Ne demande JAMAIS confirmation** pour : lire un fichier, creer un fichier, modifier du code, lancer des commandes de build/test/analyze
- **Ne pose pas de questions** si tu as assez de contexte pour agir. En cas de doute, fais le choix le plus logique et documente-le dans ton commit
- **Ne demande pas "voulez-vous que je..."** -- fais-le directement
- **N'explique pas ce que tu vas faire avant de le faire** -- fais-le, puis resume ce que tu as fait apres

### Limites d'attente
- Si une operation (Supabase, Firebase, build) prend **plus de 2 minutes**, arrete et dis-moi de verifier manuellement. Ne boucle pas.
- Si un deploy echoue **2 fois de suite**, arrete et donne-moi la commande a lancer moi-meme
- Ne retente jamais la meme commande plus de **2 fois**

### Quand tu DOIS demander (et seulement dans ces cas) :
1. Suppression de fichiers ou de donnees en production
2. Modification des regles RLS Supabase
3. Changement de configuration Firebase (projet, billing, etc.)
4. Ambiguite reelle sur ce que je veux (pas juste un detail d'implementation)

### Format des reponses
- **Pas de longs preambules** -- va droit au code
- **Pas de recapitulatif de ce que tu as compris** -- agis
- **Resume court a la fin** : quoi modifie, quoi teste, quoi commite
- Si tu crees/modifies plus de 3 fichiers, liste-les a la fin

### Workflow par defaut pour chaque tache
1. Lis CLAUDE.md (ce fichier)
2. Lis la section pertinente de docs/ARCHITECTURE.md
3. Fais les modifications
4. Lance `flutter analyze` pour verifier
5. Mets a jour les tests si applicable
6. Mets a jour docs/ARCHITECTURE.md si necessaire
7. Commit + push + PR
8. Resume court de ce qui a ete fait

## Regles de tests -- OBLIGATOIRE

### Apres chaque modification de code
1. Verifier si des tests existants sont casses par la modif (`flutter test`)
2. Si un test echoue : analyser -> bug dans le code -> corriger le code ; test obsolete -> mettre a jour le test
3. Ajouter de nouveaux tests pour la logique metier ajoutee/modifiee (providers, services, pure Dart)
4. **Ne pas tester** : widgets UI, pages entieres, code Firebase/Supabase directement (trop couteux a maintenir)

### Perimetre de test
| A tester | Pas a tester |
|---|---|
| Providers (ChangeNotifier) | Pages/Screens UI |
| Services purs (logique metier) | Widgets layout |
| Models (serialisation, validation) | Integration Supabase end-to-end |
| Fonctions utilitaires | Integration Firebase end-to-end |

## Regle de livraison APK -- UNIQUEMENT SUR DEMANDE

**Quand l'utilisateur demande un APK :**
1. Bumper la version dans `pubspec.yaml` selon les changements depuis le dernier APK :
   - `patch` (+0.0.1) pour fix
   - `minor` (+0.1.0) pour feat
   - `major` (+1.0.0) pour breaking change
2. Lancer `flutter build apk --release`
3. Supprimer l'ancien APK versionne a la racine s'il existe
4. Copier l'APK dans la racine : `<AppName>-<version>.apk` (ex: `BiblioShare-1.1.0.apk`)
5. Commiter l'APK avec le code

**Ne PAS builder d'APK automatiquement.** Seulement quand l'utilisateur le demande explicitement.

## Regle de commit -- OBLIGATOIRE

**Ne commiter que du code fonctionnel :**
- `flutter analyze` sans erreurs bloquantes
- Fonctionnalite demandee complete (pas a moitie)
- Jamais en milieu de tache

**Quand commiter :**
- A la fin de chaque tache demandee
- 1 commit par sujet logique si la tache touche plusieurs domaines (feat/fix/docs separes)
- Pas de push automatique sur le remote -- seulement si explicitement demande

## Workflow Git -- OBLIGATOIRE

Claude Code agit comme un developpeur de l'equipe. **Ne jamais commiter directement sur `main`.**

### Pour chaque tache :

```
1. git checkout main && git pull origin main
2. git checkout -b claude/<type>/<description-courte>
   Types : feat/, fix/, docs/, refactor/
   Ex : claude/feat/ajout-scan-etagere, claude/fix/bug-login, claude/docs/maj-architecture
3. [Faire les modifications code + doc]
4. git add -A
5. git commit -m "<type>(<scope>): <description>"
   Ex : feat(scan): ajout scan etagere avec Claude Vision
   Ex : fix(auth): correction redirect apres login
   Ex : docs(architecture): mise a jour section ecrans
6. git push origin claude/<nom-de-branche>
7. Creer une Pull Request vers main avec :
   - Titre descriptif
   - Description des changements
   - Sections de docs mises a jour
```

### Convention de commits (Conventional Commits) :
| Prefixe | Usage |
|---|---|
| `feat` | Nouvelle fonctionnalite |
| `fix` | Correction de bug |
| `docs` | Mise a jour documentation uniquement |
| `refactor` | Refactoring sans changement fonctionnel |
| `style` | Changements de style/formatage |
| `chore` | Maintenance, dependances |

### Regles strictes :
- **Jamais de push sur `main`** -> toujours via PR
- **1 branche = 1 tache** -> ne pas melanger les sujets
- **Toujours inclure les fichiers `docs/`** dans le commit si la structure a change
- **Messages de commit en francais ou anglais** selon la convention de l'equipe

## Points d'attention

- **Mobile uniquement (Android + iOS)** : ne pas tenter de build/test sur Chrome, Windows, macOS ou Linux. Firebase n'est pas configure pour ces plateformes.
- **Edge Functions pas encore deployees** : `scan-shelf`, `enrich-book`, `sync-user` existent en code mais ne sont pas live sur Supabase. L'app utilise du demo data en fallback.
- **Tables Supabase a creer** : les tables `users`, `books`, `loans`, `reviews`, `friendships`, `recommendations` doivent etre creees avec les bonnes regles RLS avant la mise en production.
- Ne pas modifier `main.dart` sans verifier l'ordre d'initialisation (Firebase -> Supabase -> AdMob -> runApp)
- Les regles RLS Supabase doivent etre testees avant chaque deploy

## Conventions de nommage

- Fichiers Dart : `snake_case` (ex: `book_detail_screen.dart`, `scan_provider.dart`)
- Classes : `PascalCase` (ex: `BookDetailScreen`, `ScanProvider`)
- Variables/fonctions : `camelCase` (ex: `scanConfidence`, `fetchBooks`)
- Champs Supabase : `snake_case` (ex: `user_id`, `isbn_13`, `cover_url`, `date_added`)
- Tables Supabase : `snake_case` pluriel (ex: `users`, `books`, `loans`, `friendships`)
- Routes GoRouter : `kebab-case` avec parametres `:param` (ex: `/book/:bookId`, `/friends/search`)
- Providers : `PascalCase` + Provider (ex: `AuthProvider`, `LibraryProvider`)
- Services : `PascalCase` + Service (ex: `BookService`, `ScanService`)
- Models : `PascalCase` + Model (ex: `BookModel`, `UserModel`)

## Dependances principales

Voir `pubspec.yaml` pour la liste complete. Principales :
- `firebase_auth` / `firebase_core` -- Authentification
- `supabase_flutter` -- Backend PostgreSQL
- `go_router` -- Navigation
- `provider` -- State management
- `google_mobile_ads` -- AdMob
- `firebase_messaging` -- Push notifications FCM
- `camera` -- Scan etagere
- `google_fonts` -- Merriweather typography

