# Checklist de mise a jour -- BiblioShare

> Utiliser ce fichier a chaque modification significative du projet.

---

## Avant la modification

- [ ] Lire la section concernee dans `ARCHITECTURE.md`
- [ ] Verifier la carte mentale `architecture_mindmap.mermaid`
- [ ] Noter la version actuelle : ____________________
- [ ] Creer une branche Git : `git checkout -b feature/nom-de-la-feature`

---

## Apres la modification

### Mise a jour ARCHITECTURE.md

- [ ] **Section 4 (Ecrans)** -- si ajout, suppression ou modification d'une page/route
- [ ] **Section 5 (Donnees)** -- si ajout/modification de table, champ, ou relation Supabase
- [ ] **Section 6 (API/Edge Functions)** -- si ajout/modification d'une Edge Function ou integration tierce
- [ ] **Section 7 (Custom Code)** -- si ajout/modification de provider, service, model, widget
- [ ] **Section 8 (Auth)** -- si modification de l'authentification Firebase ou des regles de securite
- [ ] **Section 10 (Deploiement)** -- si modification du process de build ou des variables d'environnement

### Mise a jour architecture_mindmap.mermaid

- [ ] Mise a jour si changement structurel (nouvel ecran, nouvelle table, nouvelle integration)

### Supabase RLS Rules

- [ ] Regles RLS mises a jour si nouvelle table ou nouvelles permissions
- [ ] Tester avec un user non proprietaire (acces refuse attendu)
- [ ] Tester avec le proprietaire (acces autorise attendu)
- [ ] Migration SQL appliquee si modification de schema

### Edge Functions

- [ ] Code de la fonction mis a jour dans `supabase/functions/`
- [ ] `supabase functions deploy <nom-fonction> --project-ref osbcejhzxxpdtvbdwaaw` execute
- [ ] Variables d'environnement configurees (`supabase secrets set`)
- [ ] Fonctions concernees : `scan-shelf`, `enrich-book`, `sync-user`

### Flutter

- [ ] `flutter analyze` sans erreurs
- [ ] `flutter build apk --release` teste si changements impactants
- [ ] Permissions Android (`AndroidManifest.xml`) mises a jour si nouveau plugin

### Changelog

- [ ] Entree ajoutee dans **Section 11** de `ARCHITECTURE.md` :

```
| YYYY-MM-DD | X.Y.Z | Description des changements | Auteur |
```

- [ ] Version incrementee dans `pubspec.yaml` si release

---

## Tests a effectuer

### Fonctionnalites core

- [ ] Authentification (Google / Apple / Phone OTP / Anonymous / deconnexion)
- [ ] Scan etagere (camera, envoi Claude Vision, resultats, ajout livres)
- [ ] Bibliotheque (liste livres, detail, modification, suppression)
- [ ] Social (amis, recherche, demandes, acceptation/refus)
- [ ] Profil (affichage stats, modification, photo)

### Si modif du module Prets

- [ ] Creation d'un pret (selection livre, ami, date)
- [ ] Changement de statut (en cours, rendu, en retard)
- [ ] Historique des prets

### Si modif du module Recommandations

- [ ] Envoi recommandation a un ami
- [ ] Reception et affichage recommandation
- [ ] Changement de statut (lue, acceptee)

### Si modif Supabase RLS

- [ ] Tester avec un user non proprietaire (acces refuse attendu)
- [ ] Tester avec le proprietaire (acces autorise attendu)
- [ ] Tester les operations CRUD sur chaque table modifiee

---

## Git

- [ ] Commit avec message Conventional Commits :
  - `feat:` nouvelle fonctionnalite
  - `fix:` correction de bug
  - `refactor:` refactoring sans changement de comportement
  - `docs:` documentation uniquement
  - `chore:` maintenance (dependances, config)
- [ ] Push de la branche
- [ ] PR creee (si travail en equipe)

---

## Checklist rapide (modifications mineures)

Pour les petits fixes (typo, style, correction mineure) :

- [ ] `flutter analyze` OK
- [ ] Commit avec message descriptif
- [ ] Entree changelog si correctif notable

---

## Reference rapide -- Fichiers cles

| Ce que tu modifies | Fichiers a toucher |
|---|---|
| Nouvel ecran | `lib/features/<module>/screens/` + `lib/core/router/app_router.dart` |
| Nouvelle table Supabase | `lib/shared/models/` + `lib/core/services/supabase_service.dart` + migration SQL |
| Nouveau provider | `lib/features/<module>/providers/` + `lib/main.dart` (MultiProvider) |
| Nouvelle Edge Function | `supabase/functions/<nom>/index.ts` + deploy |
| Nouveau service | `lib/features/<module>/services/` ou `lib/core/services/` |
| Nouveau model | `lib/shared/models/<nom>_model.dart` |
| Modification design | `lib/core/theme/app_colors.dart` + `lib/core/theme/app_theme.dart` |
| Nouvelle permission Android | `android/app/src/main/AndroidManifest.xml` |
| Nouvelle permission iOS | `ios/Runner/Info.plist` |
| Configuration Firebase | `lib/firebase_options.dart` + `android/app/google-services.json` |
| Configuration Supabase | `lib/core/services/supabase_service.dart` + `lib/core/constants/app_constants.dart` |
