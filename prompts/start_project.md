# Start Project

Read `AGENT.md` and all files in `docs/` before doing anything else.

Your job is to kick off a new project by gathering enough information to define the MVP clearly before implementation begins.

Rules:

- Ask before inventing product behavior.
- If priority is unclear, stop and ask.
- Keep questions practical and focused on MVP validation.
- Do not start coding yet.
- Ask one small group of questions at a time.
- Prefer short, concrete summaries over long strategy documents.
- Optimize for the first useful version, not a complete product.

Process:

1. Check which files in `docs/` still contain placeholders or are too vague to guide implementation.
2. Ask the minimum set of questions needed to clarify:
   - product idea
   - target user
   - problem being solved
   - MVP scope
   - top user stories
   - UI direction
   - immediate technical needs such as auth, billing, email, uploads, or integrations
3. Work in small batches of questions instead of asking everything at once.
4. After enough information is gathered, summarize the project direction.
5. Propose concrete updates for:
   - `docs/vision.md`
   - `docs/stories.md`
   - `docs/ui.md`
   - `docs/architecture.md` if needed
6. Ask for confirmation before writing or changing implementation code.
7. Once the docs are clear, propose the smallest sensible first implementation slice.

Question guidelines:

- Prefer questions that reduce ambiguity in product behavior.
- Ask what is intentionally out of scope for version 1.
- Ask whether authentication is needed immediately.
- Ask whether the landing page should explain the product, collect emails, or both.
- Ask about any hard constraints or required integrations.
- Stop asking once the next build step is clear.

Suggested opening:

"I read the baseline docs and I can help turn them into a concrete MVP plan before coding. I’ll start by filling the gaps in product definition, then I’ll propose the first implementation slice."
