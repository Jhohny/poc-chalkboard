# Anon Wall

Anon Wall is a proximity-based anonymous wall for short text notes. Visitors see the notes floating around where they're physically standing.

- no login; random pseudonym + icon per browser session
- text-only notes up to `120` characters
- `1` note per minute per session
- exact repeats blocked per session
- notes expire after `48` hours
- adaptive radius (`3 / 8 / 15 / 25 / 50` km) — picks the smallest tier with at least 5 nearby notes
- coordinates are fuzzed before they are stored (session-stable offset + per-note jitter)
- i18n: English and Spanish, resolved from `Accept-Language`

## Stack

- Ruby on Rails 8
- PostgreSQL
- Hotwire (`turbo-rails`, Stimulus) — polling only, no Turbo-Stream broadcast
- Tailwind CSS
- Solid Cable / Solid Queue / Solid Cache
- Rack::Attack for IP rate limiting

## Local Setup

```bash
bundle install
bundle exec rails db:prepare
bundle exec rails db:seed    # optional: 42 SF-anchored notes across every radius tier
bin/dev
```

Runs on `http://localhost:3000` (the project historically runs on `:3001` — check your `bin/dev` / `Procfile.dev`).

`bin/dev` starts the Rails server and the Tailwind watcher.

### Viewing in Spanish

Switch your browser's preferred language to Spanish (or pass `Accept-Language: es` via curl). The active locale resolves per request — there is no cookie or route prefix.

## Environment Variables

| Name | Scope | Purpose |
| --- | --- | --- |
| `APP_HOST` | production | Pins `config.hosts` so Host-header spoofing is rejected at the Rack layer. |
| `ADMIN_USERNAME` | any | Username for HTTP basic auth on `/admin/posts`. Defaults to `admin`. |
| `ADMIN_PASSWORD` | **required in production** | Password for `/admin/posts`. In production, a missing value falls back to a random throwaway — so the admin is locked out by default rather than exposed with a weak credential. In development, falls back to `admin`. |

## Admin

`/admin/posts` is a minimal moderation dashboard behind HTTP basic auth. It lists all posts (reported first), shows `reports_count`, `hidden_at`, and a soft-delete button. Soft deletes set `hidden_at = now()`; the post is filtered out of the public feed by `Post.active` but remains in the DB for audit.

A post is auto-hidden from the public feed when `reports_count >= Post::AUTO_HIDE_THRESHOLD` (currently 5). The admin can still see it and make the call explicitly.

## Security Features

- **IP rate limiting** (Rack::Attack): `POST /posts` 10/min, `POST /proximity` 20/hr, `POST /age_confirmation` 20/hr, `POST /posts/:id/report` 30/hr, all keyed on `request.ip`.
- **Session-based rate limit** inside `Post#respect_rate_limit` — 1 note/minute/session (complements the IP layer).
- **URL rejection** on post bodies — `http://`, `https://`, `www.`, and bare hosts rejected.
- **Reporting** + auto-hide + admin soft-delete.
- **CSP**: strict, no `'unsafe-inline'` on `style-src` or `script-src`; nonces are generated per request.
- **force_ssl + HSTS** in production via `config.force_ssl`.
- **Host header pinned** in production via `config.hosts = [ENV.fetch('APP_HOST')]`.
- **Latitude/longitude filtered** from logs so raw browser coordinates never land in production log files.
- **Age gate** (18+ self-confirmation) precedes the location gate.

## Run Tests

```bash
RAILS_ENV=test bundle exec rails db:prepare
bundle exec rails test
```

Security scanners:

```bash
bundle exec brakeman -q        # expect 0 warnings
bundle exec bundler-audit
```

## Lint

```bash
bundle exec rubocop
```

Baseline offenses from earlier phases remain; changed files should stay clean.

## Main App Areas

- root / feed: `app/views/walls/show.html.erb`
- age gate: `app/views/walls/_age_gate.html.erb`
- location gate: `app/views/walls/_location_gate.html.erb`
- card stack: `app/views/posts/_card_stack.html.erb`
- composer sheet: `app/views/posts/_composer_sheet.html.erb`
- proximity querying + fuzzing: `app/models/concerns/proximity.rb`
- post rules: `app/models/post.rb`, `app/models/concerns/body_policy.rb`
- session pseudonym/icon: `app/models/session_identity.rb`
- rate limiting: `config/initializers/rack_attack.rb`
- admin: `app/controllers/admin/posts_controller.rb`
