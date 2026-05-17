# knowledge-gaps.md — Things I noticed I don't know

> When I notice a gap (user asks something I can't answer well, I had to
> guess, I deferred to a web search), log it here. Auto-research cron
> picks the oldest / most-cited gap, runs a research turn, writes a
> `knowledge/<topic>.md` entry, and marks the gap closed.
>
> Per the user-confirmed autonomy policy: auto-research is allowed
> without per-fetch approval (T4). Audit trail = git history.

> Format:
> `## YYYY-MM-DD HH:MM gap-title`
> ` Question: <the precise question I couldn't answer well>`
> ` Triggered by: <session / heartbeat / etc>`
> ` Status: open | researching | closed → knowledge/<file>.md`

## 2026-05-17 OpenClaw cron job schema (precise field list)

Question: What's the exact field list for `~/.openclaw/cron/jobs.json`
entries (schedule, agent, session-mode, message vs system-event, wake,
delete-after-run, retry overrides)?
Triggered by: bootstrap of autonomy layer
Status: open — will be closed by first run of the auto-research cron.

## 2026-05-17 Best practice for memory_search query expansion

Question: When the bot writes its own search query, should it expand
the user's question into multiple variants for hybrid search, or trust
nomic-embed-text + BM25 keyword to bridge phrasing differences?
Triggered by: AGENTS.md design
Status: open

## 2026-05-17 Ebbinghaus-style decay for daily logs

Question: What's the right threshold for pruning an OBSERVATIONS.md
entry as "trivial"? Single-mention + 14 days untouched? Or
classifier-based?
Triggered by: HEARTBEAT.md monthly-consolidation design
Status: open
