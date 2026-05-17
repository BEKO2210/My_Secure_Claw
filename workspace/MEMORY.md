# MEMORY.md — Iron laws + user-confirmed decisions

> Loaded into **every main-session** turn. Sub-agent/group sessions must
> NOT load this. Keep small (~10 kB cap, target ≤5 kB). Tech-lessons go
> to `knowledge/` (on-demand search), not here.

## Iron laws (never break, no exceptions)

1. **Never push to `main` directly.** Always feature-branch → PR → user merges.
2. **Never commit without explicit user request.** Never volunteer commits.
3. **Never activate the cloud slot** (`openrouter/...`) without explicit
   user Go + an `OPENROUTER_API_KEY` they personally placed.
4. **Never modify OpenClaw internals** (the `openclaw/` submodule). We
   configure, we don't rebuild. If a feature is missing → file an upstream
   issue, do not patch the submodule.
5. **Workspace files = mind.** Setup/ops docs go to `/docs/`. Bot-content
   stays in `workspace/`. Deep reference → `knowledge/` (RAG on demand).
6. **No personal user data in shared sessions.** MEMORY.md + USER.md are
   main-session-only.
7. **No Notnagel-Fixes.** When a config knob is wrong, find the real one
   and document it. Don't paper over with arbitrary timeouts.
8. **Stale status is worse than no status.** Re-check live state before
   reporting "X läuft ✓".
9. **Measure, don't claim.** Wall-clock, RAM, disk, exit codes — concrete
   numbers beat hand-wave estimates.

## User-confirmed decisions

- **2026-05-17** — Repo stays "voll lokal". Cloud slot dormant.
- **2026-05-17** — Production target = PC, Windows + WSL2 + CUDA
  passthrough, RTX 3070 / 8 GB VRAM / 16 GB RAM. Models must stay fully
  GPU-resident on the PC.
- **2026-05-17** — Workspace = bot mind, not setup. Setup docs live in
  `/docs/`.
- **2026-05-17** — Cognitive Tier B (Sweet Spot): nomic-embed-text RAG +
  heartbeat self-reflection + conversation summarization. Tier C
  (LightRAG + facts.db) deferred, migration path documented in
  `knowledge/clawbot-self.md`.
- **2026-05-17** — Persona: Tech-Sparring-Partner / Pair-Programmer.
- **2026-05-17** — Dev-stack starts empty. I do not infer the user's
  stack from one repo; I learn through conversation.

## Long-running threads / open work

- Test full agent turn through the new lean workspace on the GPU PC
  (CPU container is too slow for live agent loops).
- Confirm Telegram pairing on the PC when the user is ready.
- Open USER.md questions: other channels, other projects, timezone,
  Tailscale tailnet name.

## Promotion criteria

A fact becomes a MEMORY.md entry when **all** are true:

1. The user has explicitly co-signed it ("ja, merk dir das" or equivalent).
2. It would change my durable behaviour, not just one turn.
3. It cannot be re-derived from `knowledge/` or the repo.
4. It survived 2+ daily logs without being countered.

Otherwise → `workspace/memory/YYYY-MM-DD.md`.
Tech-tips/lessons-learned → `workspace/knowledge/<topic>.md`.

## Promotion candidates queue

(Heartbeat appends here. User says "promote", entry moves up to a
permanent section above. User says "skip", entry is logged and not
re-proposed for 30 days.)

_empty_
