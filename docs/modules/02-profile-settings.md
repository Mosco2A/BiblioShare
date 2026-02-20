# Module 2 : Profil & Parametres

## Profil utilisateur

Le profil est stocke dans Supabase table `users` et synchronise via `ProfileProvider`.

### Champs

- Nom d'affichage, username unique (@...)
- Email, telephone
- Photo de profil (URL)
- Bio (280 car. max)
- Localisation, genres preferes
- Lien externe (Goodreads, blog...)
- Locale, timezone
- Providers auth lies

## Fichiers

| Fichier | Role |
|---------|------|
| `lib/shared/models/user_model.dart` | Modele de donnees |
| `lib/shared/models/user_settings_model.dart` | Preferences utilisateur |
| `lib/features/profile/services/profile_service.dart` | CRUD Supabase |
| `lib/features/profile/providers/profile_provider.dart` | State management |
| `lib/features/profile/screens/profile_screen.dart` | Affichage profil |
| `lib/features/profile/screens/edit_profile_screen.dart` | Edition profil |

## Stats affichees

- Nombre total de livres
- Nombre de livres lus
- Nombre d'amis
- Objectif de lecture annuel
