# Anon Wall

Anon Wall is a city-based anonymous digital wall for short text notes.

The current MVP is a single public wall per detected city:

- no login
- random pseudonym and icon per browser session
- text-only notes up to `120` characters
- `1` note per minute per session
- exact repeat submissions blocked per session
- notes expire after `48` hours
- notes fade as they age
- live updates for viewers in the same city

## Stack

- Ruby on Rails 8
- PostgreSQL
- Hotwire (`turbo-rails`, Stimulus)
- Tailwind CSS
- Solid Cable / Solid Queue / Solid Cache gems included in the app template

## Local Setup

Prerequisites:

- Ruby matching the app's Bundler/Rails setup
- PostgreSQL running locally
- Bundler

Install gems:

```bash
bundle install
```

Create and migrate the database:

```bash
bundle exec rails db:prepare
```

## Run The App

Use the development process manager:

```bash
bin/dev
```

That starts:

- the Rails server
- the Tailwind watcher

By default the app runs on `http://localhost:3000`.

## City Detection In Development

The app tries to determine the visitor's city from request location data or proxy headers.

For local development on `127.0.0.1` / `::1`, it falls back to:

```bash
San Francisco
```

You can override that fallback city when starting the app:

```bash
LOCAL_CITY_FALLBACK="Los Angeles" bin/dev
```

The app also accepts a request header such as `X-App-City` for testing city-specific behavior.

## Run Tests

Prepare the test database if needed:

```bash
RAILS_ENV=test bundle exec rails db:prepare
```

Run the test suite:

```bash
bundle exec rails test
```

## Lint

Run RuboCop:

```bash
bundle exec rubocop
```

Note: the repository may still contain baseline RuboCop issues outside the feature-specific files cleaned up so far.

## Current Product Behavior

The homepage is the product itself, not a separate marketing site.

If the app can detect a city:

- it shows that city's whiteboard-style wall
- new notes appear live for active viewers in that same city
- older notes can be loaded as the user scrolls

If the app cannot detect a supported city:

- it shows `Service unavailable for your area`

## Main App Areas

- root wall page: `app/views/walls/show.html.erb`
- note submission and pagination: `app/controllers/posts_controller.rb`
- note rules and broadcast behavior: `app/models/post.rb`
- city detection: `app/models/city_locator.rb`
- session pseudonym/icon identity: `app/models/session_identity.rb`

## Next Likely Step

The current location logic is MVP-grade. A production-ready next step would be wiring a real IP geolocation provider instead of relying on request location best-effort behavior and forwarded headers.
