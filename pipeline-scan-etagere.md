# 📷→📚 BiblioShare — Pipeline Scan d'Étagère
## De la photo brute à la liste de livres intégrée en base

---

## 🎯 VUE D'ENSEMBLE DU PIPELINE

```
PHOTO               ANALYSE IA           ENRICHISSEMENT         VALIDATION          INTÉGRATION
─────               ──────────           ──────────────         ──────────          ───────────

📱 Capture    →    🤖 Claude Vision   →   📖 Google Books    →   👤 L'utilisateur  →  🗄️ Supabase
   photo              analyse la            + Open Library        confirme/corrige      INSERT
   étagère            photo et              complètent            chaque livre          en base
                      retourne JSON         les fiches

  ~2 sec            ~5-10 sec             ~2-5 sec              manuel               ~1 sec
                                          (parallèle)
```

**Temps total automatique : ~10-15 secondes** pour une étagère de 30 livres.
L'utilisateur ne voit que l'étape de validation.

---

## ÉTAPE 1 : 📱 CAPTURE DE LA PHOTO

### Ce qui se passe côté app (FlutterFlow + Custom Widget Dart)

```
L'UTILISATEUR :
1. Appuie sur "Scanner une étagère"
2. La caméra s'ouvre avec un overlay guide
3. Il cadre son étagère et prend la photo
4. (optionnel) Il prend plusieurs photos si grande étagère

CE QUE L'APP FAIT EN COULISSE :
1. Custom Widget Dart → ouvre la caméra avec overlay
2. Photo prise en haute résolution (min 1920px de large)
3. Vérification qualité :
   - Luminosité suffisante ? (histogramme basique)
   - Flou détecté ? (Laplacian variance)
   - Si mauvaise qualité → "Reprends la photo, c'est flou/sombre"
4. Compression intelligente :
   - Resize à 2048px max (assez pour l'OCR, pas trop lourd)
   - JPEG qualité 85% → ~500 Ko - 1.5 Mo
5. Upload vers Supabase Storage : /scans/{userId}/{timestamp}.jpg
6. Récupération de l'URL publique signée (expire en 1h)
7. Appel de l'Edge Function "scan-shelf" avec cette URL
```

### Gestion multi-photos (grande étagère)

```
Si l'étagère est trop large pour une seule photo :

OPTION A — MULTI-SHOT (recommandé)
  → L'utilisateur prend 2-3 photos en se décalant
  → Chaque photo est analysée séparément par Claude
  → Les résultats sont fusionnés côté serveur
  → Dédoublonnage par ISBN ou titre+auteur

OPTION B — PHOTO UNIQUE LARGE
  → L'utilisateur prend du recul pour tout capturer
  → Moins précis pour l'OCR (tranches plus petites)
  → Claude gère quand même, mais avec des scores de confiance plus bas

OPTION C — ÉTAGÈRE PAR ÉTAGÈRE
  → L'utilisateur prend une photo par rangée
  → Meilleure précision
  → Plus de photos mais résultats plus fiables
```

---

## ÉTAPE 2 : 🤖 ANALYSE PAR CLAUDE VISION API

### L'Edge Function `scan-shelf`

```typescript
// Supabase Edge Function : scan-shelf
// Reçoit l'URL de la photo, appelle Claude Vision, retourne la liste

import { serve } from "https://deno.land/std/http/server.ts";
import Anthropic from "npm:@anthropic-ai/sdk";

serve(async (req) => {
  const { imageUrl, userId, scanId } = await req.json();

  const anthropic = new Anthropic();

  // Télécharger l'image et la convertir en base64
  const imageResponse = await fetch(imageUrl);
  const imageBuffer = await imageResponse.arrayBuffer();
  const base64Image = btoa(String.fromCharCode(...new Uint8Array(imageBuffer)));

  // Appel Claude Vision avec le prompt structuré
  const response = await anthropic.messages.create({
    model: "claude-sonnet-4-5-20250929",
    max_tokens: 4096,
    messages: [
      {
        role: "user",
        content: [
          {
            type: "image",
            source: {
              type: "base64",
              media_type: "image/jpeg",
              data: base64Image,
            },
          },
          {
            type: "text",
            text: SHELF_ANALYSIS_PROMPT,  // voir ci-dessous
          },
        ],
      },
    ],
  });

  // Parser le JSON retourné par Claude
  const analysisText = response.content[0].text;
  const analysis = JSON.parse(
    analysisText.replace(/```json\n?/g, "").replace(/```\n?/g, "")
  );

  // Sauvegarder le résultat brut en base
  // (pour debug, historique, et amélioration future)
  await supabase.from("scan_results").insert({
    id: scanId,
    user_id: userId,
    image_url: imageUrl,
    raw_analysis: analysis,
    book_count: analysis.stats.total_livres,
    created_at: new Date().toISOString(),
  });

  return new Response(JSON.stringify(analysis), {
    headers: { "Content-Type": "application/json" },
  });
});
```

### Le prompt envoyé à Claude Vision (la clé de tout)

```
C'est LE prompt critique. Sa qualité détermine la qualité de la détection.

PROMPT :
"""
Tu es un expert en identification de livres. Analyse cette photo d'étagère.

INSTRUCTIONS PRÉCISES :

1. Identifie CHAQUE livre visible sur la photo, même partiellement.
   Parcours de GAUCHE À DROITE, étagère par étagère de HAUT EN BAS.

2. Pour chaque livre, extrais :
   - titre : le titre exact lu sur la tranche (ou ta meilleure estimation)
   - auteur : l'auteur si lisible sur la tranche
   - editeur : l'éditeur ou la collection si reconnaissable
     (Folio, Poche, Gallimard, Penguin, Points, Le Livre de Poche, J'ai Lu, etc.)
   - confiance : un score de 0 à 100 indiquant ta certitude
   - statut : "COMPLET" si tu es sûr, "PARTIEL" si partiellement lisible,
     "ILLISIBLE" si tu ne peux rien lire
   - apparence : couleur de la tranche, taille estimée (poche/moyen/grand),
     épaisseur approximative
   - candidats : si confiance < 80%, propose 2-3 titres alternatifs possibles

3. INDICES CONTEXTUELS à utiliser :
   - Les logos d'éditeurs sont très distinctifs (Gallimard = fond crème,
     Folio = bande colorée en bas, Penguin = orange...)
   - Les livres d'une même collection ont le même design
   - La taille et l'épaisseur donnent des indices sur le livre
   - Les livres voisins peuvent donner un contexte (même auteur, même thème)

4. Retourne UNIQUEMENT un objet JSON valide, sans commentaire ni markdown.
   Pas de ```json, juste le JSON brut.

STRUCTURE JSON ATTENDUE :
{
  "etageres": [
    {
      "numero": 1,
      "livres": [
        {
          "position": 1,
          "titre": "L'Étranger",
          "auteur": "Albert Camus",
          "editeur": "Folio",
          "confiance": 95,
          "statut": "COMPLET",
          "apparence": {
            "couleur_tranche": "blanc cassé avec bande verte",
            "taille": "poche",
            "epaisseur_estimee": "fin"
          },
          "candidats": []
        }
      ]
    }
  ],
  "stats": {
    "total_livres": 0,
    "complets": 0,
    "partiels": 0,
    "illisibles": 0
  }
}
"""
```

### Ce que Claude retourne concrètement

```json
{
  "etageres": [
    {
      "numero": 1,
      "livres": [
        {
          "position": 1,
          "titre": "L'Étranger",
          "auteur": "Albert Camus",
          "editeur": "Folio",
          "confiance": 95,
          "statut": "COMPLET",
          "apparence": {
            "couleur_tranche": "blanc cassé avec bande verte",
            "taille": "poche",
            "epaisseur_estimee": "fin"
          },
          "candidats": []
        },
        {
          "position": 2,
          "titre": "La Peste",
          "auteur": "Albert Camus",
          "editeur": "Folio",
          "confiance": 90,
          "statut": "COMPLET",
          "apparence": {
            "couleur_tranche": "blanc cassé avec bande orange",
            "taille": "poche",
            "epaisseur_estimee": "moyen"
          },
          "candidats": []
        },
        {
          "position": 3,
          "titre": null,
          "auteur": null,
          "editeur": "Folio",
          "confiance": 20,
          "statut": "ILLISIBLE",
          "apparence": {
            "couleur_tranche": "blanc cassé avec bande bleue",
            "taille": "poche",
            "epaisseur_estimee": "fin"
          },
          "candidats": [
            "La Chute — Albert Camus",
            "L'Exil et le Royaume — Albert Camus",
            "Noces — Albert Camus"
          ]
        }
      ]
    },
    {
      "numero": 2,
      "livres": [
        {
          "position": 1,
          "titre": "Dune",
          "auteur": "Frank Herbert",
          "editeur": "Pocket",
          "confiance": 85,
          "statut": "COMPLET",
          "apparence": {
            "couleur_tranche": "bleu foncé",
            "taille": "poche",
            "epaisseur_estimee": "épais"
          },
          "candidats": []
        }
      ]
    }
  ],
  "stats": {
    "total_livres": 4,
    "complets": 3,
    "partiels": 0,
    "illisibles": 1
  }
}
```

---

## ÉTAPE 3 : 📖 ENRICHISSEMENT WEB AUTOMATIQUE

### L'Edge Function `enrich-books`

```
DÉCLENCHÉE : automatiquement après le scan, pour CHAQUE livre
avec confiance >= 50%.

STRATÉGIE DE RECHERCHE EN CASCADE :

Pour chaque livre détecté par Claude :

  ┌─────────────────────────────────────────────────┐
  │ ENTRÉE : { titre: "L'Étranger", auteur: "Albert│
  │ Camus", editeur: "Folio", confiance: 95 }      │
  └────────────────────┬────────────────────────────┘
                       ▼
  ┌─────────────────────────────────────────────────┐
  │ 1. GOOGLE BOOKS API                             │
  │    GET /volumes?q=intitle:L'Étranger+inauthor:  │
  │    Camus&langRestrict=fr                        │
  │                                                  │
  │    → Retourne : ISBN, description, pages,        │
  │      couverture, catégories, note, editeur       │
  │                                                  │
  │    Si résultat trouvé avec score de match > 80%  │
  │    → ENRICHI ✅ passer au livre suivant           │
  │    Si pas de résultat ou match faible             │
  │    → continuer en cascade ↓                      │
  └────────────────────┬────────────────────────────┘
                       ▼
  ┌─────────────────────────────────────────────────┐
  │ 2. OPEN LIBRARY API                             │
  │    GET /search.json?title=L'Étranger&author=    │
  │    Camus                                         │
  │                                                  │
  │    → Retourne : ISBN, nb pages, éditeurs,        │
  │      première publication, sujets, couverture    │
  │                                                  │
  │    Croiser avec le résultat Google Books         │
  │    pour confirmer / compléter                    │
  └────────────────────┬────────────────────────────┘
                       ▼
  ┌─────────────────────────────────────────────────┐
  │ 3. LOGIQUE DE MATCHING D'ÉDITION                │
  │                                                  │
  │    Problème : Google Books retourne souvent      │
  │    plusieurs éditions du même livre.             │
  │    Laquelle est celle sur l'étagère ?            │
  │                                                  │
  │    CRITÈRES DE SÉLECTION :                       │
  │    a) L'éditeur correspond ? (Folio = Gallimard) │
  │       → Score +30                                │
  │    b) Le format correspond ? (poche ↔ poche)     │
  │       → Score +20                                │
  │    c) Le nombre de pages colle avec l'épaisseur? │
  │       → Score +15                                │
  │    d) La couverture ressemble ? (couleur tranche)│
  │       → Score +10                                │
  │    e) La langue correspond ?                     │
  │       → Score +25                                │
  │                                                  │
  │    → Prendre l'édition avec le score le + élevé  │
  └─────────────────────────────────────────────────┘
```

### Parallélisation pour la performance

```
IMPORTANT : On n'attend pas livre par livre.

30 livres détectés → 30 enrichissements lancés en PARALLÈLE :

  Promise.allSettled([
    enrichBook(livre1),    // ← ~2 sec
    enrichBook(livre2),    // ← ~2 sec
    enrichBook(livre3),    // ← ~2 sec
    ...                    // tous en même temps
    enrichBook(livre30),   // ← ~2 sec
  ])

  Temps total : ~3-5 secondes pour 30 livres
  (pas 30 x 2 sec = 60 sec !)

  Google Books API : 1000 req/jour gratuit, largement suffisant.
  Open Library API : pas de limite.
```

### Structure de la fiche enrichie

```json
{
  "scan_position": { "etagere": 1, "position": 1 },
  "scan_confidence": 95,
  "scan_raw": {
    "titre": "L'Étranger",
    "auteur": "Albert Camus",
    "editeur": "Folio"
  },
  "enriched": {
    "isbn_13": "9782070360024",
    "isbn_10": "2070360024",
    "title": "L'Étranger",
    "authors": [{ "name": "Albert Camus", "role": "author" }],
    "publisher": "Gallimard",
    "collection": "Folio",
    "publication_date": "1971-11-15",
    "first_published": "1942-06-15",
    "language": "fr",
    "page_count": 186,
    "description": "« Aujourd'hui, maman est morte... »",
    "genres": ["Roman", "Littérature française", "Classique"],
    "cover_url": "https://books.google.com/...thumbnail.jpg",
    "goodreads_rating": 3.98,
    "match_edition_score": 92
  },
  "enrichment_sources": ["google_books", "open_library"],
  "enrichment_status": "complete"
}
```

---

## ÉTAPE 4 : 👤 VALIDATION PAR L'UTILISATEUR

### L'écran de validation (FlutterFlow)

```
C'est l'étape clé. L'utilisateur voit TOUS les livres détectés
et peut confirmer, corriger ou supprimer.

L'app affiche la liste triée par CONFIANCE (les problèmes en haut) :

ÉTAT DE L'ÉCRAN :
┌─────────────────────────────────────────────────────────┐
│  📷 Scan du 15/03/2025 — 28 livres détectés             │
│  ✅ 24 identifiés · ⚠️ 3 incertains · ❌ 1 illisible    │
│                                                          │
│  ─── ⚠️ À VÉRIFIER ───                                  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │ ❌ Livre #7 — ILLISIBLE (confiance: 20%)         │   │
│  │ 📷 [miniature tranche]  Tranche bleue, poche     │   │
│  │ Suggestions :                                     │   │
│  │  ○ La Chute — A. Camus                           │   │
│  │  ○ L'Exil et le Royaume — A. Camus               │   │
│  │  ○ Noces — A. Camus                              │   │
│  │ [Choisir une suggestion] [Saisir manuellement]    │   │
│  │ [📷 Scanner le code-barre] [🗑️ Ignorer]           │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │ ⚠️ "Le Petit Prince" — confiance: 65%            │   │
│  │ 📷 [tranche]  │  📕 [couverture trouvée]         │   │
│  │ Saint-Exupéry · Folio · 120 pages                 │   │
│  │ [✅ Confirmer] [✏️ Corriger] [📷 Code-barre]      │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ─── ✅ IDENTIFIÉS ───                                   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │ ✅ "L'Étranger" — Albert Camus — 95%             │   │
│  │ 📕 Folio, Gallimard · 186 pages · ISBN 978207... │   │
│  │ [✅ OK] [✏️ Corriger]                              │   │
│  └──────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │ ✅ "La Peste" — Albert Camus — 90%               │   │
│  │ 📕 Folio, Gallimard · 352 pages · ISBN 978207... │   │
│  │ [✅ OK] [✏️ Corriger]                              │   │
│  └──────────────────────────────────────────────────┘   │
│  ... (24 autres livres)                                  │
│                                                          │
│  ─── ACTIONS ───                                         │
│  [✅ Tout confirmer (24)] [➕ Ajouter un livre manqué]   │
│  [📷 Rescanner] [💾 Sauvegarder]                         │
└─────────────────────────────────────────────────────────┘

INTERACTIONS :
  - "Tout confirmer" → confirme d'un coup tous les livres à 80%+
  - Tap sur un livre ✅ → fiche détaillée avec infos enrichies
  - "Corriger" → champ de saisie titre/auteur → relance l'enrichissement
  - "Scanner le code-barre" → ouvre ML Kit barcode → ISBN → enrichissement direct
  - "Ajouter un livre manqué" → saisie manuelle ou scan ISBN
  - "Ignorer" → ne pas ajouter ce livre
  - Swipe gauche → supprimer de la liste
```

### Fallback : scan de code-barre ISBN

```
QUAND L'IA NE TROUVE PAS :
Le code-barre est la solution infaillible.

Flow :
1. L'utilisateur tape "Scanner le code-barre" sur un livre illisible
2. Custom Action Dart → ouvre google_mlkit_barcode_scanning
3. L'utilisateur scanne le code-barre au dos du livre
4. ML Kit retourne : "9782070360024" (ISBN-13)
5. Appel direct Google Books API avec l'ISBN → match parfait
6. La fiche livre est remplie → retour à l'écran de validation

AVANTAGE :
  - Fonctionne hors-ligne (ML Kit est on-device)
  - 100% de précision (ISBN = identifiant unique mondial)
  - 1 seconde pour scanner
  - Fallback parfait pour les 5-10% de livres mal détectés
```

---

## ÉTAPE 5 : 🗄️ INTÉGRATION EN BASE DE DONNÉES

### Ce qui se passe quand l'utilisateur confirme

```
BOUTON "Sauvegarder" ou "Tout confirmer" :

POUR CHAQUE LIVRE CONFIRMÉ :

1. VÉRIFIER LE DOUBLON
   → SELECT id FROM books
     WHERE user_id = '{userId}'
     AND (isbn_13 = '{isbn}' OR (title ILIKE '{titre}' AND authors->0->>'name' ILIKE '{auteur}'))
   → Si trouvé : "Tu as déjà ce livre ! Ignorer ou mettre à jour ?"

2. INSÉRER LE LIVRE EN BASE
   → INSERT INTO books (
       user_id, isbn_13, isbn_10, title, original_title,
       authors, publisher, collection, publication_date, language,
       page_count, format, description, genres, themes,
       cover_url, goodreads_rating, babelio_rating,
       condition, date_added,
       scan_confidence, scan_photo_url, shelf_position
     ) VALUES (...)
     RETURNING id;

3. TÉLÉCHARGER ET STOCKER LA COUVERTURE
   → Fetch l'image de couverture depuis Google Books
   → Upload dans Supabase Storage : /covers/{isbn_13}.jpg
   → UPDATE books SET cover_url = '{url_locale}' WHERE id = '{bookId}'
   → (pour ne pas dépendre de l'URL Google Books à long terme)

4. CRÉER L'ENTRÉE DE REVIEW VIDE
   → INSERT INTO reviews (user_id, book_id, reading_status)
     VALUES ('{userId}', '{bookId}', 'unread')
   → Le livre est ajouté comme "non lu" par défaut

5. METTRE À JOUR LES STATS
   → UPDATE mv_user_stats (via trigger ou refresh de la vue matérialisée)
   → Le compteur "total_books" de l'utilisateur augmente

6. PUBLIER DANS LE FIL SOCIAL
   → INSERT INTO social_feed (user_id, action_type, metadata)
     VALUES ('{userId}', 'scan_shelf', {
       book_count: 28,
       scan_id: '{scanId}',
       sample_titles: ["L'Étranger", "La Peste", "Dune"]
     })
   → Les amis voient : "Sophie a scanné une étagère (+28 livres)"

7. VÉRIFIER LES MATCHS SOCIAUX
   → Edge Function "check-social-matches" :
     - Ce livre est sur la wishlist d'un ami ?
       → Notification : "Sophie a [Livre] que tu voulais !"
     - Un ami a le même livre et l'a adoré ?
       → Donnée stockée pour future recommandation
```

### Le batch INSERT (performance)

```sql
-- On n'insère pas livre par livre.
-- On fait un batch INSERT pour les 28 livres d'un coup :

INSERT INTO books (user_id, isbn_13, title, authors, publisher, ...)
VALUES
  ('{userId}', '9782070360024', 'L''Étranger', '[{"name":"Albert Camus"}]', 'Gallimard', ...),
  ('{userId}', '9782070360741', 'La Peste', '[{"name":"Albert Camus"}]', 'Gallimard', ...),
  ('{userId}', '9782266320481', 'Dune', '[{"name":"Frank Herbert"}]', 'Pocket', ...),
  ... (25 autres)
RETURNING id, isbn_13, title;

-- 1 seule requête SQL pour 28 livres = rapide
-- Supabase gère ça en ~100ms

-- Puis batch INSERT des reviews :
INSERT INTO reviews (user_id, book_id, reading_status)
SELECT '{userId}', id, 'unread' FROM books
WHERE user_id = '{userId}' AND id = ANY('{bookIds}');
```

---

## 🔄 SCHÉMA COMPLET DU FLUX DE DONNÉES

```
                         ÉTAPE 1                    ÉTAPE 2
                         CAPTURE                    ANALYSE IA
                         ───────                    ──────────
  📱 Utilisateur          Supabase                  Edge Function
  prend la photo    →    Storage                →   scan-shelf
                         /scans/{uid}/              │
                         {timestamp}.jpg            │ Appel Claude
                                                    │ Vision API
                                                    ▼
                                              JSON structuré
                                              {etageres: [{livres: [...]}]}
                                                    │
                         ÉTAPE 3                    │
                         ENRICHISSEMENT             │
                         ──────────────             ▼
                         Edge Function         Pour chaque livre :
                         enrich-books    ←───  confiance >= 50%
                         │
                         ├─→ Google Books API (titre + auteur)
                         ├─→ Open Library API (compléments)
                         └─→ Matching d'édition (éditeur, format)
                              │
                              ▼
                         Fiches enrichies
                         {isbn, description, couverture, genres, ...}
                              │
                         ÉTAPE 4                    │
                         VALIDATION                 │
                         ──────────                 ▼
                         FlutterFlow          Écran de validation
                         Page                 avec tous les livres
                         "ScanValidation"     classés par confiance
                              │
                              │ L'utilisateur confirme,
                              │ corrige, ou scanne des
                              │ codes-barres pour les
                              │ livres mal identifiés
                              │
                              ▼
                         ÉTAPE 5
                         INTÉGRATION
                         ───────────
                         Supabase              Batch INSERT
                         PostgreSQL       →    books (28 lignes)
                                          →    reviews (28 lignes)
                                          →    social_feed (1 ligne)
                                          →    Refresh mv_user_stats
                                          →    Check wishlist matches
                                          →    Download covers → Storage

                         RÉSULTAT : 28 livres dans la bibliothèque 📚
```

---

## 🛡️ GESTION DES CAS LIMITES

```
CAS 1 — Photo de mauvaise qualité
  → Détection côté app AVANT d'envoyer
  → Si envoyée quand même : Claude retourne beaucoup de "ILLISIBLE"
  → L'app propose de reprendre la photo

CAS 2 — Livres dans une langue non-latine (arabe, japonais, russe...)
  → Claude Vision lit les alphabets non-latins
  → L'enrichissement Google Books supporte toutes les langues
  → Le paramètre search_languages de l'utilisateur aide à filtrer

CAS 3 — Livres empilés horizontalement
  → Claude les détecte et les traite normalement
  → La position est notée comme "empilé" au lieu d'un numéro

CAS 4 — Objets non-livres sur l'étagère (déco, cadres, plantes)
  → Claude les ignore naturellement (il cherche des livres)
  → Si confusion : confiance très basse → filtré automatiquement

CAS 5 — Même livre en double
  → Détection au moment de l'INSERT (vérif ISBN ou titre+auteur)
  → Proposer : "Tu as déjà ce livre. Doublon ou 2ème exemplaire ?"

CAS 6 — Livre très rare / auto-édité / pas dans les APIs
  → Enrichissement échoue → statut "enrichment_partial"
  → L'utilisateur remplit manuellement les infos manquantes
  → Ou scanne le code-barre pour tenter avec l'ISBN

CAS 7 — Timeout ou erreur API
  → Retry automatique (3 tentatives avec backoff exponentiel)
  → Si échec total : les livres sont quand même créés avec les
    données du scan (titre + auteur de Claude), sans enrichissement
  → L'enrichissement est relancé en arrière-plan plus tard
  → Notification : "3 livres n'ont pas pu être enrichis, on réessaie"

CAS 8 — Très grande bibliothèque (100+ livres)
  → Encourager le scan par étagère / section
  → Rate limiting Google Books : 1000 req/jour
  → Si atteint : queue les enrichissements pour le lendemain
  → L'utilisateur peut utiliser sa bibliothèque en attendant
```

---

## 💡 OPTIMISATIONS FUTURES

```
V2 — APPRENTISSAGE :
  → Stocker les corrections de l'utilisateur
  → Si un livre est souvent mal détecté par Claude,
    enrichir le prompt avec des exemples
  → Taux de correction par éditeur/collection pour adapter la confiance

V2 — CACHE D'ENRICHISSEMENT :
  → Si un ami a déjà le même ISBN en base → copier ses données enrichies
  → Pas besoin de re-appeler Google Books pour un livre déjà connu
  → Table "book_metadata" partagée (ISBN → données, indépendant du user)

V2 — SCAN CONTINU :
  → Mode vidéo : pointer la caméra et scanner en temps réel
  → Chaque livre détecté s'ajoute au fur et à mesure
  → Plus besoin de prendre une photo puis attendre
```
