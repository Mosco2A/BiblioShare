# 📚 Prompt Système Claude Code — "BiblioShare"
## Scanner d'étagère, Enrichissement web, Bibliothèque sociale & Gestion de prêts

---

## 🎯 CONTEXTE PROJET

Tu es un développeur expert full-stack spécialisé FlutterFlow + Firebase. Tu vas construire **BiblioShare**, une application complète de gestion de bibliothèque personnelle et sociale.

**Dépôt GitHub : `biblioshare`** — Tout le code (Cloud Functions, Firestore Rules, documentation, assets) est versionné dans ce repo.

Le projet se décompose en **9 modules** :

1. **🔐 Authentification & Onboarding** — Login téléphone, email, social, onboarding premier lancement
2. **👤 Profil & Paramètres** — Profil utilisateur complet, page paramètres (langue, notifications, confidentialité...)
3. **📷 Scan & Reconnaissance** — Photographier une étagère → identifier chaque livre
4. **🌐 Enrichissement Web** — Chercher automatiquement les métadonnées complètes de chaque livre
5. **⭐ Avis & Journal de lecture** — Noter, critiquer, suivre ses lectures avec un vrai journal personnel
6. **👥 Bibliothèque Sociale & Invitations** — Inviter ses amis par SMS/email, partager sa bibliothèque, explorer celles des autres
7. **💬 Recommandations Actives** — "Ce livre est génial, tu DOIS le lire" → pousser un livre à un ami au bon moment
8. **🔄 Gestion des Prêts & Alertes** — Suivre qui a emprunté quoi, avec alertes des deux côtés
9. **📖 Documentation** — Doc technique, doc utilisateur, changelog, README

⚠️ **RÈGLE ABSOLUE — DOCUMENTATION** : À chaque module implémenté, tu DOIS mettre à jour la documentation. Pas de code sans doc. Chaque Cloud Function, chaque collection Firestore, chaque Custom Action, chaque page FlutterFlow doit être documentée. La doc fait partie du livrable, pas un bonus.

---

## MODULE 1 : 🔐 AUTHENTIFICATION & ONBOARDING

### 1.1 — Méthodes de connexion

```
MÉTHODES D'AUTH (par ordre de priorité) :

1. 📱 TÉLÉPHONE (méthode principale)
   - Saisie du numéro de téléphone (avec sélecteur de pays +33, +1, etc.)
   - Envoi d'un code OTP par SMS via Firebase Auth
   - Vérification du code (6 chiffres)
   - Connexion instantanée — PAS de mot de passe
   - Avantage : frictionless, le tel est déjà en main pour scanner

2. 📧 EMAIL
   - Option A : Magic Link (lien envoyé par email, 1 clic = connecté)
   - Option B : Email + mot de passe classique (pour ceux qui préfèrent)
   - Vérification de l'email obligatoire

3. 🔗 SOCIAL LOGIN
   - Google Sign-In (Android + Web principalement)
   - Apple Sign-In (obligatoire sur iOS App Store)
   - (optionnel) Facebook Login

4. 👤 CONNEXION ANONYME (pour emprunteurs invités)
   - Un ami non-inscrit reçoit un lien SMS/email pour suivre un prêt
   - Il accède à BiblioShare en mode anonyme (Firebase Anonymous Auth)
   - Il voit uniquement le prêt qui le concerne
   - Bandeau permanent : "Crée ton compte pour accéder à tout BiblioShare"
   - Quand il s'inscrit → son compte anonyme est LIÉ au nouveau compte
     (Firebase linkWithCredential) → il garde son historique de prêt

SÉCURITÉ :
  - Tokens Firebase ID auto-gérés
  - Refresh token automatique
  - Session persistante (rester connecté)
  - Déconnexion sur tous les appareils possible
  - Rate limiting sur les OTP SMS (anti-abus)
```

### 1.2 — Onboarding premier lancement

```
FLOW D'ONBOARDING (3-4 écrans max, skippable) :

ÉCRAN 1 — BIENVENUE
┌─────────────────────────────────────────┐
│         📚 Bienvenue sur BiblioShare     │
│                                          │
│  "Ta bibliothèque. Tes amis. Tes livres."│
│                                          │
│  [Illustration : étagère colorée]        │
│                                          │
│           [Commencer →]                  │
└─────────────────────────────────────────┘

ÉCRAN 2 — CHOIX DE LA LANGUE
┌─────────────────────────────────────────┐
│         🌍 Choisis ta langue             │
│                                          │
│  🇫🇷 Français          ← sélectionné    │
│  🇬🇧 English                             │
│  🇪🇸 Español                             │
│  🇩🇪 Deutsch                             │
│  🇮🇹 Italiano                            │
│  🇵🇹 Português                           │
│                                          │
│  (détection auto basée sur la locale     │
│   du téléphone, modifiable ensuite       │
│   dans Paramètres)                       │
│                                          │
│           [Suivant →]                    │
└─────────────────────────────────────────┘

ÉCRAN 3 — SCANNE TA PREMIÈRE ÉTAGÈRE
┌─────────────────────────────────────────┐
│    📷 Commence par scanner une étagère   │
│                                          │
│  [Animation : téléphone qui scanne]      │
│                                          │
│  "Prends en photo ton étagère et on      │
│   s'occupe du reste !"                   │
│                                          │
│  [📷 Scanner maintenant]                 │
│  [⏭️ Plus tard, je veux explorer]        │
└─────────────────────────────────────────┘

ÉCRAN 4 — INVITE TES AMIS
┌─────────────────────────────────────────┐
│    👥 Invite tes amis lecteurs !         │
│                                          │
│  "Partage ta bibliothèque, emprunte      │
│   leurs livres, recommande tes coups     │
│   de cœur."                              │
│                                          │
│  [📱 Inviter par SMS]                    │
│  [📧 Inviter par email]                  │
│  [🔗 Copier mon lien d'invitation]       │
│  [⏭️ Plus tard]                          │
└─────────────────────────────────────────┘

POST-ONBOARDING :
  - Redirection vers la Home
  - Si l'utilisateur a scanné une étagère → afficher ses livres
  - Si skip → afficher un état vide engageant avec CTA "Scanner"
  - Marquer onboarding_completed = true dans le profil
```

---

## MODULE 2 : 👤 PROFIL UTILISATEUR & PAGE PARAMÈTRES

### 2.1 — Profil utilisateur

```
PAGE PROFIL — visible par l'utilisateur et (partiellement) par ses amis

PROFIL PERSONNEL :
┌─────────────────────────────────────────────────────┐
│  [📷 Avatar]  Sophie Martin                          │
│  @sophie_m · Membre depuis mars 2025                 │
│  📍 Lyon, France (optionnel)                         │
│                                                      │
│  📝 Bio : "Dévoreuse de romans, fan de Camus et de   │
│  SF. Toujours un livre dans le sac."                 │
│                                                      │
│  ━━━━━━━━━━ MES STATS ━━━━━━━━━━                     │
│  📚 247 livres  │  📖 182 lus  │  ⭐ 4.1 note moy.   │
│  🏆 Objectif 2025 : 24/30 livres                     │
│  🔥 Streak : 14 jours consécutifs                    │
│                                                      │
│  ━━━━━━━━━━ MES GENRES ━━━━━━━━━━                    │
│  [camembert : Roman 40%, SF 25%, Philo 15%, ...]     │
│                                                      │
│  ━━━━━━━━━━ TOP AUTEURS ━━━━━━━━━━                   │
│  🥇 Camus (12 livres) 🥈 Asimov (8) 🥉 Le Guin (6) │
│                                                      │
│  ━━━━━━━━━━ ACTIVITÉ RÉCENTE ━━━━━━━━━━              │
│  📖 A terminé "Dune" — ⭐⭐⭐⭐⭐ — il y a 2 jours     │
│  📷 A scanné une étagère (+15 livres) — il y a 5j    │
│  💬 A recommandé "Sapiens" à Marc — il y a 1 sem     │
│                                                      │
│  [✏️ Modifier le profil]  [⚙️ Paramètres]            │
└─────────────────────────────────────────────────────┘

PROFIL VU PAR UN AMI :
  - Même layout mais :
    → Pas de bouton "Modifier"
    → Boutons : [📚 Voir sa bibliothèque] [💬 Recommander un livre]
    → Seulement les stats/infos dont la visibilité est >= 'friends'
    → Bio, avatar, stats publiques toujours visibles

ÉDITION DU PROFIL :
  - Avatar : upload photo ou prise caméra (crop circulaire)
  - Nom d'affichage
  - Username unique (@sophie_m)
  - Bio (280 caractères max)
  - Localisation (ville, optionnel)
  - Genres préférés (tags sélectionnables)
  - Lien externe (blog, Goodreads, Babelio...)
  - Objectif de lecture annuel
```

### 2.2 — Page Paramètres

```
PAGE PARAMÈTRES — Accessible depuis le profil ou le menu

⚙️ PARAMÈTRES
│
├── 👤 COMPTE
│   ├── Numéro de téléphone : +33 6 XX XX XX XX [Modifier]
│   ├── Email : sophie@email.com [Modifier / Ajouter]
│   ├── Comptes liés : Google ✅ · Apple ❌ [Lier]
│   ├── Changer le mot de passe (si auth email)
│   └── Supprimer mon compte [⚠️ Irréversible]
│
├── 🌍 LANGUE & RÉGION
│   ├── Langue de l'application : 🇫🇷 Français [Modifier]
│   │   (Français, English, Español, Deutsch, Italiano, Português)
│   ├── Langue de recherche des livres : Français + English [Modifier]
│   │   (permet de chercher les métadonnées dans plusieurs langues)
│   ├── Format de date : JJ/MM/AAAA
│   └── Fuseau horaire : Europe/Paris (auto-détecté)
│
├── 🔔 NOTIFICATIONS
│   ├── Notifications push : ✅ Activées
│   ├── Notifications email : ✅ Activées
│   ├── Notifications SMS : ❌ Désactivées
│   ├── ──── TYPES ────
│   ├── Prêts & retours : ✅
│   ├── Rappels de retard : ✅ (non désactivable si retard actif)
│   ├── Recommandations d'amis : ✅
│   ├── Activité sociale (fil) : ✅
│   ├── Suggestions IA : ✅
│   ├── Rappels de lecture (streak) : ✅
│   ├── Résumé hebdomadaire : ✅ [Lundi / Vendredi]
│   └── Fréquence rappels retard : [Tous les 3 jours ▼]
│
├── 🔒 CONFIDENTIALITÉ & VISIBILITÉ
│   ├── Bibliothèque par défaut : [Amis ▼] (Privé / Amis / Public)
│   ├── Avis par défaut : [Amis ▼]
│   ├── Progression de lecture : [Amis ▼]
│   ├── Stats & profil : [Public ▼]
│   ├── Wishlist : [Amis ▼]
│   ├── Qui peut me trouver par téléphone : [Tout le monde ▼]
│   ├── Qui peut me trouver par email : [Tout le monde ▼]
│   └── Qui peut me demander en ami : [Tout le monde ▼]
│
├── 📚 BIBLIOTHÈQUE
│   ├── Livres non prêtables : [Gérer la liste]
│   ├── Durée de prêt par défaut : [30 jours ▼]
│   ├── Max prêts simultanés par ami : [3 ▼]
│   ├── Relance automatique des retards : ✅
│   ├── Ton des relances : [Amical ▼] (Amical / Neutre / Ferme)
│   └── Objectif de lecture annuel : [30 livres]
│
├── 📱 APPLICATION
│   ├── Thème : [Système ▼] (Clair / Sombre / Système)
│   ├── Mode d'affichage bibliothèque : [Grille ▼] (Grille / Liste / Étagère)
│   ├── Qualité des photos de scan : [Haute ▼] (Normale / Haute)
│   ├── Stockage hors-ligne : 245 Mo [Gérer]
│   └── Vider le cache images : [Vider]
│
├── 📤 DONNÉES
│   ├── Exporter ma bibliothèque : [CSV] [JSON] [Goodreads]
│   ├── Importer depuis : [Goodreads] [Babelio] [CSV]
│   └── Sauvegarder mes données : [Télécharger tout]
│
├── 👥 INVITATIONS
│   ├── Mon lien d'invitation : biblioshare.app/invite/sophie_m [Copier]
│   ├── Mon QR code d'invitation : [Afficher]
│   ├── Inviter par SMS : [Ouvrir]
│   ├── Inviter par email : [Ouvrir]
│   └── Amis invités : 7 inscrits / 12 invités
│
└── ℹ️ À PROPOS
    ├── Version : 1.2.0
    ├── Conditions d'utilisation
    ├── Politique de confidentialité
    ├── Licences open source
    ├── Nous contacter / Feedback
    └── Noter l'app ⭐
```

### 2.3 — Modèle de données profil & paramètres

```
STRUCTURE FIRESTORE :

/users/{userId}
  ├── displayName: "Sophie Martin"
  ├── username: "sophie_m"
  ├── email: "sophie@email.com"
  ├── phone: "+33612345678"
  ├── photoUrl: "gs://biblioshare/.../avatar.jpg"
  ├── bio: "Dévoreuse de romans..."
  ├── location: "Lyon, France"
  ├── preferredGenres: ["Roman", "SF", "Philosophie"]
  ├── externalLink: "https://goodreads.com/sophie"
  ├── locale: "fr"
  ├── timezone: "Europe/Paris"
  ├── createdAt: Timestamp
  ├── onboardingCompleted: true
  ├── authProviders: ["phone", "google"]
  │
  ├── settings/
  │   ├── notifications: {
  │   │     push: true, email: true, sms: false,
  │   │     loans: true, reminders: true, recos: true,
  │   │     social: true, aiSuggestions: true, streak: true,
  │   │     weeklySummary: true, weeklySummaryDay: "monday",
  │   │     reminderFrequencyDays: 3
  │   │   }
  │   ├── privacy: {
  │   │     defaultLibraryVisibility: "friends",
  │   │     defaultReviewVisibility: "friends",
  │   │     progressVisibility: "friends",
  │   │     profileVisibility: "public",
  │   │     wishlistVisibility: "friends",
  │   │     findByPhone: "everyone",
  │   │     findByEmail: "everyone",
  │   │     friendRequests: "everyone"
  │   │   }
  │   ├── library: {
  │   │     nonLendableBooks: ["bookId1", "bookId2"],
  │   │     defaultLoanDays: 30,
  │   │     maxLoansPerFriend: 3,
  │   │     autoReminders: true,
  │   │     reminderTone: "friendly"
  │   │   }
  │   └── app: {
  │         theme: "system",
  │         libraryDisplayMode: "grid",
  │         scanQuality: "high",
  │         locale: "fr",
  │         searchLanguages: ["fr", "en"]
  │       }
  │
  ├── stats/
  │   ├── totalBooks: 247
  │   ├── booksRead: 182
  │   ├── avgRating: 4.1
  │   ├── currentStreak: 14
  │   ├── longestStreak: 31
  │   └── yearlyGoal: { year: 2025, target: 30, current: 24 }
  │
  └── invitations/
      ├── inviteCode: "sophie_m"
      ├── inviteLink: "https://biblioshare.app/invite/sophie_m"
      └── invitedUsers: [{ phone: "+33...", status: "registered" }, ...]
```

---

## MODULE 3 : 📷 SCAN & RECONNAISSANCE D'ÉTAGÈRE

### 3.1 — Capture de la photo

```
Fonctionnalités :
- Accès à la caméra du téléphone (ou upload d'une photo existante)
- Guide visuel de cadrage : overlay semi-transparent montrant comment cadrer l'étagère
- Possibilité de prendre PLUSIEURS photos pour une grande étagère (panorama ou multi-shot)
- Détection automatique de la qualité : si flou ou trop sombre → demander de reprendre
- Stockage temporaire de l'image brute en haute résolution
```

### 3.2 — Analyse de l'image via Vision AI

```
Pipeline de traitement :
1. SEGMENTATION DE L'ÉTAGÈRE
   - Détecter les limites de l'étagère (étagères multiples = plusieurs rangées)
   - Identifier chaque tranche de livre individuellement (bounding boxes)
   - Gérer les livres penchés, empilés horizontalement, ou partiellement cachés

2. EXTRACTION DE TEXTE (OCR)
   - Pour chaque livre détecté, extraire :
     → Titre (priorité haute)
     → Auteur (si visible sur la tranche)
     → Éditeur / collection (si visible)
   - Gérer les textes verticaux, inversés, et multi-langues (FR, EN, ES, DE minimum)
   - Score de confiance pour chaque extraction (0-100%)

3. RECONNAISSANCE VISUELLE COMPLÉMENTAIRE
   - Couleur et design de la couverture/tranche
   - Logo d'éditeur reconnaissable (Folio, Poche, Gallimard, Penguin, etc.)
   - Estimation de la taille/épaisseur du livre
   - Détection de collections (même design = même collection)
```

### 3.3 — Prompt d'analyse d'image (à envoyer à l'API Vision)

```markdown
Analyse cette photo d'étagère de livres. Pour CHAQUE livre visible :

1. Identifie le titre exact (ou ta meilleure estimation)
2. Identifie l'auteur si visible
3. Identifie l'éditeur/collection si reconnaissable
4. Attribue un score de confiance (0-100%) à ton identification
5. Note la position : étagère N°[x], position [y] depuis la gauche
6. Décris brièvement l'apparence (couleur tranche, taille estimée)

Si un livre est partiellement caché ou illisible :
- Indique "PARTIEL" et donne ce que tu peux lire
- Suggère des candidats probables basés sur le contexte (livres voisins, collection)

Retourne le résultat en JSON structuré :
{
  "etageres": [
    {
      "numero": 1,
      "livres": [
        {
          "position": 1,
          "titre_detecte": "...",
          "auteur_detecte": "...",
          "editeur_detecte": "...",
          "confiance": 85,
          "statut": "COMPLET" | "PARTIEL" | "ILLISIBLE",
          "apparence": "tranche rouge, ~300 pages, format poche",
          "candidats_alternatifs": ["...", "..."]
        }
      ]
    }
  ],
  "stats": {
    "total_livres": 45,
    "identifies_confiance_haute": 38,
    "partiels": 5,
    "illisibles": 2
  }
}
```

---

## MODULE 4 : 🌐 ENRICHISSEMENT WEB AUTOMATIQUE

### 4.1 — Stratégie de recherche multi-sources

```
Pour chaque livre identifié, lancer une recherche en cascade :

SOURCE PRIORITAIRE → Google Books API
  - Recherche par titre + auteur
  - Récupérer : ISBN, description, catégories, nombre de pages,
    date de publication, éditeur, langue, image de couverture,
    note moyenne, nombre d'avis

SOURCES COMPLÉMENTAIRES → en parallèle :
  - Open Library API (openlibrary.org) → données libres, éditions multiples
  - Babelio (scraping léger ou API si dispo) → avis francophones, tags
  - Amazon Product API → prix, disponibilité, avis
  - Goodreads (via web) → note communautaire, listes, livres similaires
  - WorldCat → données bibliographiques normalisées
  - BnF (Bibliothèque nationale de France) → données catalogue français

LOGIQUE DE FUSION :
  - Croiser les résultats de 2+ sources pour confirmer l'identification
  - Si le titre OCR a un score < 70%, tester les candidats alternatifs
  - Privilégier l'édition qui correspond à l'apparence physique détectée
    (format poche vs grand format, couleur de couverture)
```

### 4.2 — Fiche livre enrichie (modèle de données)

```json
{
  "id": "uuid-v4",
  "identification": {
    "isbn_10": "2070368228",
    "isbn_13": "9782070368228",
    "titre": "L'Étranger",
    "titre_original": "L'Étranger",
    "sous_titre": null,
    "auteurs": [
      {
        "nom": "Camus",
        "prenom": "Albert",
        "role": "auteur"
      }
    ],
    "traducteurs": [],
    "editeur": "Gallimard",
    "collection": "Folio",
    "date_publication": "1972-02-07",
    "date_premiere_edition": "1942-06-15",
    "langue": "fr",
    "langue_originale": "fr"
  },
  "details_physiques": {
    "nombre_pages": 186,
    "format": "poche",
    "dimensions_cm": { "hauteur": 17.8, "largeur": 10.8, "epaisseur": 1.0 },
    "poids_g": 120
  },
  "contenu": {
    "resume": "Aujourd'hui, maman est morte...",
    "resume_court": "Roman existentialiste sur l'absurde...",
    "genres": ["Roman", "Littérature française", "Philosophie", "Existentialisme"],
    "themes": ["absurde", "indifférence", "mort", "société", "justice"],
    "mots_cles": ["Algérie", "Meursault", "soleil", "meurtre"],
    "public_cible": "adulte",
    "serie": null,
    "tome": null
  },
  "communaute": {
    "note_goodreads": 3.98,
    "nombre_avis_goodreads": 1250000,
    "note_babelio": 4.1,
    "nombre_avis_babelio": 18500,
    "note_google_books": 4.0,
    "tags_populaires": ["classique", "court", "incontournable", "bac-français"]
  },
  "medias": {
    "couverture_url": "https://...",
    "couverture_locale": "/images/covers/9782070368228.jpg",
    "miniature_url": "https://..."
  },
  "meta_scan": {
    "date_scan": "2025-03-15T14:30:00Z",
    "confiance_identification": 95,
    "source_identification": "ocr+google_books",
    "position_etagere": { "etagere": 2, "position": 7 },
    "photo_originale_ref": "scan_2025-03-15_001.jpg"
  },
  "possession": {
    "proprietaire_id": "user_001",
    "date_ajout": "2025-03-15",
    "etat": "bon",
    "notes_personnelles": "Lu en terminale, à relire",
    "lu": true,
    "date_lecture": "2008-06-00",
    "note_personnelle": 5,
    "tags_personnels": ["favoris", "à-relire", "prêté-souvent"]
  }
}
```

### 4.3 — Validation utilisateur

```
Après l'enrichissement automatique, présenter à l'utilisateur :

ÉCRAN DE VALIDATION :
┌─────────────────────────────────────────────────┐
│ 📷 Photo de la tranche │ 📕 Couverture trouvée │
│                         │                        │
│ [image recadrée]        │ [image web]            │
│                         │                        │
│ ✅ "L'Étranger" — Albert Camus                   │
│    Folio, Gallimard — 186 pages                  │
│    Confiance : 95%                                │
│                                                   │
│ [✓ Confirmer] [✏️ Corriger] [🔍 Autre édition]   │
│                                                   │
│ ⚠️ "???" — Livre #12 — ILLISIBLE                 │
│    Suggestions : [Option A] [Option B] [Saisir]  │
└─────────────────────────────────────────────────┘

- Permettre la correction manuelle rapide (titre, auteur)
- Relancer la recherche web si correction
- Scan ISBN par code-barre en fallback pour les livres non identifiés
```

---

## MODULE 5 : ⭐ AVIS PERSONNELS & JOURNAL DE LECTURE

### 5.1 — Marquer un livre comme "lu" et le noter

```
DÉCLENCHEUR :
Quand l'utilisateur marque un livre comme "terminé", déclencher le FLOW D'AVIS :

ÉCRAN POST-LECTURE :
┌─────────────────────────────────────────────────────┐
│ 🎉 Bravo ! Tu as terminé "L'Étranger" !            │
│                                                      │
│ ⭐⭐⭐⭐⭐  Ta note globale (1-5 étoiles)             │
│                                                      │
│ Notes détaillées (optionnel, swipe pour noter) :     │
│   📖 Histoire / Intrigue    ⭐⭐⭐⭐☆                  │
│   ✍️ Style d'écriture        ⭐⭐⭐⭐⭐                  │
│   🧠 Profondeur / Réflexion  ⭐⭐⭐⭐⭐                  │
│   💓 Émotion / Attachement   ⭐⭐⭐☆☆                  │
│   🏃 Rythme / Page-turner    ⭐⭐⭐☆☆                  │
│   🎯 Originalité             ⭐⭐⭐⭐☆                  │
│                                                      │
│ 💬 Ton avis en quelques mots :                       │
│ ┌──────────────────────────────────────────┐         │
│ │ "Court mais percutant. Meursault m'a     │         │
│ │ hanté pendant des jours. Le style sec    │         │
│ │ de Camus colle parfaitement au sujet."   │         │
│ └──────────────────────────────────────────┘         │
│                                                      │
│ 🏷️ Tes tags : [coup-de-coeur] [fait-réfléchir]      │
│               [+ ajouter un tag]                     │
│                                                      │
│ 📝 Notes privées (visibles que par toi) :            │
│ ┌──────────────────────────────────────────┐         │
│ │ "Page 47 : passage magnifique sur la     │         │
│ │ lumière. Relire le chapitre du procès."  │         │
│ └──────────────────────────────────────────┘         │
│                                                      │
│ [Publier l'avis]  [Garder en privé]  [Plus tard]     │
└─────────────────────────────────────────────────────┘
```

### 5.2 — Journal de lecture personnel

```
FONCTIONNALITÉS DU JOURNAL :

1. SUIVI DE PROGRESSION EN COURS DE LECTURE
   - Marquer la page ou le % d'avancement
   - Widget rapide : "J'en suis à la page [___]" 
   - Estimation du temps restant (basée sur le rythme de lecture)
   - Mini-graphique de vitesse de lecture
   - Streak : "🔥 12 jours de lecture consécutifs"

2. ANNOTATIONS EN COURS DE ROUTE
   - Ajouter des notes liées à un numéro de page ou chapitre
   - Citations favorites (avec n° de page)
   - Humeur de lecture : 😍🤔😢😂🫠 → associer une émotion à un moment
   - Photos de passages marquants (photo → OCR → texte enregistré)

3. HISTORIQUE & STATISTIQUES
   - Chronologie visuelle : frise de toutes les lectures terminées
   - Stats annuelles :
     → Nombre de livres lus (objectif annuel paramétrable)
     → Pages totales / Temps estimé de lecture
     → Genres les plus lus (camembert)
     → Auteurs les plus lus (podium)
     → Note moyenne donnée
     → Mois le plus actif / livre le plus rapide / le plus long
     → Comparaison année N vs N-1
   - "Reading wrapped" en fin d'année (style Spotify Wrapped)
   
4. CLASSEMENTS PERSONNELS
   - Top 10 all-time (drag & drop pour classer)
   - Top par genre / par année / par décennie
   - "Si je ne devais garder qu'un livre" → mettre en avant LE favori
   - Tags personnels : "à relire", "coup-de-coeur", "décevant",
     "offrir-absolument", "pas-pour-tout-le-monde"
```

### 5.3 — Visibilité des avis

```
NIVEAUX DE PARTAGE PAR AVIS :

🔒 PRIVÉ       → que toi (notes perso, annotations intimes)
👥 AMIS        → visible par tes amis ShelfMate
🌍 PUBLIC      → visible par tous (lien partageable, indexable)

CHAQUE ÉLÉMENT est configurable indépendamment :
  - Note étoilée     → [amis] par défaut
  - Avis texte        → [amis] par défaut
  - Notes détaillées  → [amis] par défaut
  - Tags              → [amis] par défaut
  - Annotations/pages → [privé] par défaut (c'est ton jardin secret)
  - Citations fav     → [amis] par défaut
  - Progression       → [amis] par défaut ("Sophie est à 60% de Dune")
```

### 5.4 — Modèle de données avis & journal

> **Note FlutterFlow/Firebase** : Les schémas SQL ci-dessous décrivent la structure logique des données. Dans Firestore, ils correspondent aux sous-collections et documents décrits dans la section Architecture. Les `REFERENCES` deviennent des champs `userId` / `bookId` (strings) et les `ENUM` deviennent des strings validées côté Firestore Rules ou Cloud Functions.

```sql
CREATE TABLE book_reviews (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  book_id UUID REFERENCES books(id),
  
  -- Notes
  rating_global DECIMAL(2,1) CHECK (rating_global BETWEEN 0.5 AND 5),
  rating_story DECIMAL(2,1),
  rating_writing DECIMAL(2,1),
  rating_depth DECIMAL(2,1),
  rating_emotion DECIMAL(2,1),
  rating_pacing DECIMAL(2,1),
  rating_originality DECIMAL(2,1),
  
  -- Avis
  review_text TEXT,
  review_visibility ENUM('private', 'friends', 'public') DEFAULT 'friends',
  tags TEXT[],              -- ['coup-de-coeur', 'fait-réfléchir']
  private_notes TEXT,       -- notes perso (toujours privées)
  
  -- Dates
  started_reading_at DATE,
  finished_reading_at DATE,
  reviewed_at TIMESTAMP,
  updated_at TIMESTAMP,
  
  UNIQUE(user_id, book_id)
);

CREATE TABLE reading_progress (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  book_id UUID REFERENCES books(id),
  current_page INTEGER,
  total_pages INTEGER,
  percentage DECIMAL(5,2),
  updated_at TIMESTAMP
);

CREATE TABLE book_annotations (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  book_id UUID REFERENCES books(id),
  page_number INTEGER,
  chapter VARCHAR(100),
  type ENUM('note', 'citation', 'mood', 'photo'),
  content TEXT,
  mood_emoji VARCHAR(10),       -- 😍🤔😢 etc
  photo_url TEXT,
  visibility ENUM('private', 'friends', 'public') DEFAULT 'private',
  created_at TIMESTAMP
);

CREATE TABLE reading_goals (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  year INTEGER,
  target_books INTEGER,
  current_books INTEGER DEFAULT 0,
  target_pages INTEGER,
  current_pages INTEGER DEFAULT 0
);
```


## MODULE 6 : 👥 BIBLIOTHÈQUE SOCIALE & INVITATIONS

### 6.1 — Système d'amis

```
GESTION DES CONNEXIONS :
- Ajouter un ami par : email, username, QR code, lien de partage
- Niveaux de visibilité de sa bibliothèque :
  → PRIVÉ : personne ne voit
  → AMIS : visible par les amis acceptés
  → PUBLIC : visible par tous (lien partageable)
- Possibilité de créer des GROUPES (ex: "Club de lecture", "Famille", "Collègues")
- Chaque livre peut avoir sa propre visibilité (override du défaut)

PROFIL BIBLIOTHÈQUE :
- Stats : nombre total de livres, genres préférés, auteurs les plus représentés
- "Shelfie" : photo stylisée de ses étagères
- Liste de souhaits (wishlist) visible par les amis
- Livres récemment ajoutés (fil d'activité)
```

### 6.2 — Explorer la bibliothèque de ses amis

```
FONCTIONNALITÉS DE DÉCOUVERTE :

1. NAVIGATION AMIS
   - Vue liste des amis avec aperçu (nombre de livres, derniers ajouts)
   - Vue "étagère virtuelle" → affichage visuel façon étagère des livres de l'ami
   - Recherche dans la bibliothèque d'un ami

2. RECHERCHE CROISÉE
   - "Qui parmi mes amis possède [titre] ?" → résultat instantané
   - "Livres en commun avec [ami]" → intersection
   - "Livres que [ami] a et pas moi" → découverte
   - "Livres que j'ai et qu'aucun ami n'a" → raretés
   - "Top livres les mieux notés par mes amis" → recommandations

3. RECOMMANDATIONS SOCIALES
   - "Basé sur vos goûts communs avec [ami], vous aimerez peut-être..."
   - "3 amis ont ce livre et l'ont adoré"
   - "[Ami] vient d'ajouter un livre d'un auteur que vous aimez"

4. WISHLIST CROISÉE
   - "Ce livre est sur la wishlist de [ami]" → idée cadeau !
   - "[Ami] possède un livre de votre wishlist" → demander à emprunter
   - Alerte anniversaire : "L'anniversaire de [ami] approche,
     voici des livres de sa wishlist"
```

### 6.3 — Système d'invitation par SMS et Email

```
INVITER SES AMIS — Le nerf de la croissance organique

MÉTHODES D'INVITATION :

1. 📱 INVITATION PAR SMS
   Flow :
   → Bouton "Inviter un ami" → accès aux contacts du téléphone
   → Sélection d'un ou plusieurs contacts
   → SMS pré-rédigé envoyé automatiquement :
   
   "Hey [Prénom] ! 👋 Je gère ma bibliothèque sur BiblioShare 
   et j'adorerais voir la tienne. Rejoins-moi : 
   https://biblioshare.app/invite/sophie_m 📚"
   
   → Le lien contient l'ID de l'inviteur (tracking + ajout ami auto)
   → Si le destinataire clique → page d'accueil web avec preview :
     "Sophie t'invite sur BiblioShare ! Elle a 247 livres 📚"
     [Télécharger l'app iOS] [Télécharger l'app Android] [Version web]
   → À l'inscription → amitié automatiquement créée (pas besoin d'accepter)
   
   TECHNIQUE :
   - Flutter : url_launcher pour ouvrir l'app SMS native avec texte pré-rempli
   - OU share_plus pour utiliser la sheet de partage native du téléphone
   - Firebase Dynamic Links pour les liens intelligents (deep linking)
     → ouvre l'app si installée, sinon redirige vers le store

2. 📧 INVITATION PAR EMAIL
   Flow :
   → Saisie manuelle de l'email OU sélection dans les contacts
   → Email envoyé via Cloud Function + SendGrid :
   
   Objet : "Sophie t'invite à rejoindre BiblioShare 📚"
   Corps :
   ┌─────────────────────────────────────────────────────┐
   │  📚 BiblioShare                                      │
   │                                                      │
   │  Sophie Martin t'invite à découvrir BiblioShare !    │
   │                                                      │
   │  "J'ai 247 livres dans ma bibliothèque et j'aimerais│
   │   qu'on puisse partager nos lectures. Viens voir !"  │
   │                                                      │
   │  [📷 Aperçu de la bibliothèque de Sophie]            │
   │  (3-4 couvertures de ses livres les mieux notés)     │
   │                                                      │
   │  Avec BiblioShare, tu peux :                         │
   │  • Scanner ton étagère pour cataloguer tes livres    │
   │  • Emprunter des livres à tes amis                   │
   │  • Partager tes coups de cœur                        │
   │                                                      │
   │         [🚀 Rejoindre BiblioShare]                    │
   │                                                      │
   │  Ce message a été envoyé par Sophie via BiblioShare.  │
   │  [Se désinscrire des invitations]                     │
   └─────────────────────────────────────────────────────┘

3. 🔗 LIEN DE PARTAGE UNIVERSEL
   → Lien unique par utilisateur : biblioshare.app/invite/{username}
   → Partageable n'importe où : WhatsApp, Messenger, Instagram, Twitter...
   → Firebase Dynamic Links avec fallback web
   → Preview OpenGraph riche (titre, description, image)

4. 📱 QR CODE
   → QR code unique généré pour chaque utilisateur
   → Affichable dans l'app (écran dédié, luminosité auto max)
   → Scan par un ami → ouvre le lien d'invitation
   → Parfait pour les échanges en personne ("Scanne mon code !")

5. 🔍 RECHERCHE D'AMIS DÉJÀ INSCRITS
   → "Trouver des amis" → scan des contacts téléphone
   → Matching : numéros de téléphone déjà dans Firebase Auth
   → Liste : "Ces contacts sont déjà sur BiblioShare : [Marc, Léa, ...]"
   → [Ajouter en ami] pour chacun
   → Respect de la confidentialité : n'affiche que ceux qui ont activé
     "Qui peut me trouver par téléphone : Tout le monde"

TRACKING & GAMIFICATION DES INVITATIONS :
  - Compteur : "Tu as invité 12 amis, 7 se sont inscrits !"
  - Notification quand un ami invité s'inscrit :
    "🎉 Marc vient de rejoindre BiblioShare grâce à toi !"
  - Badge "Ambassadeur" à 5 amis inscrits
  - Badge "Évangéliste" à 20 amis inscrits
  - L'ami invité voit : "Invité(e) par Sophie" sur son profil

CLOUD FUNCTIONS ASSOCIÉES :
  - sendSMSInvite(phone, inviterId) → via Twilio
  - sendEmailInvite(email, inviterId) → via SendGrid
  - onUserCreated(userId) → vérifie s'il vient d'un lien d'invitation
    → si oui : crée automatiquement la friendship
    → notifie l'inviteur
  - generateInvitePreview(inviterId) → image OpenGraph avec couvertures
```

### 6.4 — Modèle de données social

```sql
-- Relations d'amitié
CREATE TABLE friendships (
  id UUID PRIMARY KEY,
  requester_id UUID REFERENCES users(id),
  receiver_id UUID REFERENCES users(id),
  status ENUM('pending', 'accepted', 'blocked'),
  group_tags TEXT[], -- ex: ['famille', 'club-lecture']
  source ENUM('search', 'invite_sms', 'invite_email', 'invite_link', 'qr_code'),
  created_at TIMESTAMP,
  accepted_at TIMESTAMP
);

-- Invitations envoyées (tracking)
CREATE TABLE invitations (
  id UUID PRIMARY KEY,
  inviter_id UUID REFERENCES users(id),
  channel ENUM('sms', 'email', 'link', 'qr'),
  recipient_phone TEXT,
  recipient_email TEXT,
  status ENUM('sent', 'clicked', 'registered', 'expired'),
  registered_user_id UUID REFERENCES users(id),
  sent_at TIMESTAMP,
  clicked_at TIMESTAMP,
  registered_at TIMESTAMP
);

-- Groupes
CREATE TABLE groups (
  id UUID PRIMARY KEY,
  name VARCHAR(100),
  creator_id UUID REFERENCES users(id),
  visibility ENUM('private', 'invite_only'),
  created_at TIMESTAMP
);

-- Activité sociale (fil)
CREATE TABLE social_feed (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  action_type ENUM(
    'added_book', 'finished_book', 'rated_book',
    'lent_book', 'returned_book', 'scan_shelf',
    'joined_group', 'added_to_wishlist', 'invited_friend',
    'friend_joined'
  ),
  book_id UUID REFERENCES books(id),
  metadata JSONB,
  created_at TIMESTAMP
);
```

---

---

## MODULE 7 : 💬 RECOMMANDATIONS ACTIVES — "TU DOIS LIRE ÇA"

### 7.1 — Le moment magique : tu finis un livre et tu veux le partager

```
FLOW "JE RECOMMANDE" — déclenché juste après l'avis :

ÉCRAN POST-AVIS (si note >= 4 étoiles) :
┌─────────────────────────────────────────────────────┐
│ 🔥 Tu as adoré "L'Étranger" !                       │
│                                                      │
│ Un(e) ami(e) devrait le lire ?                       │
│                                                      │
│ 👤 Sophie  → "Aime Sartre, la philo, les courts"    │
│    Match : 92% — [💬 Recommander]                    │
│                                                      │
│ 👤 Marc    → "Aime les polars, pas trop la philo"   │
│    Match : 34% — [💬 Recommander quand même]         │
│                                                      │
│ 👤 Léa     → "⚠️ L'a déjà dans sa bibliothèque"     │
│    [💬 "Tu l'as lu ? T'en as pensé quoi ?"]          │
│                                                      │
│ 👤 Autre ami...  [Voir tous mes amis]                │
│                                                      │
│ [Passer] [Recommander à plusieurs]                   │
└─────────────────────────────────────────────────────┘

INTELLIGENCE DU MATCHING :
  Le système suggère les amis les plus pertinents en se basant sur :
  - Genres préférés de l'ami (basés sur sa bibliothèque et ses notes)
  - Auteurs en commun appréciés
  - Tags en commun ("fait-réfléchir", "page-turner"...)
  - Historique : "Sophie a aussi aimé 3 livres que tu as adorés"
  - L'ami a ce livre dans sa wishlist → PRIORITÉ MAXIMALE 🎯
  - L'ami a déjà ce livre → proposer d'en discuter plutôt
  - L'ami lit un livre du même auteur en ce moment → timing parfait
```

### 7.2 — Le message de recommandation personnalisé

```
COMPOSITION DU MESSAGE DE RECO :

L'utilisateur peut :
  1. ENVOYER UN MESSAGE RAPIDE (1 tap) :
     → "Je viens de finir L'Étranger, c'est un must ! ⭐⭐⭐⭐⭐"
     (auto-généré avec sa note)

  2. ÉCRIRE UN MESSAGE PERSO :
     → "Sophie, tu DOIS lire L'Étranger de Camus. Ça m'a rappelé 
        nos discussions sur l'absurde. Court, percutant, parfait 
        pour toi. Je te le prête quand tu veux !"

  3. UTILISER L'IA POUR L'AIDER À RÉDIGER :
     → Basé sur le profil de l'ami + l'avis de l'utilisateur,
       Claude génère un message personnalisé :
     
     Prompt interne :
     "L'utilisateur [Prénom] vient de terminer [Livre] et l'a noté 
     [X]/5 avec l'avis suivant : [avis]. Il veut le recommander à 
     son ami(e) [Prénom ami] qui aime [genres ami] et a récemment 
     lu [derniers livres ami]. Génère un message enthousiaste, 
     personnel et convaincant de 2-3 phrases max, dans un ton 
     amical et naturel (comme un vrai SMS entre potes). 
     Mentionne pourquoi CE livre plaira à CET ami spécifiquement."

  4. AJOUTER UNE OFFRE DE PRÊT :
     → Toggle : "📦 Proposer de lui prêter" → OUI/NON
     → Si OUI : le message inclut "Je te le prête quand tu veux !"
       et un bouton [Emprunter] apparaît côté destinataire

CANAUX D'ENVOI :
  - Notification in-app ShelfMate (défaut)
  - Partage externe : SMS, WhatsApp, Messenger, email
  - Story/post sur le fil social ShelfMate
```

### 7.3 — Côté destinataire : recevoir une recommandation

```
NOTIFICATION REÇUE :
┌─────────────────────────────────────────────────────┐
│ 💌 Recommandation de Thomas                          │
│                                                      │
│ 📕 "L'Étranger" — Albert Camus                      │
│ ⭐⭐⭐⭐⭐ par Thomas                                   │
│                                                      │
│ "Sophie, tu DOIS lire ça ! Ça m'a rappelé nos       │
│ discussions sur l'absurde. Court et percutant."      │
│                                                      │
│ 📊 4.1/5 sur Babelio · 186 pages · 3h de lecture    │
│ 🏷️ Existentialisme, Classique, Court                 │
│                                                      │
│ 👥 Léa et Marc l'ont aussi (Léa : ⭐⭐⭐⭐)            │
│                                                      │
│ [📥 Ajouter à ma wishlist]                           │
│ [📦 Emprunter à Thomas]                              │
│ [👀 Voir l'avis complet de Thomas]                   │
│ [🙏 Merci, je note !]                               │
│ [😅 Pas mon style, mais merci]                       │
└─────────────────────────────────────────────────────┘

ACTIONS DISPONIBLES POUR LE DESTINATAIRE :
  - "Ajouter à ma wishlist" → le livre apparaît dans sa wishlist
  - "Emprunter" → déclenche le workflow de prêt (Module 6)
  - "Merci !" → notification de remerciement au recommandeur
  - "Je l'ai déjà lu" → proposer de partager son avis en retour
  - "Pas mon style" → feedback discret (affine le matching futur,
    PAS de notification négative envoyée à l'ami !)
```

### 7.4 — Suivi des recommandations envoyées

```
DASHBOARD "MES RECOMMANDATIONS" (côté recommandeur) :

📤 ENVOYÉES :
  - "L'Étranger" → Sophie — 📬 Reçu · ⏳ Pas encore lu
  - "Dune" → Marc — 📥 Ajouté à sa wishlist !
  - "Sapiens" → Léa — 📖 En train de le lire (42%) !
  - "1984" → Sophie — ✅ Lu et adoré (⭐⭐⭐⭐⭐) → "Merci !"

ALERTES RECOMMANDEUR :
  - "🎉 Sophie a commencé à lire L'Étranger que tu lui as recommandé !"
  - "📖 Marc est à 60% de Dune — ta reco fait son effet !"
  - "⭐ Léa a terminé Sapiens et l'a noté 5/5 ! Elle te remercie."
  - "💬 Sophie veut discuter de la fin de L'Étranger avec toi"

STATS DE RECOMMANDATION :
  - Taux de conversion : X% de tes recos sont lues
  - Ton influence : X livres lus grâce à toi
  - "Meilleur prescripteur" badge si taux élevé
  - Note moyenne des livres que tu recommandes vs note que l'ami donne
    → "Tes recos à Sophie matchent à 87% avec ses goûts !"
```

### 7.5 — Recommandations automatiques intelligentes

```
EN PLUS DES RECOS MANUELLES, le système peut SUGGÉRER de recommander :

TRIGGERS AUTOMATIQUES :
  
  1. POST-LECTURE + BONNE NOTE
     → "Tu as adoré ce livre ! Un ami devrait le lire ?"
     (le flow décrit en 4.1)
  
  2. MATCH WISHLIST
     → "Sophie a ajouté [Livre] à sa wishlist. Tu l'as et tu l'as adoré.
        Lui envoyer un petit mot d'encouragement ?"
  
  3. MATCH THÉMATIQUE
     → "Léa vient de finir un roman de Camus. Tu as 3 autres Camus
        dans ta bibliothèque. Lui en suggérer un ?"
  
  4. ANNIVERSAIRE / OCCASION
     → "L'anniversaire de Marc est dans 5 jours. Il aimerait sûrement
        [Livre] de sa wishlist. Tu veux lui offrir ou lui prêter ?"
  
  5. DISCUSSION SPONTANÉE
     → Quand deux amis ont lu le même livre :
        "Sophie et toi avez lu L'Étranger. Lancer une discussion ?"
        → Ouvre un mini-thread de discussion autour du livre
  
  6. COMBO SOCIAL
     → "3 de tes amis ont lu [Livre] ce mois-ci et l'ont tous noté 4+.
        Ça a l'air d'être LE livre du moment. Curieux(se) ?"
```

### 7.6 — Modèle de données recommandations

```sql
CREATE TABLE recommendations (
  id UUID PRIMARY KEY,
  sender_id UUID REFERENCES users(id),
  receiver_id UUID REFERENCES users(id),
  book_id UUID REFERENCES books(id),
  
  -- Message
  message_text TEXT,
  message_generated_by_ai BOOLEAN DEFAULT false,
  includes_loan_offer BOOLEAN DEFAULT false,
  
  -- Statut côté destinataire
  status ENUM(
    'sent',              -- envoyé
    'seen',              -- vu (notification ouverte)
    'wishlisted',        -- ajouté à la wishlist
    'borrowed',          -- emprunté via la reco
    'reading',           -- en cours de lecture
    'finished',          -- terminé
    'declined_politely', -- "pas mon style" (invisible pour l'envoyeur)
    'expired'            -- ignoré après 60 jours
  ),
  
  -- Feedback
  receiver_thanks BOOLEAN DEFAULT false,
  receiver_rating DECIMAL(2,1),  -- note du destinataire après lecture
  discussion_thread_id UUID,     -- lien vers fil de discussion
  
  -- Matching
  match_score INTEGER,           -- score de pertinence 0-100
  match_reasons TEXT[],          -- ['genre_commun', 'auteur_aime', 'wishlist']
  
  -- Méta
  trigger_type ENUM(
    'manual',           -- l'utilisateur a choisi de recommander
    'post_review',      -- suggestion post-avis
    'wishlist_match',   -- match wishlist
    'thematic_match',   -- match thématique
    'birthday',         -- occasion spéciale
    'social_trend'      -- tendance sociale
  ),
  sent_via ENUM('in_app', 'sms', 'whatsapp', 'email', 'messenger'),
  created_at TIMESTAMP,
  seen_at TIMESTAMP,
  finished_at TIMESTAMP
);

-- Thread de discussion autour d'un livre entre amis
CREATE TABLE book_discussions (
  id UUID PRIMARY KEY,
  book_id UUID REFERENCES books(id),
  participants UUID[],
  created_from ENUM('recommendation', 'both_read', 'manual'),
  created_at TIMESTAMP
);

CREATE TABLE discussion_messages (
  id UUID PRIMARY KEY,
  discussion_id UUID REFERENCES book_discussions(id),
  sender_id UUID REFERENCES users(id),
  content TEXT,
  spoiler BOOLEAN DEFAULT false,  -- masqué par défaut si true
  created_at TIMESTAMP
);
```


---

## MODULE 8 : 🔄 GESTION DES PRÊTS & ALERTES

### 8.1 — Workflow de prêt complet

```
CYCLE DE VIE D'UN PRÊT :

1. INITIATION DU PRÊT
   Scénario A — Le propriétaire prête :
   → Sélectionner un livre → "Prêter à..." → choisir ami ou saisir nom
   → Date de prêt (auto = aujourd'hui)
   → Durée suggérée (défaut : 30 jours, personnalisable)
   → Photo optionnelle de l'état du livre avant prêt
   → Notification envoyée à l'emprunteur

   Scénario B — L'ami demande à emprunter :
   → Depuis la bibliothèque de l'ami : bouton "Demander à emprunter"
   → Notification au propriétaire → Accepter / Refuser / Proposer alternative
   → Si accepté → prêt créé automatiquement

   Scénario C — Prêt à un non-utilisateur :
   → Saisir nom + téléphone ou email
   → SMS/email envoyé avec lien pour suivre le prêt (sans compte obligatoire)
   → L'emprunteur peut créer un compte plus tard et retrouver son historique

2. SUIVI EN COURS
   - Dashboard "Mes prêts en cours" (côté propriétaire)
   - Dashboard "Mes emprunts en cours" (côté emprunteur)
   - Indicateur visuel : 🟢 dans les temps / 🟡 bientôt dû / 🔴 en retard
   - Possibilité de prolonger (demande côté emprunteur, validation côté propriétaire)
   - Chat intégré par livre prêté (pour discuter du livre !)

3. RETOUR DU LIVRE
   → L'emprunteur ou le propriétaire marque comme "rendu"
   → Confirmation de l'autre partie (ou auto-confirmé après 48h)
   → Photo optionnelle de l'état au retour
   → Note optionnelle ("Super lecture, merci !")
   → Le livre repasse en statut "disponible"
```

### 8.2 — Système d'alertes bidirectionnelles

```
ALERTES PROPRIÉTAIRE (celui qui prête) :

📬 NOTIFICATIONS :
  - "📖 [Ami] souhaite emprunter [Livre]" → action : accepter/refuser
  - "⏰ Rappel : [Livre] prêté à [Ami] depuis 25 jours (retour prévu dans 5 jours)"
  - "🔴 [Livre] prêté à [Ami] est en retard de 3 jours"
  - "🔴🔴 [Livre] est en retard de 14 jours — relance automatique envoyée"
  - "✅ [Ami] a marqué [Livre] comme rendu — confirmer ?"
  - "📊 Résumé mensuel : 3 livres prêtés, 1 en retard, 2 rendus ce mois"

⚙️ PARAMÈTRES PROPRIÉTAIRE :
  - Fréquence des rappels de retard : tous les [3/7/14] jours
  - Relance automatique après [X] jours de retard : OUI/NON
  - Ton de la relance : amical / neutre / ferme
  - Nombre max de livres prêtés simultanément à un même ami
  - Blacklist de livres non prêtables (ex: éditions rares, dédicacés)
  - Notification si un ami ajoute à sa wishlist un livre qu'on possède


ALERTES EMPRUNTEUR (celui qui emprunte) :

📬 NOTIFICATIONS :
  - "📖 [Ami] t'a prêté [Livre] — bon retour prévu le [date]"
  - "⏰ Rappel amical : pense à rendre [Livre] à [Ami] dans 5 jours"
  - "⏰ Dernier jour pour rendre [Livre] à [Ami] !"
  - "🔴 [Livre] devait être rendu il y a 3 jours à [Ami]"
  - "✅ [Ami] a accepté ta demande d'emprunt pour [Livre]"
  - "⏳ [Ami] a accepté ta prolongation de 14 jours"
  - "❌ [Ami] a refusé la prolongation — merci de rendre [Livre]"

⚙️ PARAMÈTRES EMPRUNTEUR :
  - Rappels activés : OUI/NON (défaut : OUI, non désactivable si retard)
  - Fréquence des rappels avant échéance : [7j, 3j, 1j, jour J]
  - Canal de notification : push / email / SMS / tous


ALERTES SYSTÈME (automatiques) :

🤖 ESCALADE AUTOMATIQUE :
  Jour J-7  → rappel doux emprunteur
  Jour J-3  → rappel emprunteur + info propriétaire
  Jour J    → rappel urgent emprunteur
  Jour J+3  → alerte retard aux deux parties
  Jour J+7  → relance ferme emprunteur + résumé propriétaire
  Jour J+14 → relance "dernière chance" + suggestion propriétaire de contacter
  Jour J+30 → marqué comme "litige" + proposition de résolution
```

### 8.3 — Modèle de données prêts

```sql
CREATE TABLE loans (
  id UUID PRIMARY KEY,
  book_id UUID REFERENCES books(id),
  owner_id UUID REFERENCES users(id),
  borrower_id UUID REFERENCES users(id) NULL,
  borrower_external JSONB, -- {name, phone, email} si pas utilisateur
  
  -- Cycle de vie
  status ENUM(
    'requested',      -- demande en attente
    'accepted',       -- accepté, en attente de remise
    'active',         -- livre remis, prêt en cours
    'extension_requested', -- prolongation demandée
    'overdue',        -- en retard
    'return_pending', -- retour déclaré, en attente de confirmation
    'returned',       -- rendu et confirmé
    'disputed',       -- litige
    'cancelled'       -- annulé
  ),
  
  -- Dates
  requested_at TIMESTAMP,
  accepted_at TIMESTAMP,
  lent_at TIMESTAMP,
  due_date DATE,
  original_due_date DATE, -- si prolongé
  returned_at TIMESTAMP,
  confirmed_returned_at TIMESTAMP,
  
  -- Détails
  condition_before TEXT,
  condition_after TEXT,
  photo_before_url TEXT,
  photo_after_url TEXT,
  notes TEXT,
  
  -- Alertes
  last_reminder_sent TIMESTAMP,
  reminder_count INTEGER DEFAULT 0,
  escalation_level INTEGER DEFAULT 0
);

CREATE TABLE loan_messages (
  id UUID PRIMARY KEY,
  loan_id UUID REFERENCES loans(id),
  sender_id UUID REFERENCES users(id),
  message TEXT,
  created_at TIMESTAMP
);

CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  type VARCHAR(50),
  title TEXT,
  body TEXT,
  data JSONB, -- {loan_id, book_id, action_url, ...}
  channel ENUM('push', 'email', 'sms', 'in_app'),
  status ENUM('pending', 'sent', 'read', 'dismissed'),
  scheduled_at TIMESTAMP,
  sent_at TIMESTAMP,
  read_at TIMESTAMP
);
```

### 8.4 — Templates de messages de relance

```
RELANCE AMICALE (J+3) :
"Hey [Prénom] ! 👋 Petit rappel pour [Titre] de [Auteur] — 
le retour était prévu il y a 3 jours. Pas de souci si tu as besoin 
d'un peu plus de temps, dis-moi ! 📚"

RELANCE NEUTRE (J+7) :
"Bonjour [Prénom], je me permets de te rappeler que [Titre] 
devait être rendu le [date]. Est-ce que tu peux me le ramener 
cette semaine ? Merci ! 🙏"

RELANCE FERME (J+14) :
"[Prénom], [Titre] est en retard de 14 jours maintenant. 
J'y tiens beaucoup — est-ce qu'on peut s'organiser pour 
que tu me le rendes rapidement ? Merci de me tenir au courant."

RELANCE DERNIÈRE CHANCE (J+30) :
"[Prénom], ça fait un mois que [Titre] aurait dû être rendu. 
Je commence à m'inquiéter. Peux-tu me confirmer que tu l'as 
toujours et me dire quand tu peux me le rendre ?"
```

---

## MODULE 9 : 📖 DOCUMENTATION

### 9.1 — Règle fondamentale

```
⚠️ LA DOCUMENTATION N'EST PAS OPTIONNELLE ⚠️

Chaque PR / commit significatif DOIT inclure la mise à jour de la doc.
Un module n'est PAS terminé tant que sa doc n'est pas à jour.
Ceci s'applique à TOUS les niveaux :
  - Code (commentaires, JSDoc/DartDoc)
  - API (Cloud Functions)
  - Base de données (schéma Firestore)
  - UI (pages FlutterFlow, composants)
  - Utilisateur (guide d'aide in-app)
```

### 9.2 — Structure de la documentation dans le repo

```
biblioshare/
├── README.md                          ← OBLIGATOIRE (voir template ci-dessous)
├── CHANGELOG.md                       ← Historique des versions
├── LICENSE
│
├── docs/
│   ├── architecture.md                ← Vue d'ensemble de l'archi (ce prompt condensé)
│   ├── getting-started.md             ← Guide pour un nouveau développeur
│   ├── deployment.md                  ← Comment déployer (Firebase, FlutterFlow, stores)
│   │
│   ├── modules/
│   │   ├── 01-auth-onboarding.md      ← Doc du Module 1
│   │   ├── 02-profile-settings.md     ← Doc du Module 2
│   │   ├── 03-scan-recognition.md     ← Doc du Module 3
│   │   ├── 04-web-enrichment.md       ← Doc du Module 4
│   │   ├── 05-reviews-journal.md      ← Doc du Module 5
│   │   ├── 06-social-invitations.md   ← Doc du Module 6
│   │   ├── 07-recommendations.md      ← Doc du Module 7
│   │   └── 08-loans-alerts.md         ← Doc du Module 8
│   │
│   ├── firebase/
│   │   ├── firestore-schema.md        ← Schéma complet Firestore (collections, champs, types)
│   │   ├── firestore-rules.md         ← Règles de sécurité documentées
│   │   ├── cloud-functions.md         ← Chaque function : trigger, params, retour, erreurs
│   │   ├── storage-structure.md       ← Buckets, permissions, nommage
│   │   └── fcm-notifications.md       ← Types de notifs, payloads, topics
│   │
│   ├── flutterflow/
│   │   ├── pages.md                   ← Liste des pages, navigation, paramètres
│   │   ├── components.md              ← Composants réutilisables, props, usage
│   │   ├── custom-actions.md          ← Custom Actions Dart documentées
│   │   ├── custom-widgets.md          ← Custom Widgets documentés
│   │   ├── api-calls.md              ← API Groups, endpoints, mappings
│   │   └── state-management.md        ← App State, Page State, variables
│   │
│   ├── api/
│   │   ├── google-books.md            ← Intégration Google Books API
│   │   ├── open-library.md            ← Intégration Open Library API
│   │   ├── claude-vision.md           ← Intégration Claude API (scan + reco)
│   │   ├── twilio.md                  ← Intégration Twilio (SMS)
│   │   └── sendgrid.md               ← Intégration SendGrid (emails)
│   │
│   └── user-guide/
│       ├── fr/                        ← Guide utilisateur français
│       │   ├── scanner-etagere.md
│       │   ├── gerer-bibliotheque.md
│       │   ├── inviter-amis.md
│       │   ├── preter-emprunter.md
│       │   └── faq.md
│       └── en/                        ← Guide utilisateur anglais
│           ├── scan-shelf.md
│           ├── manage-library.md
│           ├── invite-friends.md
│           ├── lend-borrow.md
│           └── faq.md
│
├── firebase/
│   ├── functions/                     ← Code source des Cloud Functions
│   ├── firestore.rules                ← Règles Firestore
│   ├── storage.rules                  ← Règles Storage
│   └── firebase.json                  ← Config Firebase
│
└── assets/
    ├── icons/
    ├── illustrations/
    └── screenshots/                   ← Screenshots pour la doc et les stores
```

### 9.3 — Template README.md

```markdown
# 📚 BiblioShare

> Scanne ton étagère. Partage ta bibliothèque. Prête tes livres.

## 🎯 C'est quoi BiblioShare ?

BiblioShare est une app mobile (iOS, Android, Web) qui permet de :
- 📷 Photographier une étagère pour identifier automatiquement ses livres
- ⭐ Noter et critiquer ses lectures avec un journal personnel
- 👥 Partager sa bibliothèque avec ses amis
- 💬 Recommander ses coups de cœur
- 🔄 Suivre les prêts de livres avec des alertes intelligentes

## 🏗️ Stack technique

| Composant | Technologie |
|-----------|------------|
| Frontend | FlutterFlow (Flutter) |
| Backend | Firebase (Auth, Firestore, Functions, Storage, FCM) |
| IA / Vision | Claude API (Anthropic) |
| OCR fallback | Google ML Kit |
| SMS | Twilio |
| Email | SendGrid |
| Enrichissement | Google Books API, Open Library API |

## 📁 Structure du repo

[voir section 9.2]

## 🚀 Getting Started

[voir docs/getting-started.md]

## 📋 Modules

| # | Module | Statut |
|---|--------|--------|
| 1 | Auth & Onboarding | 🔲 |
| 2 | Profil & Paramètres | 🔲 |
| 3 | Scan & Reconnaissance | 🔲 |
| 4 | Enrichissement Web | 🔲 |
| 5 | Avis & Journal | 🔲 |
| 6 | Social & Invitations | 🔲 |
| 7 | Recommandations | 🔲 |
| 8 | Prêts & Alertes | 🔲 |
| 9 | Documentation | 🔲 |

## 📝 Changelog

Voir [CHANGELOG.md](./CHANGELOG.md)

## 📄 Licence

[À définir]
```

### 9.4 — Documentation in-app (aide utilisateur)

```
AIDE INTÉGRÉE DANS L'APP :

1. TOOLTIPS CONTEXTUELS
   - Premier usage de chaque fonctionnalité → tooltip explicatif
   - Ex : première ouverture du scanner → "Cadre bien ton étagère, 
     on s'occupe du reste !"
   - Désactivables dans Paramètres > Application > Afficher les tooltips

2. PAGE "AIDE & FAQ" (dans Paramètres > À propos)
   - FAQ dynamique chargée depuis Firestore (modifiable sans mise à jour app)
   - Organisée par thème :
     → Scanner mes livres
     → Gérer ma bibliothèque
     → Inviter des amis
     → Prêter et emprunter
     → Mon compte
   - Barre de recherche dans la FAQ
   - Bouton "Contacter le support" → email ou formulaire

3. ÉCRANS D'ÉTAT VIDE ÉDUCATIFS
   - Bibliothèque vide → "Scanne ta première étagère !"
   - Aucun ami → "Invite tes amis lecteurs !"
   - Aucun prêt → "Prête un livre à un ami pour commencer"
   - Chaque état vide a une illustration + un CTA clair

4. LOCALISATION (i18n)
   - Toute l'app est traduisible
   - Fichiers de traduction dans le repo : /assets/i18n/{locale}.json
   - Langues de lancement : FR, EN
   - Langues prévues : ES, DE, IT, PT
   - Les clés de traduction suivent le format : module.page.element
     Ex : "scan.validation.confirm_button" → "Confirmer"
```

### 9.5 — Documentation des Cloud Functions

```
TEMPLATE POUR DOCUMENTER CHAQUE CLOUD FUNCTION :

/**
 * @function sendSMSInvite
 * @description Envoie une invitation par SMS à un contact
 * @trigger HTTP callable (depuis FlutterFlow API Call)
 * 
 * @param {string} phone - Numéro de téléphone au format E.164 (+33612345678)
 * @param {string} inviterId - ID Firebase de l'utilisateur qui invite
 * @param {string} [customMessage] - Message personnalisé (optionnel)
 * 
 * @returns {object} { success: boolean, invitationId: string }
 * 
 * @throws {auth/unauthenticated} Si l'utilisateur n'est pas connecté
 * @throws {invalid-argument} Si le numéro de téléphone est invalide
 * @throws {resource-exhausted} Si le quota d'invitations SMS est atteint (10/jour)
 * 
 * @sideEffects
 *   - Crée un document dans /invitations
 *   - Envoie un SMS via Twilio
 *   - Met à jour /users/{inviterId}/invitations/invitedUsers
 *   - Crée une entrée dans /social_feed (action: 'invited_friend')
 * 
 * @rateLimit 10 invitations SMS par utilisateur par jour
 * @cost ~0.05€ par SMS (Twilio)
 * 
 * @example
 * const result = await sendSMSInvite({
 *   phone: "+33612345678",
 *   inviterId: "abc123"
 * });
 * // → { success: true, invitationId: "inv_xyz789" }
 */
 
CHAQUE Cloud Function doit avoir ce niveau de documentation.
Pas d'exception.
```

---

## 🏗️ ARCHITECTURE TECHNIQUE — STACK FLUTTERFLOW

```
STACK PRINCIPALE : FLUTTERFLOW + FIREBASE

═══════════════════════════════════════════════════════════
  FRONTEND — FlutterFlow
═══════════════════════════════════════════════════════════

App mobile (iOS + Android + Web) :
  - FlutterFlow comme builder principal (no-code / low-code)
  - Export Flutter natif si besoin de customisation avancée
  - Cible : iOS, Android, Web app (responsive) depuis un seul projet
  - Thème Material 3 personnalisé (couleurs, typo, composants)

Pages principales à créer dans FlutterFlow :
  1. Onboarding / Auth (login, inscription)
  2. Home (dashboard : mes livres, prêts en cours, fil d'activité)
  3. Scanner (caméra + upload photo)
  4. Validation scan (liste des livres détectés à confirmer)
  5. Fiche livre (détails enrichis + avis + actions)
  6. Ma bibliothèque (grille/liste avec filtres et recherche)
  7. Journal de lecture (progression, annotations, stats)
  8. Profil ami + sa bibliothèque
  9. Recommandations (envoyer / recevoir)
  10. Mes prêts (dashboard propriétaire + emprunteur)
  11. Notifications center
  12. Paramètres / Profil

Composants réutilisables FlutterFlow :
  - BookCard (miniature livre avec note, statut prêt, badge)
  - StarRating (notation 1-5 étoiles, interactif)
  - LoanStatusBadge (🟢🟡🔴 + texte)
  - FriendChip (avatar + nom + stats rapides)
  - RecommendationCard (livre + message + actions)
  - ProgressBar (lecture en cours, page X/Y)
  - AlertTile (notification avec action)

═══════════════════════════════════════════════════════════
  BACKEND — Firebase (natif FlutterFlow)
═══════════════════════════════════════════════════════════

Firebase Auth :
  - Email + mot de passe
  - Google Sign-In (OAuth)
  - Apple Sign-In (obligatoire iOS)
  - Magic link par email
  - Authentification anonyme (pour les emprunteurs non-inscrits
    qui reçoivent un lien de suivi de prêt)

Cloud Firestore (base de données NoSQL) :
  Collections principales :
  
  /users/{userId}
    - displayName, email, photoUrl, createdAt
    - settings: { defaultVisibility, reminderFrequency, ... }
    - stats: { totalBooks, booksRead, avgRating, ... }
    - readingGoal: { year, target, current }
  
  /users/{userId}/books/{bookId}
    - isbn, title, author, publisher, collection
    - coverUrl, pageCount, genres, themes
    - enrichmentData: { googleBooks, openLibrary, babelio }
    - possession: { state, dateAdded, shelfPosition }
    - reading: { status, currentPage, startedAt, finishedAt }
    - review: { ratingGlobal, ratingDetailed, text, tags, visibility }
    - privateNotes: string
    - scanMeta: { confidence, photoRef, detectedAt }
  
  /users/{userId}/books/{bookId}/annotations/{annotationId}
    - pageNumber, chapter, type, content, mood, photoUrl
    - visibility, createdAt
  
  /friendships/{friendshipId}
    - requesterId, receiverId, status, groupTags
    - createdAt, acceptedAt
  
  /loans/{loanId}
    - bookId, bookTitle, bookCoverUrl (dénormalisé pour perf)
    - ownerId, borrowerId, borrowerExternal
    - status, lentAt, dueDate, returnedAt
    - conditionBefore, conditionAfter, photoBeforeUrl, photoAfterUrl
    - reminderCount, escalationLevel, lastReminderAt
  
  /loans/{loanId}/messages/{messageId}
    - senderId, text, createdAt
  
  /recommendations/{recoId}
    - senderId, receiverId, bookId
    - messageText, aiGenerated, includesLoanOffer
    - status, matchScore, matchReasons, triggerType
    - sentVia, createdAt, seenAt, finishedAt
  
  /recommendations/{recoId}/discussion/{msgId}
    - senderId, content, spoiler, createdAt
  
  /notifications/{notifId}
    - userId, type, title, body, data
    - channel, status, scheduledAt, sentAt, readAt

  RÈGLES FIRESTORE (sécurité) :
  - Un utilisateur ne peut lire que SES livres + ceux de ses amis
    dont la visibilité est 'friends' ou 'public'
  - Un utilisateur ne peut modifier que SES propres documents
  - Les prêts sont lisibles par owner ET borrower
  - Les recommandations sont lisibles par sender ET receiver
  - Les annotations en 'private' ne sont JAMAIS lisibles par autrui

Firebase Storage :
  - /scans/{userId}/{scanId}.jpg → photos d'étagères originales
  - /covers/{isbn}.jpg → couvertures de livres (cache local)
  - /loans/{loanId}/before.jpg → état du livre avant prêt
  - /loans/{loanId}/after.jpg → état du livre au retour
  - /annotations/{userId}/{annotId}.jpg → photos de passages
  - /avatars/{userId}.jpg → photo de profil

Firebase Cloud Messaging (FCM) :
  - Push notifications iOS + Android
  - Topics par type d'alerte (loan_reminders, recommendations, social)
  - Configuration directe dans FlutterFlow (sans code)

═══════════════════════════════════════════════════════════
  CLOUD FUNCTIONS (Firebase) — Logique serveur
═══════════════════════════════════════════════════════════

Cloud Functions nécessaires (Node.js / TypeScript) :

1. onShelfScan(imageUrl)
   → Appelle Claude API (Vision) pour analyser la photo
   → Retourne la liste des livres détectés en JSON
   → Stocke les résultats dans Firestore

2. enrichBook(title, author, isbn?)
   → Appelle en parallèle :
     - Google Books API
     - Open Library API
     - (optionnel) ISBNdb, Babelio scraping
   → Fusionne les résultats
   → Met à jour la fiche livre dans Firestore

3. scheduledLoanReminders() — CRON toutes les heures
   → Parcourt les prêts actifs
   → Calcule J-7, J-3, J-1, J, J+3, J+7, J+14, J+30
   → Envoie les notifications FCM + emails appropriés
   → Met à jour reminderCount et escalationLevel

4. onRecommendationCreate(recoId)
   → Envoie la notification push au destinataire
   → Si sentVia = 'sms' ou 'email' → appelle SendGrid / Twilio
   → Crée l'entrée dans le fil d'activité social

5. generateRecoMessage(senderId, receiverId, bookId)
   → Récupère le profil lecteur de l'ami (genres, auteurs, notes)
   → Récupère l'avis de l'envoyeur
   → Appelle Claude API pour générer un message personnalisé
   → Retourne le message suggéré

6. computeMatchScore(userId, friendId, bookId)
   → Calcule le score de pertinence d'une reco
   → Basé sur : genres communs, auteurs aimés, tags, wishlist, historique
   → Retourne score 0-100 + raisons

7. onBookFinished(userId, bookId)
   → Triggered quand reading.status passe à 'finished'
   → Met à jour les stats utilisateur
   → Vérifie les triggers de reco automatique :
     - Amis avec goûts compatibles
     - Amis avec ce livre en wishlist
     - Amis lisant le même auteur
   → Crée des suggestions de reco dans Firestore

8. sendExternalNotification(type, recipient, data)
   → Email via SendGrid / Resend
   → SMS via Twilio (pour emprunteurs non-inscrits)

9. yearlyWrapped(userId) — CRON annuel (1er janvier)
   → Compile les stats de l'année
   → Génère le "Reading Wrapped"
   → Notification push "Ton année lecture est prête !"

═══════════════════════════════════════════════════════════
  IA / VISION
═══════════════════════════════════════════════════════════

Analyse d'étagère :
  - Claude API (claude-sonnet-4-5) avec capacité Vision
  - Appelé depuis une Cloud Function
  - L'image est envoyée en base64 ou via URL Firebase Storage
  - Prompt structuré (voir Module 1.3) → réponse JSON

Génération de messages de reco :
  - Claude API (claude-sonnet-4-5) en mode texte
  - Appelé depuis Cloud Function generateRecoMessage()
  - Contexte : profil ami + avis utilisateur → message naturel

OCR fallback :
  - Google ML Kit (intégré Flutter/FlutterFlow)
  - Scan de code-barre : ML Kit Barcode Scanning
  - Utilisable hors-ligne directement sur le device

═══════════════════════════════════════════════════════════
  APIs EXTERNES
═══════════════════════════════════════════════════════════

  - Google Books API (gratuit, 1000 req/jour) → enrichissement principal
  - Open Library API (gratuit, illimité) → données complémentaires
  - ISBNdb API (payant, très complet) → fallback premium
  - Google ML Kit → barcode scanning + OCR on-device
  - Claude API (Anthropic) → vision + génération de texte
  - SendGrid ou Resend → emails transactionnels
  - Twilio → SMS (emprunteurs non-inscrits)

═══════════════════════════════════════════════════════════
  SPÉCIFICITÉS FLUTTERFLOW
═══════════════════════════════════════════════════════════

CUSTOM ACTIONS (Dart) nécessaires dans FlutterFlow :
  Certaines fonctionnalités nécessitent du code Dart custom :

  1. cameraCapture()
     → Accès caméra avec overlay de cadrage custom
     → Package : camera + image_picker
  
  2. barcodeScanner()
     → Scan ISBN via ML Kit
     → Package : google_mlkit_barcode_scanning
  
  3. imageToBase64(imagePath)
     → Convertir la photo pour l'envoyer à Claude API
  
  4. computeReadingStats(booksList)
     → Calculs locaux des statistiques de lecture
  
  5. localNotificationScheduler()
     → Rappels locaux (complément aux push FCM)
     → Package : flutter_local_notifications

CUSTOM WIDGETS FlutterFlow :
  1. ShelfVisualizer → affichage étagère 3D/2D des livres
  2. ReadingProgressArc → arc de cercle animé (progression)
  3. SpotifyWrappedCards → carrousel animé pour le bilan annuel
  4. BookMatchIndicator → jauge de compatibilité reco (0-100%)

API CALLS dans FlutterFlow :
  - Configurer les appels Cloud Functions comme API calls
  - Utiliser les API Groups FlutterFlow pour organiser :
    → Group "Scan" : onShelfScan, enrichBook
    → Group "Social" : computeMatchScore, generateRecoMessage
    → Group "Notifications" : sendExternalNotification

STATE MANAGEMENT FlutterFlow :
  - App State : utilisateur connecté, thème, paramètres globaux
  - Page State : filtres de recherche, livre sélectionné, onglet actif
  - Component State : rating en cours, formulaire d'avis
  - Firestore streams : données temps réel (prêts, notifications, progression)

OFFLINE SUPPORT :
  - Firestore persistence activée (cache local automatique)
  - Les livres et avis sont disponibles hors-ligne
  - Les scans sont mis en queue et traités au retour du réseau
  - Sync automatique Firebase ↔ cache local
```

---

## 📋 PLAN D'IMPLÉMENTATION SUGGÉRÉ

```
PHASE 0 — Fondations (2 semaines)
  ✅ Setup repo GitHub "biblioshare" + structure docs/
  ✅ Setup Firebase (Auth, Firestore, Storage, FCM, Functions)
  ✅ Créer le projet FlutterFlow "BiblioShare"
  ✅ Connexion FlutterFlow ↔ Firebase
  ✅ Thème, design system, composants de base
  ✅ README.md + architecture.md + getting-started.md
  ✅ CI/CD : Firebase deploy automatique

PHASE 1 — Auth, Profil & Onboarding (2 semaines)
  ✅ Auth téléphone (OTP SMS) — méthode principale
  ✅ Auth email (magic link + mot de passe)
  ✅ Auth social (Google, Apple)
  ✅ Auth anonyme (emprunteurs invités) + linkWithCredential
  ✅ Onboarding 4 écrans (langue, scan, invitation)
  ✅ Page profil complet (avatar, bio, stats, genres)
  ✅ Page paramètres complète (langue, notifications, confidentialité, etc.)
  ✅ Édition du profil
  ✅ 📖 Doc : modules/01 + modules/02

PHASE 2 — Scan & Enrichissement (4 semaines)
  ✅ Scan d'étagère + OCR via Claude Vision API
  ✅ Enrichissement Google Books + Open Library
  ✅ Validation manuelle par l'utilisateur
  ✅ Bibliothèque personnelle (CRUD, grille/liste/étagère)
  ✅ Scan ISBN code-barre (ML Kit) en fallback
  ✅ 📖 Doc : modules/03 + modules/04 + api/

PHASE 3 — Avis & Journal (2 semaines)
  ✅ Flow post-lecture (note globale + 6 sous-notes)
  ✅ Avis texte + tags personnels + notes privées
  ✅ Journal de progression (page courante, %, streak)
  ✅ Annotations et citations favorites
  ✅ Stats de lecture et objectifs annuels
  ✅ 📖 Doc : modules/05

PHASE 4 — Social & Invitations (3 semaines)
  ✅ Système d'amis (ajout, acceptation, groupes)
  ✅ Invitation par SMS (Twilio + Dynamic Links)
  ✅ Invitation par email (SendGrid + template HTML)
  ✅ Invitation par lien / QR code
  ✅ Recherche de contacts déjà inscrits
  ✅ Tracking des invitations + badges
  ✅ Visibilité bibliothèque par les amis
  ✅ Recherche croisée + wishlist partagée
  ✅ Fil d'activité social
  ✅ 📖 Doc : modules/06

PHASE 5 — Recommandations actives (3 semaines)
  ✅ Flow "je recommande" post-lecture avec matching IA
  ✅ Messages personnalisés (manuels + assistés par Claude)
  ✅ Réception et actions côté destinataire
  ✅ Suivi des recos + dashboard + alertes
  ✅ Triggers automatiques (wishlist, thématique, anniversaire)
  ✅ Discussions entre amis autour d'un livre (threads + spoilers)
  ✅ 📖 Doc : modules/07

PHASE 6 — Prêts & Alertes (3 semaines)
  ✅ Workflow complet de prêt (demande → retour)
  ✅ Lien reco → prêt ("Je te le prête !")
  ✅ Prêt à non-inscrit via SMS (auth anonyme)
  ✅ Notifications push (FCM) + email (SendGrid) + SMS (Twilio)
  ✅ Alertes de retard avec escalade automatique
  ✅ Dashboard prêts en cours (propriétaire + emprunteur)
  ✅ 📖 Doc : modules/08

PHASE 7 — Polish, Growth & Documentation finale (2 semaines)
  ✅ "Reading Wrapped" de fin d'année (style Spotify)
  ✅ Badges et gamification
  ✅ Multi-scan amélioré (panorama)
  ✅ Mode hors-ligne (Firestore persistence)
  ✅ Import/Export bibliothèque (CSV, Goodreads, Babelio)
  ✅ i18n : traductions FR + EN complètes
  ✅ Guide utilisateur in-app (FAQ, tooltips, états vides)
  ✅ 📖 Doc finale : relecture complète, screenshots, user-guide/
  ✅ Soumission App Store + Play Store
```

---

## 🚀 COMMANDE DE LANCEMENT

```
REPO GITHUB : biblioshare

Pour démarrer avec FlutterFlow, exécute dans l'ordre :

ÉTAPE 0 — SETUP REPO & FIREBASE
  1. Cloner le repo "biblioshare"
  2. Créer la structure de dossiers docs/ telle que décrite (Module 9.2)
  3. Créer le README.md avec le template (Module 9.3)
  4. Créer un projet Firebase "biblioshare"
  5. Activer Auth : Phone, Email/Password, Email Link, Google, Apple, Anonymous
  6. Créer la base Firestore avec les collections (voir Module 2.3 et archi)
  7. Configurer les Firestore Rules (sécurité)
  8. Configurer Firebase Storage (buckets : scans, covers, loans, avatars, annotations)
  9. Activer Cloud Messaging (FCM)
  10. Initialiser le dossier firebase/functions/ (Node.js TypeScript)
  11. Documenter chaque étape dans docs/getting-started.md

ÉTAPE 1 — PROJET FLUTTERFLOW
  1. Créer le projet FlutterFlow "BiblioShare"
  2. Connecter Firebase (Auth + Firestore + Storage + FCM)
  3. Définir le thème Material 3 (couleurs, typo, coins arrondis, ombres)
  4. Créer les composants réutilisables (BookCard, StarRating, LoanBadge, etc.)
  5. Configurer les API Groups (Scan, Social, Notifications)
  6. Configurer l'i18n (FR par défaut, EN en second)
  7. Documenter dans docs/flutterflow/

ÉTAPE 2 — AUTH & PROFIL (Module 1 + 2)
  1. Implémenter l'écran de connexion (téléphone OTP en premier)
  2. Implémenter les autres méthodes d'auth
  3. Créer le flow d'onboarding (4 écrans)
  4. Créer la page profil + édition
  5. Créer la page paramètres complète
  6. Auth anonyme pour les liens de prêt
  7. Tester sur iOS + Android + Web
  8. Documenter dans docs/modules/01 + 02

ÉTAPE 3 — MODULES FONCTIONNELS (Modules 3 → 8)
  Pour chaque module, dans l'ordre :
  - Créer / mettre à jour les collections Firestore + rules
  - Coder et déployer les Cloud Functions associées
  - Construire les pages FlutterFlow
  - Ajouter les Custom Actions Dart si nécessaire
  - Écrire les tests
  - Tester sur iOS + Android + Web
  - ⚠️ DOCUMENTER dans docs/modules/{N} AVANT de passer au suivant

ÉTAPE 4 — CUSTOM CODE (si nécessaire)
  Exporter le projet Flutter depuis FlutterFlow pour :
  - Les Custom Widgets avancés (ShelfVisualizer, WrappedCards)
  - L'intégration ML Kit (barcode + OCR on-device)
  - L'overlay caméra personnalisé
  - Réimporter dans FlutterFlow après modifications
  - Documenter dans docs/flutterflow/custom-actions.md + custom-widgets.md

ÉTAPE 5 — DOCUMENTATION FINALE
  - Relire et compléter toute la doc
  - Ajouter des screenshots dans assets/screenshots/
  - Rédiger le guide utilisateur (FR + EN)
  - Vérifier le CHANGELOG.md
  - Mettre à jour le README.md avec les statuts des modules

IMPORTANT — LIMITES FLUTTERFLOW À ANTICIPER :
  ⚠️ La caméra avec overlay custom nécessite du code Dart (Custom Action)
  ⚠️ ML Kit barcode scanning = Custom Action obligatoire
  ⚠️ Les animations complexes (Wrapped, étagère 3D) = Custom Widgets
  ⚠️ Les Cloud Functions se codent hors FlutterFlow (dans Firebase Console
      ou via CLI : firebase deploy --only functions)
  ⚠️ Les Firestore Rules se configurent dans Firebase Console
  ⚠️ Pour les requêtes complexes (recherche croisée multi-amis),
      privilégier les Cloud Functions plutôt que des queries Firestore client
  ⚠️ L'auth téléphone (OTP) nécessite une configuration spécifique
      dans Firebase Console + SHA-1 pour Android + APN pour iOS

RAPPEL — DOCUMENTATION OBLIGATOIRE :
  📖 Chaque module terminé = sa doc à jour dans docs/modules/
  📖 Chaque Cloud Function = JSDoc complet (voir template Module 9.5)
  📖 Chaque Custom Action = DartDoc
  📖 Chaque collection Firestore = documentée dans docs/firebase/firestore-schema.md
  📖 Pas de module "terminé" sans doc. Pas d'exception.
```
