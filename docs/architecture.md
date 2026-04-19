# Architecture

## MVP defaults

- one Rails app
- root domain is the product
- no separate marketing site

## Product assumptions for v1

- detect the visitor's city from IP address
- no browser geolocation prompt
- no manual city override
- anonymous posting only
- random pseudonym persisted for the browser session
- random icon or emoji persisted with the pseudonym for the browser session
- text-only posts capped at 120 characters
- one post per minute per session
- block exact repeat submissions from the same session
- posts expire automatically after 48 hours (soft delete via expires_at filter, no hard deletion)
- city feed ordered newest first
- viewers in the same city receive live updates when new posts are created

Start simple. Add more infrastructure only when the MVP needs it.

## Current implementation shape

- root page renders the city wall
- posts store city identifier, pseudonym, body, timestamps, and presentation attributes (position, rotation, color, size)
- session stores the generated pseudonym, icon, and rate-limit context
- query filtering via `expires_at` removes expired posts from all queries without deleting rows
- Rails Action Cable via Solid Cable broadcasts new posts to city-scoped streams
- if IP-to-city lookup fails, render an unavailable state instead of fallback content
- Solid Queue runs background jobs; Solid Cache handles caching
- recurring.yml schedules periodic maintenance tasks

## Phase 2 — Readability and mobile UX

No new data model needed. Changes are CSS and layout only:

- remove default text-shadow (glow) from notes; apply only on hover via CSS `:hover`
- increase gap between note cards
- apply Caveat font to note body only; metadata uses system sans-serif
- mobile: collapsible composer using Stimulus — closed state persists while user scrolls, floating button reopens it
- mobile: compact header at reduced size

## Phase 3 — City Pulse and daily prompts

### City Pulse

Derived from existing post data. No new table required.

Computed values per city per request (or cached short-term):

- note count in the last hour: `Post.visible_in_city(slug).where('posted_at >= ?', 1.hour.ago).count`
- mood signal: heuristic based on count ranges (quiet / active / buzzing) or simple keyword matching on recent bodies
- specific signals (rain mentions, event energy): keyword scan on recent post bodies

Cache the result per city with a short TTL (60–120 seconds) to avoid recomputing on every request.

### Daily prompts

No database table. A hardcoded array of prompts rotated by `Date.today.yday % prompts.length`. Prompts are defined per locale (English and Spanish). The composer renders the day's prompt as the textarea placeholder.

## Phase 4 — Micro reactions and retention signals

### Reactions

New table: `reactions`

| column | type | notes |
|---|---|---|
| post_id | integer | foreign key to posts |
| reaction_type | string | one of: nod, same, lol, felt_that |
| session_token_digest | string | hashed session token, rate-limits one reaction per type per session per post |
| created_at | datetime | |

Constraints:
- unique index on `(post_id, reaction_type, session_token_digest)` — one reaction type per session per post
- no cascade delete needed; expired posts stay soft-deleted, reactions can be left in place

Reaction counts are aggregated per post on read. No separate counter cache needed at MVP scale.

Reactions are city-scoped implicitly through the post. A user in Mexico City only sees and reacts to notes on that city's wall.

Broadcasting: when a reaction is saved, broadcast updated counts to the city stream so all active viewers see the change live.

### Retention signals

"New notes since you left":

- store `last_visited_at` per city in the session
- on wall load, compute `Post.visible_in_city(slug).where('posted_at > ?', last_visited_at).count`
- show the count as a dismissible banner if > 0
- update `last_visited_at` to `Time.current` after rendering

"Your chalk got reactions":

- store the IDs of posts made in this session in the session store
- on wall load, query reaction counts for those post IDs
- show a summary if any reactions exist since last visit

Both signals are session-local. No accounts, no push notifications, no email.

## Localization

Rails I18n for all user-facing copy. English (`en`) and Spanish (`es`) are the two launch locales.

Locale detection order:

1. explicit user preference stored in session (future)
2. `Accept-Language` request header
3. fallback to English

City names, pseudonyms, and post bodies are user-generated and not translated. Only product copy (labels, prompts, reaction names, city pulse messages, error states) is localized.
