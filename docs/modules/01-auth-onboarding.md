# Module 1 : Authentification & Onboarding

## Methodes d'authentification

1. **Telephone (principale)** — OTP 6 chiffres via Firebase Auth
2. **Google Sign-In** — Android + Web
3. **Apple Sign-In** — iOS (obligatoire App Store)
4. **Anonyme** — Pour emprunteurs invites, avec bandeau upgrade

## Fichiers

| Fichier | Role |
|---------|------|
| `lib/features/auth/services/auth_service.dart` | Wrapper Firebase Auth |
| `lib/features/auth/providers/auth_provider.dart` | Etat auth (initial/unauthenticated/onboarding/authenticated) |
| `lib/features/auth/screens/login_screen.dart` | Ecran login phone + social |
| `lib/features/auth/screens/otp_verification_screen.dart` | Saisie code OTP |
| `lib/features/auth/screens/onboarding_screen.dart` | 4 pages PageView |
| `lib/features/auth/screens/splash_screen.dart` | Splash anime |

## Flow

```
App launch → Splash → Firebase Auth check
  → Non connecte → Login → OTP → Sync Supabase → Onboarding → Home
  → Connecte sans onboarding → Onboarding → Home
  → Connecte avec onboarding → Home
```

## Auth Guard (GoRouter)

Le redirect dans `AppRouter` gere 4 etats :
- `initial` → reste sur splash
- `unauthenticated` → redirige vers /login
- `onboarding` → force /onboarding
- `authenticated` → empeche retour login/splash

## Sync Supabase

A chaque connexion Firebase, `SupabaseService.syncUser()` appelle l'Edge Function `sync-user` qui cree/met a jour le profil dans la table `users`.
