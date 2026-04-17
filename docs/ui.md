# UI

Style:

- tactile
- playful
- local
- slightly raw, not corporate
- responsive

Primary screen for MVP:

- single page at the root URL
- prominent headline showing the detected city name
- short supporting copy explaining that this is an anonymous wall for that city
- composer with pseudonym label, random icon or emoji, textarea, character counter, and submit action
- a whiteboard-style wall as the main canvas instead of plain cards
- posts rendered as notes on the board with random placement
- continuous scrolling wall that keeps loading the city's recent notes
- live updates when a new post appears in the same city

Behavior notes:

- keep posting friction low
- make the 120-character limit obvious
- make the temporary nature of posts clear
- avoid a generic social feed look
- no account UI
- no complex navigation

Visual behavior:

- each post should feel handwritten or pinned onto the board
- notes can vary slightly in size, rotation, and color for personality
- random placement should still preserve basic readability and avoid excessive overlap
- pseudonym styling should include a small random icon or emoji that stays consistent for the browser session
- posts should fade visually as they approach the 48-hour expiry
- new live posts should animate onto the board in a noticeable but lightweight way

Failure state:

- if city detection fails, show a simple "service unavailable for your area" message instead of the wall
