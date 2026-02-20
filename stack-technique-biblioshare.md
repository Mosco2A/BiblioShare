# 🏗️ BiblioShare — Recommandation Stack Technique
## Pallier les limites de FlutterFlow avec une architecture hybride

---

## 📋 RÉSUMÉ EXÉCUTIF

FlutterFlow est parfait pour prototyper vite et construire 70-80% de l'app en no-code. Mais BiblioShare a des besoins qui dépassent le no-code pur : scan par caméra avec overlay, OCR en temps réel, matching IA, notifications complexes, recherches croisées entre bibliothèques...

**Ma recommandation : une architecture hybride en 3 couches.**

```
┌─────────────────────────────────────────────────────────┐
│                    COUCHE 1 — UI                         │
│              FlutterFlow (no-code)                       │
│    80% des écrans, navigation, formulaires, listes       │
│    + Custom Widgets & Actions en Dart pour le reste      │
├─────────────────────────────────────────────────────────┤
│                  COUCHE 2 — BACKEND                      │
│         Supabase (PostgreSQL) + Firebase (Auth/FCM)      │
│    Données relationnelles + Auth téléphone + Push        │
│    + Edge Functions (logique serveur)                    │
├─────────────────────────────────────────────────────────┤
│                  COUCHE 3 — SERVICES                     │
│         Claude API + Google Books + Twilio + SendGrid    │
│    IA Vision + Enrichissement + SMS + Email              │
└─────────────────────────────────────────────────────────┘
```

---

## 🔍 LES 8 LIMITES DE FLUTTERFLOW POUR BIBLIOSHARE

Voici les limites concrètes identifiées et comment les résoudre :

### LIMITE 1 — Caméra avec overlay personnalisé
```
❌ PROBLÈME :
FlutterFlow ne permet pas de superposer un guide de cadrage
sur la vue caméra. Le widget caméra natif est basique.

✅ SOLUTION : Custom Widget Dart
→ Créer un widget Flutter custom utilisant le package `camera`
→ Superposer un overlay semi-transparent avec un cadre guide
→ Ajouter un bouton de capture custom
→ Retourner l'image en bytes au flow FlutterFlow

📦 Packages : camera, image_picker
🔧 Effort : 1-2 jours
```

### LIMITE 2 — OCR et scan de code-barre on-device
```
❌ PROBLÈME :
FlutterFlow n'intègre pas nativement Google ML Kit.
Pas de scan de code-barre ni d'OCR en temps réel.

✅ SOLUTION : Custom Action Dart
→ Custom Action qui appelle google_mlkit_barcode_scanning
→ Custom Action qui appelle google_mlkit_text_recognition
→ Fonctionnent hors-ligne, directement sur le device
→ Résultats retournés comme String/JSON au flow FlutterFlow

📦 Packages : google_mlkit_barcode_scanning, google_mlkit_text_recognition
🔧 Effort : 2-3 jours
```

### LIMITE 3 — Requêtes relationnelles complexes
```
❌ PROBLÈME :
Firestore (NoSQL) est nul pour les requêtes croisées :
- "Qui parmi mes amis a ce livre ?"
- "Livres en commun avec Sophie"
- "Top livres les mieux notés par mes amis"
- Jointures, agrégations, GROUP BY → impossible en NoSQL

FlutterFlow ne supporte qu'un niveau de sous-collection Firestore.
Les recherches croisées nécessitent de multiples queries côté client
= lent, coûteux (lectures Firestore facturées), et fragile.

✅ SOLUTION : Remplacer Firestore par Supabase (PostgreSQL)
→ PostgreSQL = requêtes SQL natives avec JOIN, GROUP BY, HAVING
→ Row-Level Security (RLS) = sécurité au niveau de chaque ligne
→ Une seule requête pour "livres de mes amis notés 4+" au lieu de
   dizaines de lectures Firestore
→ FlutterFlow supporte Supabase nativement (intégration officielle)
→ Coûts prévisibles (pas de facturation à la lecture)

Exemple concret :
  "Livres en commun avec Sophie" =
  SELECT b.* FROM books b
  JOIN books b2 ON b.isbn = b2.isbn
  WHERE b.user_id = 'moi' AND b2.user_id = 'sophie'

  En Firestore : lire TOUS mes livres + TOUS les livres de Sophie
  + comparer côté client = 500+ lectures = cher et lent
```

### LIMITE 4 — Logique serveur complexe (IA, matching, CRON)
```
❌ PROBLÈME :
FlutterFlow n'a pas de backend serveur. Les Cloud Functions Firebase
fonctionnent mais sont verbeuses, cold-start lent (Node.js),
et difficiles à débugger.

✅ SOLUTION : Supabase Edge Functions (Deno/TypeScript)
→ Démarrage instantané (pas de cold start)
→ Accès SQL direct à la base (pas besoin d'ORM)
→ Déployables en 1 commande (supabase functions deploy)
→ TypeScript natif

+ POUR LES CRON JOBS : Supabase pg_cron (natif PostgreSQL)
→ Rappels de prêt, résumé hebdomadaire, etc.
→ Pas besoin de scheduler externe
→ Exemple : SELECT cron.schedule('loan-reminders', '0 * * * *',
  $$ SELECT check_overdue_loans() $$);

+ GARDER Firebase Cloud Functions UNIQUEMENT pour :
→ Firebase Auth triggers (onUserCreate)
→ Firebase Cloud Messaging (FCM) pour les push
→ Tout ce qui est spécifique à l'écosystème Google
```

### LIMITE 5 — Animations et widgets visuels avancés
```
❌ PROBLÈME :
FlutterFlow supporte Lottie et les animations basiques,
mais pas les visualisations custom comme :
- Étagère 3D interactive
- "Reading Wrapped" style Spotify (carrousel animé)
- Jauge de compatibilité animée
- Graphiques de stats personnalisés

✅ SOLUTION : Custom Widgets Flutter
→ Écrire des widgets Flutter/Dart custom
→ Utiliser les packages : fl_chart, lottie, rive
→ Les importer dans FlutterFlow comme Custom Widgets
→ Ils s'intègrent dans les pages FlutterFlow normalement

📦 Packages : fl_chart, rive, lottie, flutter_animate
🔧 Effort : 3-5 jours pour l'ensemble
```

### LIMITE 6 — Gestion fine de l'état (state management)
```
❌ PROBLÈME :
FlutterFlow utilise un state management simplifié (App State, Page State).
Pour des flux complexes comme le workflow de prêt (10 statuts possibles)
ou le suivi temps réel de la progression de lecture, c'est limité.

✅ SOLUTION : Supabase Realtime + Custom Actions
→ Supabase Realtime = écouter les changements de la DB en temps réel
  (comme Firestore listeners, mais avec PostgreSQL)
→ Custom Actions Dart pour la logique d'état complexe
→ Provider/Riverpod si export Flutter nécessaire plus tard
→ Pour le MVP : le state management FlutterFlow suffit à 90%
```

### LIMITE 7 — Authentification téléphone
```
❌ PROBLÈME :
Supabase ne supporte pas nativement l'auth par téléphone (OTP SMS)
aussi bien que Firebase. L'intégration FlutterFlow + Supabase Auth
est moins mature que Firebase Auth.

✅ SOLUTION HYBRIDE : Firebase Auth + Supabase Data
→ GARDER Firebase Auth pour :
  - Auth téléphone (OTP SMS) — mature, fiable, intégré FlutterFlow
  - Google Sign-In, Apple Sign-In
  - Auth anonyme (pour les emprunteurs invités)
→ UTILISER Supabase pour :
  - Toutes les données (livres, prêts, avis, amis...)
  - Edge Functions (logique serveur)
  - Storage (photos de scan, couvertures)

→ PONT : Synchroniser le Firebase UID dans Supabase
  Quand un user se connecte via Firebase Auth :
  1. Firebase Auth délivre un JWT
  2. Custom Action appelle Supabase avec ce JWT
  3. Supabase vérifie le JWT et crée/lie le user
  4. Toutes les requêtes Supabase utilisent le Firebase UID

  Cela se fait avec une Edge Function "sync-user" et les
  Supabase JWT custom claims.
```

### LIMITE 8 — Vendor lock-in et export
```
❌ PROBLÈME :
Si FlutterFlow change ses prix, ses features, ou disparaît,
on est coincé. Le code exporté est fonctionnel mais verbeux
et difficile à maintenir sans FlutterFlow.

✅ SOLUTION : Architecture découplée
→ Toute la logique métier est dans Supabase (SQL + Edge Functions)
  = indépendant de FlutterFlow, portable, testable
→ Les données sont dans PostgreSQL (standard ouvert, exportable)
→ Les Custom Widgets/Actions sont du Flutter pur = portables
→ Si migration nécessaire : exporter le code Flutter de FlutterFlow
  et continuer en Flutter pur, la DB et la logique ne changent pas
→ Supabase est open-source : auto-hébergeable si nécessaire
```

---

## 🏆 STACK RECOMMANDÉE FINALE

```
╔═══════════════════════════════════════════════════════════╗
║              STACK BIBLIOSHARE — HYBRIDE                  ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  📱 FRONTEND                                              ║
║  ├── FlutterFlow (UI builder principal, 80% des pages)    ║
║  ├── Custom Widgets Dart (caméra, étagère 3D, charts)     ║
║  ├── Custom Actions Dart (ML Kit, base64, state logic)    ║
║  └── Export Flutter possible si besoin de migrer          ║
║                                                           ║
║  🔐 AUTHENTIFICATION                                      ║
║  ├── Firebase Auth (téléphone OTP, Google, Apple, anonyme)║
║  ├── Intégration native FlutterFlow                       ║
║  └── JWT synchronisé avec Supabase                        ║
║                                                           ║
║  🗄️ BASE DE DONNÉES                                       ║
║  ├── Supabase (PostgreSQL)                                ║
║  ├── Données relationnelles (livres, prêts, amis, avis)   ║
║  ├── Row-Level Security (sécurité par ligne)              ║
║  ├── Requêtes SQL complexes (jointures, agrégations)      ║
║  ├── Realtime (écoute des changements en temps réel)      ║
║  └── pg_cron (tâches planifiées : rappels, wrapped...)    ║
║                                                           ║
║  ⚡ LOGIQUE SERVEUR                                       ║
║  ├── Supabase Edge Functions (Deno/TypeScript)            ║
║  │   ├── scan-shelf (appel Claude Vision API)             ║
║  │   ├── enrich-book (Google Books + Open Library)        ║
║  │   ├── compute-match-score (matching reco)              ║
║  │   ├── generate-reco-message (appel Claude texte)       ║
║  │   ├── send-sms-invite (appel Twilio)                   ║
║  │   ├── send-email-invite (appel SendGrid)               ║
║  │   └── check-overdue-loans (rappels automatiques)       ║
║  ├── Firebase Cloud Functions (UNIQUEMENT pour)           ║
║  │   ├── onUserCreate → sync user dans Supabase           ║
║  │   └── Envoi push notifications FCM                     ║
║  └── Supabase Database Functions (PL/pgSQL)               ║
║      ├── Triggers (on_book_finished → update stats)       ║
║      └── Views matérialisées (stats, classements)         ║
║                                                           ║
║  📦 STOCKAGE                                              ║
║  └── Supabase Storage                                     ║
║      ├── scans/ (photos d'étagères)                       ║
║      ├── covers/ (couvertures de livres)                  ║
║      ├── loans/ (photos avant/après prêt)                 ║
║      ├── annotations/ (photos de passages)                ║
║      └── avatars/ (photos de profil)                      ║
║                                                           ║
║  🔔 NOTIFICATIONS                                         ║
║  ├── Firebase Cloud Messaging (push iOS + Android)        ║
║  ├── SendGrid (emails transactionnels + invitations)      ║
║  └── Twilio (SMS : OTP fallback, invitations, prêts)      ║
║                                                           ║
║  🤖 IA & VISION                                           ║
║  ├── Claude API Sonnet 4.5 (analyse photo étagère)        ║
║  ├── Claude API Sonnet 4.5 (génération messages reco)     ║
║  └── Google ML Kit on-device (barcode + OCR fallback)     ║
║                                                           ║
║  📚 ENRICHISSEMENT                                        ║
║  ├── Google Books API (gratuit, 1000 req/jour)            ║
║  ├── Open Library API (gratuit, illimité)                 ║
║  └── ISBNdb (payant, fallback premium)                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

---

## 💰 COMPARAISON DES COÛTS

```
FIREBASE SEUL (stack actuelle dans le prompt) :
  Auth          : gratuit (10K SMS/mois inclus)
  Firestore     : 0,06$/100K lectures, 0,18$/100K écritures
                  ⚠️ Explose vite avec les recherches croisées
                  → Estimation BiblioShare 1000 users actifs : 50-150$/mois
  Storage       : 0,026$/GB/mois
  Functions     : 0,40$/million invocations
  FCM           : gratuit
  TOTAL estimé  : 80-200$/mois à 1000 users

SUPABASE + FIREBASE AUTH (stack recommandée) :
  Supabase Pro  : 25$/mois (8 Go DB, 250 Go bandwidth, 100 Go storage)
                  → Largement suffisant pour 1000-10000 users
                  → Requêtes SQL illimitées (pas facturées à la lecture !)
  Firebase Auth : gratuit (10K SMS/mois)
  Firebase FCM  : gratuit
  CF Firebase   : ~5$/mois (juste sync user + envoi push)
  SendGrid      : gratuit (100 emails/jour) ou 20$/mois (50K emails)
  Twilio        : ~0,05€/SMS
  Claude API    : ~0,01$/scan (Sonnet)
  TOTAL estimé  : 30-60$/mois à 1000 users ← 2-3x moins cher

ÉCONOMIE PRINCIPALE :
  Firestore facture chaque lecture de document.
  "Qui parmi mes 50 amis a ce livre ?" = 50+ lectures minimum.
  Avec PostgreSQL : 1 requête SQL, coût fixe.
```

---

## 🔄 MATRICE DE DÉCISION — OÙ VA QUOI ?

```
┌──────────────────────────┬──────────────┬──────────────┬──────────────┐
│ Fonctionnalité           │ FlutterFlow  │ Custom Dart  │ Serveur      │
│                          │ (no-code)    │ (dans FF)    │ (Supabase)   │
├──────────────────────────┼──────────────┼──────────────┼──────────────┤
│ Pages UI / navigation    │ ✅            │              │              │
│ Formulaires / listes     │ ✅            │              │              │
│ Auth (téléphone, social) │ ✅ (Firebase) │              │              │
│ CRUD livres basique      │ ✅            │              │              │
│ Thème / i18n             │ ✅            │              │              │
│ Caméra + overlay         │              │ ✅            │              │
│ Scan code-barre (ML Kit) │              │ ✅            │              │
│ OCR on-device            │              │ ✅            │              │
│ Image → base64           │              │ ✅            │              │
│ Widgets animés (charts)  │              │ ✅            │              │
│ Étagère 3D               │              │ ✅            │              │
│ Analyse photo (Claude)   │              │              │ ✅ Edge Fn   │
│ Enrichissement livres    │              │              │ ✅ Edge Fn   │
│ Recherches croisées      │              │              │ ✅ SQL       │
│ Matching reco (scoring)  │              │              │ ✅ SQL + Fn  │
│ Génération msg reco      │              │              │ ✅ Edge Fn   │
│ Rappels de prêt (CRON)   │              │              │ ✅ pg_cron   │
│ Envoi SMS (invit/prêt)   │              │              │ ✅ Edge Fn   │
│ Envoi email              │              │              │ ✅ Edge Fn   │
│ Push notifications       │              │              │ ✅ CF Firebase│
│ Stats / wrapped          │              │              │ ✅ SQL views │
│ Sécurité données         │              │              │ ✅ RLS       │
└──────────────────────────┴──────────────┴──────────────┴──────────────┘
```

---

## 📊 SCHÉMA SUPABASE (remplace les collections Firestore)

```sql
-- ════════════════════════════════════════
-- SCHÉMA PRINCIPAL BIBLIOSHARE
-- Base PostgreSQL sur Supabase
-- ════════════════════════════════════════

-- Utilisateurs (synchronisés depuis Firebase Auth)
CREATE TABLE users (
  id UUID PRIMARY KEY,                    -- = Firebase UID
  display_name TEXT NOT NULL,
  username TEXT UNIQUE NOT NULL,
  email TEXT,
  phone TEXT,
  photo_url TEXT,
  bio TEXT CHECK (length(bio) <= 280),
  location TEXT,
  preferred_genres TEXT[],
  external_link TEXT,
  locale TEXT DEFAULT 'fr',
  timezone TEXT DEFAULT 'Europe/Paris',
  auth_providers TEXT[],                  -- ['phone', 'google']
  onboarding_completed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Paramètres utilisateur (1:1 avec users)
CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  -- Notifications
  notif_push BOOLEAN DEFAULT true,
  notif_email BOOLEAN DEFAULT true,
  notif_sms BOOLEAN DEFAULT false,
  notif_loans BOOLEAN DEFAULT true,
  notif_reminders BOOLEAN DEFAULT true,
  notif_recos BOOLEAN DEFAULT true,
  notif_social BOOLEAN DEFAULT true,
  notif_streak BOOLEAN DEFAULT true,
  notif_weekly_summary BOOLEAN DEFAULT true,
  reminder_frequency_days INTEGER DEFAULT 3,
  -- Confidentialité
  default_library_visibility TEXT DEFAULT 'friends'
    CHECK (default_library_visibility IN ('private', 'friends', 'public')),
  default_review_visibility TEXT DEFAULT 'friends',
  profile_visibility TEXT DEFAULT 'public',
  find_by_phone TEXT DEFAULT 'everyone',
  find_by_email TEXT DEFAULT 'everyone',
  -- Bibliothèque
  default_loan_days INTEGER DEFAULT 30,
  max_loans_per_friend INTEGER DEFAULT 3,
  auto_reminders BOOLEAN DEFAULT true,
  reminder_tone TEXT DEFAULT 'friendly'
    CHECK (reminder_tone IN ('friendly', 'neutral', 'firm')),
  -- App
  theme TEXT DEFAULT 'system'
    CHECK (theme IN ('light', 'dark', 'system')),
  library_display TEXT DEFAULT 'grid'
    CHECK (library_display IN ('grid', 'list', 'shelf')),
  search_languages TEXT[] DEFAULT ARRAY['fr', 'en']
);

-- Livres (exemplaire possédé par un utilisateur)
CREATE TABLE books (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  -- Identification
  isbn_10 TEXT,
  isbn_13 TEXT,
  title TEXT NOT NULL,
  original_title TEXT,
  subtitle TEXT,
  authors JSONB NOT NULL DEFAULT '[]',     -- [{name, role}]
  publisher TEXT,
  collection TEXT,
  publication_date DATE,
  language TEXT DEFAULT 'fr',
  -- Détails physiques
  page_count INTEGER,
  format TEXT,                              -- 'poche', 'grand_format', 'epub'
  -- Contenu
  description TEXT,
  genres TEXT[],
  themes TEXT[],
  keywords TEXT[],
  cover_url TEXT,
  -- Communauté
  goodreads_rating DECIMAL(3,2),
  babelio_rating DECIMAL(3,2),
  -- Possession
  condition TEXT DEFAULT 'good',
  non_lendable BOOLEAN DEFAULT false,
  date_added TIMESTAMPTZ DEFAULT now(),
  -- Scan
  scan_confidence INTEGER,
  scan_photo_url TEXT,
  shelf_position JSONB,                     -- {shelf: 2, position: 7}
  -- Recherche full-text
  search_vector TSVECTOR GENERATED ALWAYS AS (
    to_tsvector('french', coalesce(title, '') || ' ' || coalesce(subtitle, '') ||
    ' ' || coalesce(description, ''))
  ) STORED
);

CREATE INDEX idx_books_user ON books(user_id);
CREATE INDEX idx_books_isbn ON books(isbn_13);
CREATE INDEX idx_books_search ON books USING GIN(search_vector);

-- Avis & notes
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
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
  visibility TEXT DEFAULT 'friends'
    CHECK (visibility IN ('private', 'friends', 'public')),
  tags TEXT[],
  private_notes TEXT,
  -- Lecture
  reading_status TEXT DEFAULT 'unread'
    CHECK (reading_status IN ('unread', 'reading', 'finished', 'abandoned')),
  current_page INTEGER,
  started_at DATE,
  finished_at DATE,
  -- Méta
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, book_id)
);

-- Annotations de lecture
CREATE TABLE annotations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  page_number INTEGER,
  chapter TEXT,
  type TEXT NOT NULL CHECK (type IN ('note', 'quote', 'mood', 'photo')),
  content TEXT,
  mood_emoji TEXT,
  photo_url TEXT,
  visibility TEXT DEFAULT 'private',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Amitiés
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES users(id),
  receiver_id UUID NOT NULL REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'blocked')),
  source TEXT DEFAULT 'search'
    CHECK (source IN ('search', 'invite_sms', 'invite_email', 'invite_link', 'qr_code')),
  group_tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT now(),
  accepted_at TIMESTAMPTZ,
  CHECK (requester_id != receiver_id)
);

CREATE UNIQUE INDEX idx_friendship_pair
  ON friendships(LEAST(requester_id, receiver_id), GREATEST(requester_id, receiver_id))
  WHERE status != 'blocked';

-- Invitations
CREATE TABLE invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inviter_id UUID NOT NULL REFERENCES users(id),
  channel TEXT NOT NULL CHECK (channel IN ('sms', 'email', 'link', 'qr')),
  recipient_phone TEXT,
  recipient_email TEXT,
  status TEXT NOT NULL DEFAULT 'sent'
    CHECK (status IN ('sent', 'clicked', 'registered', 'expired')),
  registered_user_id UUID REFERENCES users(id),
  sent_at TIMESTAMPTZ DEFAULT now(),
  clicked_at TIMESTAMPTZ,
  registered_at TIMESTAMPTZ
);

-- Prêts
CREATE TABLE loans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id UUID NOT NULL REFERENCES books(id),
  owner_id UUID NOT NULL REFERENCES users(id),
  borrower_id UUID REFERENCES users(id),
  borrower_external JSONB,                  -- {name, phone, email}
  status TEXT NOT NULL DEFAULT 'requested'
    CHECK (status IN (
      'requested', 'accepted', 'active', 'extension_requested',
      'overdue', 'return_pending', 'returned', 'disputed', 'cancelled'
    )),
  lent_at TIMESTAMPTZ,
  due_date DATE,
  original_due_date DATE,
  returned_at TIMESTAMPTZ,
  confirmed_returned_at TIMESTAMPTZ,
  condition_before TEXT,
  condition_after TEXT,
  photo_before_url TEXT,
  photo_after_url TEXT,
  notes TEXT,
  reminder_count INTEGER DEFAULT 0,
  escalation_level INTEGER DEFAULT 0,
  last_reminder_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Messages de prêt (chat)
CREATE TABLE loan_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id),
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Recommandations
CREATE TABLE recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES users(id),
  receiver_id UUID NOT NULL REFERENCES users(id),
  book_id UUID NOT NULL REFERENCES books(id),
  message_text TEXT,
  ai_generated BOOLEAN DEFAULT false,
  includes_loan_offer BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'sent'
    CHECK (status IN (
      'sent', 'seen', 'wishlisted', 'borrowed', 'reading',
      'finished', 'declined_politely', 'expired'
    )),
  match_score INTEGER,
  match_reasons TEXT[],
  trigger_type TEXT DEFAULT 'manual'
    CHECK (trigger_type IN (
      'manual', 'post_review', 'wishlist_match',
      'thematic_match', 'birthday', 'social_trend'
    )),
  sent_via TEXT DEFAULT 'in_app',
  receiver_rating DECIMAL(2,1),
  created_at TIMESTAMPTZ DEFAULT now(),
  seen_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ
);

-- Discussions autour d'un livre
CREATE TABLE book_discussions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id UUID NOT NULL REFERENCES books(id),
  participants UUID[] NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE discussion_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id UUID NOT NULL REFERENCES book_discussions(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id),
  content TEXT NOT NULL,
  spoiler BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  data JSONB,
  channel TEXT DEFAULT 'push'
    CHECK (channel IN ('push', 'email', 'sms', 'in_app')),
  status TEXT DEFAULT 'pending'
    CHECK (status IN ('pending', 'sent', 'read', 'dismissed')),
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, status);

-- Fil d'activité social
CREATE TABLE social_feed (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  action_type TEXT NOT NULL,
  book_id UUID REFERENCES books(id),
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Objectifs de lecture
CREATE TABLE reading_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  year INTEGER NOT NULL,
  target_books INTEGER DEFAULT 12,
  current_books INTEGER DEFAULT 0,
  UNIQUE(user_id, year)
);

-- Wishlist
CREATE TABLE wishlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  isbn_13 TEXT,
  title TEXT NOT NULL,
  author TEXT,
  cover_url TEXT,
  added_from TEXT,                          -- 'manual', 'recommendation', 'friend_library'
  source_user_id UUID REFERENCES users(id), -- qui a recommandé
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ════════════════════════════════════════
-- VUES UTILES (requêtes complexes pré-calculées)
-- ════════════════════════════════════════

-- Livres de mes amis
CREATE VIEW v_friends_books AS
SELECT
  f.requester_id AS user_id,
  b.*,
  u.display_name AS owner_name,
  u.photo_url AS owner_photo
FROM friendships f
JOIN books b ON b.user_id = f.receiver_id
JOIN users u ON u.id = f.receiver_id
WHERE f.status = 'accepted'
UNION ALL
SELECT
  f.receiver_id AS user_id,
  b.*,
  u.display_name AS owner_name,
  u.photo_url AS owner_photo
FROM friendships f
JOIN books b ON b.user_id = f.requester_id
JOIN users u ON u.id = f.requester_id
WHERE f.status = 'accepted';

-- Stats utilisateur (vue matérialisée, refresh périodique)
CREATE MATERIALIZED VIEW mv_user_stats AS
SELECT
  u.id AS user_id,
  COUNT(DISTINCT b.id) AS total_books,
  COUNT(DISTINCT r.id) FILTER (WHERE r.reading_status = 'finished') AS books_read,
  ROUND(AVG(r.rating_global) FILTER (WHERE r.rating_global IS NOT NULL), 1) AS avg_rating,
  MODE() WITHIN GROUP (ORDER BY unnest(b.genres)) AS top_genre,
  COUNT(DISTINCT l.id) FILTER (WHERE l.status = 'active') AS active_loans_out,
  COUNT(DISTINCT l2.id) FILTER (WHERE l2.status = 'active') AS active_loans_in
FROM users u
LEFT JOIN books b ON b.user_id = u.id
LEFT JOIN reviews r ON r.user_id = u.id
LEFT JOIN loans l ON l.owner_id = u.id
LEFT JOIN loans l2 ON l2.borrower_id = u.id
GROUP BY u.id;

-- ════════════════════════════════════════
-- ROW-LEVEL SECURITY (RLS)
-- ════════════════════════════════════════

ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendations ENABLE ROW LEVEL SECURITY;

-- Un user voit ses propres livres
CREATE POLICY "Users can see own books"
  ON books FOR SELECT USING (user_id = auth.uid());

-- Un user voit les livres de ses amis (si visibilité >= friends)
CREATE POLICY "Users can see friends books"
  ON books FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM friendships f
      WHERE f.status = 'accepted'
      AND ((f.requester_id = auth.uid() AND f.receiver_id = books.user_id)
        OR (f.receiver_id = auth.uid() AND f.requester_id = books.user_id))
    )
  );

-- Un user ne modifie que ses propres livres
CREATE POLICY "Users can modify own books"
  ON books FOR ALL USING (user_id = auth.uid());

-- Les prêts sont visibles par owner et borrower
CREATE POLICY "Loan parties can see loans"
  ON loans FOR SELECT USING (
    owner_id = auth.uid() OR borrower_id = auth.uid()
  );
```

---

## 🚦 MIGRATION DEPUIS LE PROMPT ACTUEL

```
Si tu as déjà commencé avec Firebase/Firestore :

PHASE 1 : Ajouter Supabase en parallèle
  → Créer le projet Supabase
  → Créer le schéma SQL ci-dessus
  → Configurer la connexion FlutterFlow → Supabase
  → Les nouvelles features utilisent Supabase

PHASE 2 : Migrer les données existantes
  → Exporter Firestore → JSON
  → Transformer JSON → SQL INSERT
  → Importer dans Supabase
  → Tester

PHASE 3 : Supprimer Firestore
  → Rediriger toutes les queries vers Supabase
  → Garder Firebase Auth + FCM uniquement
  → Supprimer les collections Firestore

Si tu n'as PAS encore commencé :
  → Partir directement sur la stack hybride recommandée
  → C'est ton cas (repo vide) → GO 🚀
```
