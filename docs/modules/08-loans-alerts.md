# Module 8 : Gestion des Prets & Alertes

## Cycle de vie d'un pret

```
requested → accepted → active → return_pending → returned
                     → overdue → return_pending → returned
                     → extension_requested → active (prolonge)
                                           → overdue (refuse)
requested → cancelled (refuse)
active → disputed (litige)
```

## Initiation du pret

### Scenario A — Le proprietaire prete
- Depuis la fiche livre : bouton "Preter"
- Selectionne un ami
- Choisit la date de retour (raccourcis : 2 sem, 1/2/3 mois)
- Notes optionnelles

### Scenario B — L'ami demande
- Depuis la bibliotheque d'un ami : bouton "Emprunter"
- Notification au proprietaire → Accepter/Refuser

## Dashboard prets

`LoansScreen` avec 2 onglets :
- **Pretes** : livres que j'ai pretes (en tant que proprietaire)
- **Empruntes** : livres que j'ai empruntes

Chaque pret affiche :
- Statut avec code couleur et icone
- Jours restants / en retard
- Actions contextuelles selon le statut et le role

## Alertes (prevues)

Escalade automatique :
- J-7 : rappel doux emprunteur
- J-3 : rappel emprunteur + info proprietaire
- J : rappel urgent
- J+3 : alerte retard aux deux
- J+7 : relance ferme
- J+14 : derniere chance
- J+30 : marque comme litige

## Fichiers

| Fichier | Role |
|---------|------|
| `lib/shared/models/loan_model.dart` | Modele + LoanStatus enum (9 etats) |
| `lib/features/social/services/loan_service.dart` | CRUD prets complet |
| `lib/features/social/providers/loan_provider.dart` | State management |
| `lib/features/social/screens/loans_screen.dart` | Dashboard prets/emprunts |
| `lib/features/social/screens/lend_screen.dart` | Ecran creation pret |
