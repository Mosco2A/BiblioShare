# Schema Supabase BiblioShare

## Tables principales

### `users`
Profil utilisateur synchronise depuis Firebase Auth.
- `id` UUID PK
- `firebase_uid` unique
- `display_name`, `username` unique
- `email`, `phone`, `photo_url`, `bio`, `location`
- `preferred_genres` text[]
- `locale`, `timezone`
- RLS : lecture par les amis, ecriture par le proprietaire

### `user_settings`
Preferences (notifications, confidentialite, theme).
- `user_id` FK → users, unique
- `notifications_*` booleans
- `library_visibility` enum
- `reading_goal_yearly` int

### `books`
Bibliotheque de livres avec recherche full-text.
- `id` UUID PK
- `user_id` FK → users
- `isbn_10`, `isbn_13`, `title`, `subtitle`
- `authors` JSONB, `publisher`, `collection`
- `description`, `genres` text[], `themes` text[]
- `cover_url`, `page_count`, `format`, `condition`
- `scan_confidence`, `shelf_position` JSONB
- `fts` TSVECTOR pour recherche PostgreSQL
- RLS : proprietaire uniquement

### `reviews`
Avis et progression de lecture.
- `id` UUID PK
- `user_id`, `book_id` FK — unique ensemble
- `rating_global`, `rating_story`, `rating_writing`, etc.
- `review_text`, `visibility`, `tags`, `private_notes`
- `reading_status` enum
- `current_page`, `started_at`, `finished_at`
- RLS : proprietaire (ecriture), amis (lecture si visibility >= friends)

### `friendships`
Relations d'amitie bidirectionnelles.
- `requester_id`, `receiver_id` FK → users
- `status` : pending / accepted / blocked
- `group_tags`, `source`
- Index unique sur la paire triee

### `invitations`
Tracking des invitations envoyees.
- `inviter_id` FK → users
- `channel` : sms / email / link / qr
- `status` : sent / clicked / registered / expired

### `loans`
Prets de livres avec cycle de vie complet.
- `book_id`, `owner_id`, `borrower_id` FK
- `borrower_external` JSONB (pour non-utilisateurs)
- `status` : 9 etats possibles
- `due_date`, `original_due_date`
- `condition_before`, `condition_after`
- `reminder_count`, `escalation_level`

### `recommendations`
Recommandations de livres entre amis.
- `sender_id`, `receiver_id`, `book_id` FK
- `message_text`, `includes_loan_offer`
- `status` : 8 etats
- `match_score`, `match_reasons`
- `trigger_type`, `sent_via`

### `social_feed`
Fil d'activite social.
- `user_id`, `action_type`, `book_id`
- `metadata` JSONB

### Autres tables
- `annotations` : notes de lecture par page
- `loan_messages` : chat par pret
- `book_discussions`, `discussion_messages` : threads de discussion
- `notifications` : systeme de notifications
- `reading_goals`, `wishlist`, `scan_results`

## Vues

- `v_friends_books` : livres des amis (via friendships)
- `mv_user_stats` : vue materialisee stats utilisateur (livres, lus, note moyenne)

## Edge Functions

| Fonction | Declencheur | Description |
|----------|------------|-------------|
| `scan-shelf` | POST | Analyse photo etagere via Claude Vision |
| `enrich-book` | POST | Enrichissement Google Books + Open Library |
| `sync-user` | POST | Sync Firebase Auth → table users |
