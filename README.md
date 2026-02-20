# BiblioShare

Scanner d'etagere, enrichissement web, bibliotheque sociale & gestion de prets.

## Fonctionnalites

- **Scan d'etagere** : Photographiez votre etagere, BiblioShare identifie chaque livre grace a l'IA (Claude Vision)
- **Enrichissement automatique** : Metadonnees completes via Google Books + Open Library
- **Avis & Journal de lecture** : Notez vos lectures avec 6 criteres detailles, suivez votre progression
- **Bibliotheque sociale** : Invitez vos amis, partagez vos coups de coeur
- **Recommandations** : Recommandez un livre a un ami avec un message personnalise
- **Gestion des prets** : Suivez qui a emprunte quoi, avec alertes de retour

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Frontend | Flutter 3.x, Material 3 |
| Navigation | GoRouter |
| State | Provider (ChangeNotifier) |
| Auth | Firebase Auth (phone OTP, Google, Apple) |
| Database | Supabase (PostgreSQL + RLS) |
| Backend | Supabase Edge Functions (Deno) |
| IA | Claude API (Sonnet) |
| Enrichissement | Google Books API + Open Library API |
| Ads | Google AdMob |

## Getting started

### Prerequis

- Flutter SDK >= 3.0
- Compte Firebase (Auth)
- Compte Supabase (database + Edge Functions)
- Cle API Anthropic (Claude Vision)

### Installation

```bash
# Cloner le repo
git clone https://github.com/Mosco2A/BiblioShare.git
cd BiblioShare

# Installer les dependances
flutter pub get

# Configurer les variables
# 1. Firebase : ajouter google-services.json (Android) et GoogleService-Info.plist (iOS)
# 2. Supabase : editer lib/core/constants/app_constants.dart avec votre URL et cle
# 3. Edge Functions : deployer les fonctions supabase/functions/*
# 4. SQL : executer supabase/migrations/001_initial_schema.sql

# Lancer
flutter run
```

### Deploiement Supabase

```bash
# Deployer les Edge Functions
supabase functions deploy scan-shelf
supabase functions deploy enrich-book
supabase functions deploy sync-user

# Variables d'environnement requises
supabase secrets set ANTHROPIC_API_KEY=sk-...
supabase secrets set GOOGLE_BOOKS_API_KEY=...
```

## Modules

| # | Module | Statut |
|---|--------|--------|
| 1 | Authentification & Onboarding | Complet |
| 2 | Profil & Parametres | Complet |
| 3 | Scan & Reconnaissance | Complet |
| 4 | Enrichissement Web | Complet |
| 5 | Avis & Journal de lecture | Complet |
| 6 | Bibliotheque Sociale | Complet |
| 7 | Recommandations | Complet |
| 8 | Gestion des Prets | Complet |
| 9 | Documentation | Complet |

## Documentation

Voir le dossier [`docs/`](docs/) pour la documentation complete :
- [`docs/architecture.md`](docs/architecture.md) — Vue d'ensemble de l'architecture
- [`docs/modules/`](docs/modules/) — Documentation par module
- [`docs/supabase/schema.md`](docs/supabase/schema.md) — Schema de base de donnees

## Licence

Projet prive.
