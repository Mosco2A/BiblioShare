# Module 6 : Bibliotheque Sociale & Invitations

## Systeme d'amis

### Demandes d'amis
- Envoi de demande → statut `pending`
- Le receveur peut accepter ou refuser
- Acceptation → statut `accepted`, amitie bidirectionnelle

### Recherche d'utilisateurs
- Par nom d'affichage ou @username (ilike)
- Resultats avec avatar, nom, username
- Indicateurs : "Toi", "Deja ami", bouton "Ajouter"

### Tags de groupe
Chaque amitie peut avoir des tags : "famille", "club-lecture", "collegues"

## Invitations

Methodes supportees :
1. Lien de partage (share_plus)
2. SMS (url_launcher)
3. Email
4. QR code

Tracking : invitations envoyees, cliquees, converties.

## Fil d'activite social

Table `social_feed` avec actions :
`added_book`, `finished_book`, `rated_book`, `lent_book`, `returned_book`, `scan_shelf`, `joined_group`, `added_to_wishlist`, `invited_friend`, `friend_joined`

## Fichiers

| Fichier | Role |
|---------|------|
| `lib/shared/models/friendship_model.dart` | Modele + FriendshipStatus enum |
| `lib/features/social/services/social_service.dart` | CRUD amis, invitations, feed |
| `lib/features/social/providers/social_provider.dart` | State management social |
| `lib/features/social/screens/friends_screen.dart` | Liste d'amis + demandes |
| `lib/features/social/screens/friend_search_screen.dart` | Recherche + ajout |
