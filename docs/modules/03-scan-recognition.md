# Module 3 : Scan & Reconnaissance

## Pipeline de scan

```
Photo etagere → Claude Vision API → Detection livres → Enrichissement → Validation → Insert DB
```

### Etape 1 : Capture
- Camera ou galerie via `image_picker`
- Compression a 1920px max, qualite 85%

### Etape 2 : Analyse Claude Vision
- Edge Function `scan-shelf` envoie l'image base64 a Claude Sonnet
- Prompt structure demande : titre, auteur, editeur, confiance (0-100), statut (identifie/partiel/illisible)
- Retour JSON structure avec `etageres[]` et `livres[]`

### Etape 3 : Enrichissement
- Edge Function `enrich-book` cherche en parallele Google Books + Open Library
- Algorithme de scoring des editions (titre +40, auteur +30, editeur +20 avec alias, langue +10)
- Merge des deux sources (Google Books prioritaire, Open Library complement)

### Etape 4 : Validation utilisateur
- `ScanResultsScreen` affiche les livres detectes avec badge de confiance
- Actions : Confirmer / Rejeter / Corriger manuellement
- "Tout confirmer" pour les livres haute confiance (>= 80%)

### Etape 5 : Insert base de donnees
- Conversion `DetectedBook` → `BookModel`
- Batch insert via `BookService.addBooks()`

## Fichiers

| Fichier | Role |
|---------|------|
| `lib/features/scan/services/scan_service.dart` | Appel Edge Functions |
| `lib/features/scan/providers/scan_provider.dart` | Machine a etats (idle→scanning→enriching→results) |
| `lib/features/scan/screens/scan_screen.dart` | UI camera/galerie |
| `lib/features/scan/screens/scan_results_screen.dart` | Validation resultats |
| `lib/shared/models/scan_result_model.dart` | Modeles DetectedBook, ScanResult |
| `lib/shared/models/book_model.dart` | Modele livre complet |
| `supabase/functions/scan-shelf/index.ts` | Edge Function Claude Vision |
| `supabase/functions/enrich-book/index.ts` | Edge Function enrichissement |
