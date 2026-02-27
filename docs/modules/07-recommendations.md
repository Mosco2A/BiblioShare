# Module 7 : Recommandations Actives

## Flow de recommandation

1. L'utilisateur choisit un livre a recommander
2. Selectionne un ami dans sa liste
3. Ecrit un message personnalise (optionnel)
4. Peut proposer le pret en meme temps (toggle)
5. Envoie la recommandation (notification in-app)

## Cote destinataire

Le destinataire recoit une notification avec :
- Couverture + infos du livre
- Note de l'envoyeur
- Message personnalise
- Actions : Ajouter a la wishlist, Emprunter, Merci, Pas mon style

## Statuts de recommandation

`sent` → `seen` → `wishlisted` / `borrowed` → `reading` → `finished`
Alternative : `declined_politely` (invisible pour l'envoyeur) / `expired` (60j)

## Fichiers

| Fichier | Role |
|---------|------|
| `lib/shared/models/recommendation_model.dart` | Modele + RecoStatus enum |
| `lib/features/social/services/recommendation_service.dart` | CRUD recos |
| `lib/features/social/screens/recommend_screen.dart` | Ecran envoi reco |
