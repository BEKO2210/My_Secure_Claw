# MIND.md — what each workspace file is for

This is the value the repo adds on top of stock OpenClaw. Edit these,
re-run `./scripts/install-mind.sh`, the bot's behaviour changes.

## Always-loaded (injected into every main-session turn)

| File | Purpose | Size guideline |
|---|---|---|
| `IDENTITY.md` | Name, vibe, emoji, language. Card-style. | 300-600 chars |
| `SOUL.md` | Persona, voice, values, working style, push-back rules | up to 10 KB |
| `USER.md` | What the bot knows about its human (loaded ONLY in main 1:1 sessions) | up to 10 KB |
| `MEMORY.md` | Iron-law rules + user-confirmed decisions. Main-session only. | keep <5 KB |
| `TOOLS.md` | What I can do, what I can't, hosts table | up to 10 KB |
| `AGENTS.md` | Boot sequence + per-turn loop + when to write memory | up to 10 KB |
| `HEARTBEAT.md` | Playbook for periodic self-checks (manual cron later) | up to 10 KB |

Per-file hard cap is 20 000 chars (OpenClaw truncates). Total bootstrap
target ≈ 30-50 KB. Beyond that → push into `knowledge/`.

## Loaded on demand (semantic search)

| Tree | Purpose |
|---|---|
| `knowledge/` | One topic per file. Loaded into context only when `memory_search` returns it. |
| `memory/YYYY-MM-DD.md` | Daily session logs (raw). The bot can write here. |
| `learnings/` | Structured learning loop (OBSERVATIONS, LEARNINGS, ERRORS, FEATURE_REQUESTS, knowledge-gaps, auto-mod-log) |
| `goals/` | Explicit goal queue (active, meta, done) |
| `digests/` | Bot's self-written reflections (daily / weekly / monthly) — empty until cron jobs are set up |

These trees are indexed by `nomic-embed-text` and reachable via
`memory_search`. Rebuild after edits:
```bash
node openclaw/openclaw.mjs memory index
```

## How to evolve

1. Talk to the bot. When something durable emerges:
   - Iron rule → propose for `MEMORY.md` (with user nod first)
   - User preference → propose for `USER.md`
   - Tech insight → write into `knowledge/<topic>.md`
   - Mistake + rule → append to `learnings/ERRORS.md`

2. Commit + push the changes.

3. On other machines: `git pull && ./scripts/install-mind.sh`.

## What does NOT belong in workspace/

- Operator-facing setup docs → `docs/`
- Custom code that bypasses OpenClaw → out of repo
- Secrets → `~/.openclaw/` (managed by onboard)
- Build artifacts / model blobs → never committed
