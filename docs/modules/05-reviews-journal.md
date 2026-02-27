# Module 5 : Avis & Journal de lecture

## Systeme de notation

### Note globale
Etoiles interactives 1-5 (demi-etoiles supportees) avec label contextuel :
- >= 4.5 : "Coup de coeur !"
- >= 4 : "Excellent"
- >= 3 : "Bien"
- >= 2 : "Moyen"
- < 2 : "Decevant"

### Notes detaillees (optionnelles, toggle)
6 criteres avec etoiles individuelles :
- Histoire / Intrigue
- Style d'ecriture
- Profondeur / Reflexion
- Emotion / Attachement
- Rythme / Page-turner
- Originalite

### Avis texte
Zone de texte libre (max 2000 car.)

### Tags
Tags predefinis suggerés + tags personnalises :
`coup-de-coeur`, `fait-reflechir`, `page-turner`, `a-relire`, `offrir-absolument`, `decevant`, `classique`, `feel-good`

### Notes privees
Zone separee, toujours privee (citations, pages, reflexions)

### Visibilite
SegmentedButton : Prive / Amis / Public

## Progression de lecture

- `ReadingProgressCard` : widget compact avec barre de progression
- `UpdatePageDialog` : dialog rapide pour mettre a jour la page en cours (slider + input)
- Statuts : `unread` → `reading` → `finished` / `abandoned`

## Fichiers

| Fichier | Role |
|---------|------|
| `lib/shared/models/review_model.dart` | Modele ReviewModel + ReadingStatus enum |
| `lib/features/library/services/review_service.dart` | CRUD reviews (upsert) |
| `lib/features/library/providers/review_provider.dart` | Cache + state |
| `lib/features/library/screens/review_screen.dart` | Ecran notation complet |
| `lib/features/library/widgets/reading_progress_card.dart` | Widget progression |

## Table Supabase

`reviews` avec contrainte unique `(user_id, book_id)` — upsert automatique.
