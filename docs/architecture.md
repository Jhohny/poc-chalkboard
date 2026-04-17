# Architecture

MVP defaults:

- one Rails app
- root domain is the product
- no separate marketing site

Product assumptions for v1:

- detect the visitor's city from IP address
- no browser geolocation prompt
- no manual city override
- anonymous posting only
- random pseudonym persisted for the browser session
- random icon or emoji persisted with the pseudonym for the browser session
- text-only posts capped at 120 characters
- one post per minute per session
- block exact repeat submissions from the same session
- posts expire automatically after 48 hours
- city feed ordered newest first
- viewers in the same city receive live updates when new posts are created

Start simple. Add more infrastructure only when the MVP needs it.

Likely implementation shape:

- root page renders the city wall
- store posts with city identifier, pseudonym, body, and timestamps
- store lightweight presentation attributes for each post such as board position, rotation, color, and size
- session stores the generated pseudonym and rate-limit context
- session also stores the pseudonym icon or emoji
- scheduled cleanup or query filtering removes posts older than 48 hours
- use Rails real-time primitives so new city posts can be broadcast to active viewers on that city's wall
- if IP-to-city lookup fails, render an unavailable state instead of fallback content
