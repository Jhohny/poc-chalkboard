# Phase 5 — Proximity Feed (Proximity-Only)

## What changes

The product becomes fully proximity-native.

The previous city-scoped wall is retired for Phase 5.

Instead of browsing a city feed, every visitor enters a stacked card experience showing anonymous notes from people physically near them.

The interaction is closer to Tinder than Twitter:

- one note at a time
- deliberate movement through cards
- intimate, nearby, human-scale
- less scrolling, more presence

The goal is not content consumption. The goal is feeling that people around you exist.

---

## Core product truth

This is not a city message board.

It is a living layer of nearby anonymous thoughts.

Examples:

- someone is practicing trumpet nearby
- I missed my bus again
- smells like rain tonight

These feel meaningful because they are close.

---

## Why proximity-only

Removing fallback modes strengthens the product.

Benefits:

- clearer identity
- stronger trust in local authenticity
- simpler architecture
- better habit loops tied to movement and time
- easier word-of-mouth positioning

This becomes:

**The thoughts floating around where you stand.**

---

## Entry requirement

Approximate device location is required to use the app.

No accounts. No identity. No exact tracking.

### First-launch prompt flow

Show an in-app screen before browser permission dialog.

**See anonymous notes from people near you.**
We only use approximate location to show nearby posts.

Buttons:

- Allow location
- Learn more

Then trigger browser geolocation request.

```javascript
navigator.geolocation.getCurrentPosition(successCallback, errorCallback, {
  enableHighAccuracy: false,
  timeout: 10000,
  maximumAge: 300000
})
```

Use network-based location, not exact GPS.

---

## If permission is denied

Do not fall back to city mode.

Show graceful locked state:

**Nearby notes need approximate location.**
We never show your exact position.

Buttons:

- Enable location
- Why we ask

The product remains honest to its core mechanic.

---

## Radius model

Adaptive radius, not fixed.

### Radius tiers

| Tier | Radius |
|---|---|
| Very Close | 3 km |
| Nearby | 8 km |
| Around Town | 15 km |
| Wider Area | 25 km |
| Farther Out | 50 km |

### Thresholds

- Minimum usable batch: 5 notes
- Healthy batch: 15+
- Strong batch: 30+

### Cold-load optimization

Use one DB query:

1. Fetch visible posts within max radius (50 km)
2. Compute distances
3. Bucket results by radius tier
4. Select smallest tier meeting threshold
5. Rank and return feed cards

Chosen radius cached in session for 30 minutes.

Users may widen manually anytime.

---

## Data model

All posts are proximity posts.

```ruby
add_column :posts, :latitude,  :decimal, precision: 7, scale: 4, null: false
add_column :posts, :longitude, :decimal, precision: 7, scale: 4, null: false
add_index  :posts, [:latitude, :longitude]
```

No city-only rows.

No dual feed systems.

---

## Privacy protections

### Coordinate fuzzing

Before persistence:

```ruby
FUZZ_DEGREES = 0.005

def fuzz(value)
  value + rand(-FUZZ_DEGREES..FUZZ_DEGREES)
end
```

Approximate ±500 m.

### Session-stable offset

Use one random offset per session for that visitor's posts.

Prevents triangulation across repeated posts.

### Optional snap grid

```ruby
value.round(3)
```

Coordinates stored are already privacy-degraded.

---

## Feed querying

Use Haversine SQL.

```ruby
scope :within_km, ->(lat, lng, radius_km) {
  where(...)
}
```

Example:

```ruby
Post.visible
    .within_km(lat, lng, selected_radius)
    .limit(200)
```

---

## Feed ranking

### V1

```text
score = distance_decay + time_decay + exploration_noise
```

Signals:

- nearer notes rank higher
- fresher notes rank higher
- slight randomness avoids repetitive sessions

### Freshness decay

- full weight first 2 hours
- gradual decay until 48h expiry

### V2

```text
score = distance_decay + time_decay + reactions + saves + dwell_time + exploration_noise
```

Length is not a quality signal.

---

## Card UI

### Layout

Single centered card.

Shows:

- note text
- fuzzy distance
- time ago
- optional vibe icon
- progress count

Example:

> someone left flowers on the bench again
0.8 km away · 12 min ago

### Navigation

#### Mobile

- swipe left = next
- swipe right = next
- tap edge = next

#### Desktop

- arrow keys
- previous / next buttons

No like/dislike semantics.

### Stack effect

Render top three cards.

Back cards peek behind front card.

---

## Composer

Floating action button.

Examples:

- Write nearby note
- Leave a note here

Bottom sheet opens on tap.

After submit:

- inject into local stack
- no reload

---

## Empty state

**Quiet nearby right now. Leave the first note.**

This reinforces authenticity.

---

## Live updates

### V1 polling

Poll every 60 seconds while tab visible.

Pause polling when:

- tab hidden
- low-power mode
- idle >10 minutes

Supports:

- new nearby note counts
- refresh prompts

### V2 streams

Optional websocket / geohash streams after proven demand.

---

## Abuse controls

- Existing rate limits remain
- Duplicate blocking remains
- If one source dominates nearby feed, reduce visibility weight

---

## Retention systems

### 1. Movement unlocks content

Different streets reveal different notes.

### 2. Time changes mood

Morning differs from midnight.

### 3. Radius expands curiosity

Nothing nearby? Widen area.

### 4. Contribution loop

My note is now floating near me.

### 5. Return hooks

- 9 new notes nearby
- Night is getting active around you
- One new note appeared close by

---

## Privacy display rules

Never show:

- exact address
- map pin
- direction arrow
- repeatable clues

Only show:

- nearby
- ~500 m away
- ~3 km away
- around town

Mystery improves safety and atmosphere.

---

## Architecture

| Concern | Approach |
|---|---|
| Coordinates | required lat/lng |
| Querying | Haversine SQL |
| Adaptive radius | single query + buckets |
| Session | lat/lng/radius cache |
| Privacy | fuzz before save |
| Cards | Stimulus controller |
| Swipe | touch delta |
| Updates | polling first, streams later |

---

## User stories

- As a visitor, I feel nearby human presence without creating an account.
- As a visitor, I understand why location is required before entering.
- As a visitor, I browse one nearby note at a time.
- As a visitor, I leave notes for nearby strangers.
- As a visitor, changing neighborhoods changes the feed.
- As a visitor, the app feels alive multiple times daily.

---

## What does not change

- No accounts
- No profiles
- No follower graph
- 120 character limit
- 48h expiry
- duplicate blocking
- rate limiting
- English + Spanish support

---

## Strategic truth

This should not feel like social media.

It should feel like:

**The thoughts floating around where you stand.**
