# UI

Style:

- tactile
- playful
- local
- slightly raw, not corporate
- responsive

## Primary screen (current)

- single page at the root URL
- prominent headline showing the detected city name
- short supporting copy explaining that this is an anonymous wall for that city
- composer with pseudonym label, random icon or emoji, textarea, character counter, and submit action
- a chalkboard-style wall as the main canvas
- posts rendered as chalk notes on the board with slight rotation and offset
- continuous scrolling wall that keeps loading the city's recent notes
- live updates when a new post appears in the same city

## Behavior notes

- keep posting friction low
- make the 120-character limit obvious
- make the temporary nature of posts clear
- avoid a generic social feed look
- no account UI
- no complex navigation
- feed is the hero — composition is secondary

## Typography layering

Apply fonts deliberately, not uniformly:

- serif: city headline only
- system sans-serif: all metadata (pseudonym, timestamps, labels, UI chrome)
- handwritten (Caveat): note body content only

Too much cursive creates mental load. Reserve it for where it earns its place.

## Visual behavior

- each post should feel handwritten or pinned onto the board
- notes can vary slightly in size, rotation, and color for personality
- random placement should preserve basic readability and avoid excessive overlap
- pseudonym styling includes a small random icon or emoji consistent for the session
- posts fade visually as they approach the 48-hour expiry
- new live posts animate onto the board in a noticeable but lightweight way

## Readability principles

Glow is a reward, not a default:

- default note text: matte chalk — no text-shadow, full opacity
- glow (text-shadow bloom): on hover or selected note only
- reduce halo spread by 30–40% from any previous implementation
- glow that looks good in screenshots often tires eyes in real use

Spacing:

- increase gap between notes — air equals comfort and retention
- cramped density increases fatigue and reduces time on page

## Mobile UX

Problems to solve:

- composition panel dominates on mobile, most users come to read first
- too much vertical space before feed content
- users should hit notes faster

Target mobile behavior:

- city header: compact, 20% shorter than desktop
- composer: collapsible — closed by default after initial load or first scroll
- floating "Write on wall" button: appears when composer is collapsed, opens it inline
- first notes visible above fold on initial load
- feed is the full-screen experience on mobile

## City Pulse strip

A compact strip at the top of the wall that makes the city feel alive.

Examples:

- "34 notes in the last hour"
- "Tonight feels quiet"
- "Rain mentions rising"
- "Giants game energy downtown"

Content is computed from recent post activity and optionally keyword patterns. The strip does not require a separate backend service — it can be derived from existing post data.

City Pulse is always city-scoped. A user in Mexico City sees that city's pulse, not San Francisco's.

## Daily prompts

The composer textarea placeholder rotates daily with a city-specific prompt. Examples:

- "What did the city smell like today?"
- "What annoyed you today?"
- "What surprised you today?"
- "What changed today?"

Prompts are a lightweight retention mechanism — they give users a reason to post even when they have nothing particular to say. Prompts must be translated into Spanish for Spanish-speaking markets.

## Micro reactions

No likes. The reaction vocabulary is human and local in tone:

- nod
- same
- lol
- felt that

Reactions are anonymous and session-rate-limited. No account required to react.

Spanish equivalents must ship alongside English from the start:

- nod → asiento
- same → igual
- lol → jaja
- felt that → lo sentí

## Failure state

If city detection fails, show a simple "service unavailable for your area" message instead of the wall.
