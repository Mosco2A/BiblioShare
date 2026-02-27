# Module 4 : Enrichissement Web & Detail livre

## Fiche livre enrichie

Chaque livre dans BiblioShare contient des metadonnees completes :

### Identification
ISBN-10/13, titre, sous-titre, auteurs (JSONB), traducteurs, editeur, collection, langue

### Details physiques
Nombre de pages, format (poche/broche/relie), dimensions

### Contenu
Resume, genres, themes, mots-cles, public cible, serie/tome

### Communaute
Notes Goodreads et Babelio, tags populaires

### Medias
URL couverture, miniature

### Meta scan
Date scan, confiance identification, position etagere

## Ecran detail livre

`BookDetailScreen` — ecran complet avec :
- `SliverAppBar` avec couverture en Hero animation
- Titre, sous-titre, auteurs
- Chips d'info rapide (pages, editeur, format, ISBN)
- Boutons action : Noter/Avis + Preter
- Notes communautaires Goodreads/Babelio
- Synopsis
- Genres en chips
- Tableau d'informations detaillees
- Menu contextuel : Modifier, Preter, Recommander, Supprimer

## Fichiers

| Fichier | Role |
|---------|------|
| `lib/features/library/screens/book_detail_screen.dart` | Ecran detail |
| `lib/features/library/services/book_service.dart` | CRUD livres Supabase |
| `lib/features/library/providers/library_provider.dart` | State management |
| `lib/shared/models/book_model.dart` | Modele de donnees |
