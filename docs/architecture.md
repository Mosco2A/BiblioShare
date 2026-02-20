# Architecture BiblioShare

## Vue d'ensemble

BiblioShare est une application Flutter de gestion de bibliotheque personnelle et sociale. L'architecture suit un pattern **3 couches** :

```
UI (Flutter/Material 3)
  |
Providers (ChangeNotifier via Provider)
  |
Services (CRUD Supabase + APIs externes)
  |
Backend (Supabase PostgreSQL + Edge Functions + Firebase Auth)
```

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Frontend | Flutter 3.x, Material 3, GoRouter |
| State management | Provider (ChangeNotifier) |
| Auth | Firebase Auth (phone OTP, Google, Apple, anonymous) |
| Base de donnees | Supabase (PostgreSQL) avec RLS |
| Backend serverless | Supabase Edge Functions (Deno/TypeScript) |
| IA Vision | Claude API (Sonnet) pour scan d'etagere |
| Enrichissement | Google Books API + Open Library API |
| Monetisation | Google AdMob (banner + interstitial) |

## Structure du projet

```
lib/
├── core/
│   ├── constants/       # App constants, API keys
│   ├── router/          # GoRouter config + auth guard
│   ├── services/        # Supabase client, AdMob
│   ├── theme/           # Material 3 theme, colors
│   └── utils/           # Extensions
│
├── features/
│   ├── auth/            # Module 1: Auth & Onboarding
│   │   ├── providers/
│   │   ├── screens/
│   │   └── services/
│   │
│   ├── home/            # Home screen avec 4 onglets
│   │   └── screens/
│   │
│   ├── library/         # Modules 4-5: Livres, avis, journal
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   │
│   ├── profile/         # Module 2: Profil & Parametres
│   │   ├── providers/
│   │   ├── screens/
│   │   └── services/
│   │
│   ├── scan/            # Module 3: Scan & Reconnaissance
│   │   ├── providers/
│   │   ├── screens/
│   │   └── services/
│   │
│   └── social/          # Modules 6-8: Social, Recos, Prets
│       ├── providers/
│       ├── screens/
│       └── services/
│
├── shared/
│   ├── models/          # Modeles de donnees (Dart)
│   └── widgets/         # Widgets partages
│
└── main.dart            # Point d'entree

supabase/
├── functions/           # Edge Functions (Deno/TypeScript)
│   ├── scan-shelf/      # Analyse photo etagere via Claude
│   ├── enrich-book/     # Enrichissement Google Books + Open Library
│   └── sync-user/       # Sync Firebase Auth -> Supabase
│
└── migrations/          # SQL schema + RLS policies
    └── 001_initial_schema.sql
```

## Navigation

GoRouter avec auth guard. Les routes sont definies dans `AppRoutes` :

| Route | Ecran | Auth requise |
|-------|-------|-------------|
| `/` | Splash | Non |
| `/login` | Login phone/social | Non |
| `/otp` | Verification OTP | Non |
| `/onboarding` | Onboarding 4 pages | Oui |
| `/home` | Home (4 onglets) | Oui |
| `/scan` | Scanner camera | Oui |
| `/scan/results` | Validation scan | Oui |
| `/book/:id` | Detail livre | Oui |
| `/book/:id/review` | Notation/avis | Oui |
| `/book/:id/recommend` | Recommander | Oui |
| `/book/:id/lend` | Preter | Oui |
| `/friends` | Liste amis | Oui |
| `/friends/search` | Rechercher amis | Oui |
| `/loans` | Dashboard prets | Oui |
| `/profile` | Profil | Oui |
| `/settings` | Parametres | Oui |

## Providers

| Provider | Responsabilite |
|----------|---------------|
| `AuthProvider` | Etat auth Firebase, sync Supabase |
| `ProfileProvider` | Profil utilisateur |
| `LibraryProvider` | Liste livres, CRUD |
| `ReviewProvider` | Avis, notes, progression lecture |
| `ScanProvider` | Machine a etats scan |
| `SocialProvider` | Amis, demandes, feed |
| `LoanProvider` | Prets et emprunts |

## Securite

- **Firebase Auth** gere les tokens JWT
- **Supabase RLS** (Row Level Security) sur toutes les tables sensibles
- Les Edge Functions valident les requetes
- Les cles API sont dans les variables d'environnement Supabase
