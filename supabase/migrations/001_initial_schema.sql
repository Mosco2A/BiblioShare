-- ════════════════════════════════════════
-- BIBLIOSHARE — SCHÉMA INITIAL
-- PostgreSQL sur Supabase
-- ════════════════════════════════════════

-- ── Utilisateurs (synchronisés depuis Firebase Auth) ──

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

-- ── Paramètres utilisateur (1:1 avec users) ──

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
  default_review_visibility TEXT DEFAULT 'friends'
    CHECK (default_review_visibility IN ('private', 'friends', 'public')),
  profile_visibility TEXT DEFAULT 'public'
    CHECK (profile_visibility IN ('private', 'friends', 'public')),
  find_by_phone TEXT DEFAULT 'everyone'
    CHECK (find_by_phone IN ('nobody', 'friends', 'everyone')),
  find_by_email TEXT DEFAULT 'everyone'
    CHECK (find_by_email IN ('nobody', 'friends', 'everyone')),
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

-- ── Livres ──

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

-- ── Avis & notes ──

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

-- ── Annotations de lecture ──

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
  visibility TEXT DEFAULT 'private'
    CHECK (visibility IN ('private', 'friends', 'public')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ── Amitiés ──

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

-- ── Invitations ──

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

-- ── Prêts ──

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

-- ── Messages de prêt ──

CREATE TABLE loan_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id),
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ── Recommandations ──

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

-- ── Discussions autour d'un livre ──

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

-- ── Notifications ──

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

-- ── Fil d'activité social ──

CREATE TABLE social_feed (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  action_type TEXT NOT NULL,
  book_id UUID REFERENCES books(id),
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ── Objectifs de lecture ──

CREATE TABLE reading_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  year INTEGER NOT NULL,
  target_books INTEGER DEFAULT 12,
  current_books INTEGER DEFAULT 0,
  UNIQUE(user_id, year)
);

-- ── Wishlist ──

CREATE TABLE wishlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  isbn_13 TEXT,
  title TEXT NOT NULL,
  author TEXT,
  cover_url TEXT,
  added_from TEXT,                          -- 'manual', 'recommendation', 'friend_library'
  source_user_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ── Résultats de scan (historique) ──

CREATE TABLE scan_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  image_url TEXT,
  raw_analysis JSONB,
  book_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ════════════════════════════════════════
-- VUES
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

-- Stats utilisateur (vue matérialisée)
CREATE MATERIALIZED VIEW mv_user_stats AS
SELECT
  u.id AS user_id,
  COUNT(DISTINCT b.id) AS total_books,
  COUNT(DISTINCT r.id) FILTER (WHERE r.reading_status = 'finished') AS books_read,
  ROUND(AVG(r.rating_global) FILTER (WHERE r.rating_global IS NOT NULL), 1) AS avg_rating,
  COUNT(DISTINCT l.id) FILTER (WHERE l.status = 'active') AS active_loans_out,
  COUNT(DISTINCT l2.id) FILTER (WHERE l2.status = 'active') AS active_loans_in
FROM users u
LEFT JOIN books b ON b.user_id = u.id
LEFT JOIN reviews r ON r.user_id = u.id
LEFT JOIN loans l ON l.owner_id = u.id
LEFT JOIN loans l2 ON l2.borrower_id = u.id
GROUP BY u.id;

CREATE UNIQUE INDEX idx_mv_user_stats ON mv_user_stats(user_id);

-- ════════════════════════════════════════
-- ROW-LEVEL SECURITY (RLS)
-- ════════════════════════════════════════

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE annotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist ENABLE ROW LEVEL SECURITY;

-- Users : chacun voit et modifie son propre profil
CREATE POLICY "Users can read own profile"
  ON users FOR SELECT USING (id = auth.uid());
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE USING (id = auth.uid());

-- User settings
CREATE POLICY "Users can manage own settings"
  ON user_settings FOR ALL USING (user_id = auth.uid());

-- Books : voir ses propres livres
CREATE POLICY "Users can manage own books"
  ON books FOR ALL USING (user_id = auth.uid());

-- Books : voir les livres des amis
CREATE POLICY "Users can see friends books"
  ON books FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM friendships f
      WHERE f.status = 'accepted'
      AND ((f.requester_id = auth.uid() AND f.receiver_id = books.user_id)
        OR (f.receiver_id = auth.uid() AND f.requester_id = books.user_id))
    )
  );

-- Reviews
CREATE POLICY "Users can manage own reviews"
  ON reviews FOR ALL USING (user_id = auth.uid());

-- Annotations
CREATE POLICY "Users can manage own annotations"
  ON annotations FOR ALL USING (user_id = auth.uid());

-- Friendships : les deux parties peuvent voir
CREATE POLICY "Friendship parties can see"
  ON friendships FOR SELECT USING (
    requester_id = auth.uid() OR receiver_id = auth.uid()
  );
CREATE POLICY "Users can create friend requests"
  ON friendships FOR INSERT WITH CHECK (requester_id = auth.uid());
CREATE POLICY "Receiver can update friendship"
  ON friendships FOR UPDATE USING (receiver_id = auth.uid());

-- Loans : owner et borrower peuvent voir
CREATE POLICY "Loan parties can see loans"
  ON loans FOR SELECT USING (
    owner_id = auth.uid() OR borrower_id = auth.uid()
  );
CREATE POLICY "Owner can manage loans"
  ON loans FOR ALL USING (owner_id = auth.uid());

-- Recommendations
CREATE POLICY "Users can see own recommendations"
  ON recommendations FOR SELECT USING (
    sender_id = auth.uid() OR receiver_id = auth.uid()
  );
CREATE POLICY "Users can send recommendations"
  ON recommendations FOR INSERT WITH CHECK (sender_id = auth.uid());

-- Notifications
CREATE POLICY "Users can see own notifications"
  ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE USING (user_id = auth.uid());

-- Wishlist
CREATE POLICY "Users can manage own wishlist"
  ON wishlist FOR ALL USING (user_id = auth.uid());
