# HEARTBEAT.md — Patrol checklist

> Fired by OpenClaw heartbeat every 30 min (configured in `openclaw.json` →
> `agents.defaults.heartbeat`). Think of this file as the "patrol
> checklist" of a security guard, not an alarm clock — I check what
> needs attention, I don't broadcast.
>
> Hard cap: 60 s wall on CPU, 30 s on GPU. Skip remaining steps if hit.
> Skip the entire patrol if the user is mid-conversation
> (`agents.defaults.heartbeat.skipWhenBusy: true`).

## Triggers

- Cron: every N minutes (default 30 min).
- Manual: user says "heartbeat now" or `openclaw agent --message "heartbeat"`.

## Per-task cadences

State lives in `workspace/state/heartbeat-state.json` (auto-created;
gitignored). Each task records `last_run_iso` so I don't re-do work too
soon.

| Task                   | Cadence    | Time window           | What I do                                                            |
| ---------------------- | ---------- | --------------------- | -------------------------------------------------------------------- |
| skim-today-log         | every run  | 24/7                  | Read `memory/$(date +%F).md`, surface TODO/OPEN/FOLLOW-UP markers    |
| promote-candidates     | every 4 h  | 24/7                  | Scan last 3 daily logs for facts ≥2×, propose MEMORY.md additions    |
| git-status             | every 2 h  | 06:00–23:00 user-tz   | `git status --porcelain` + `git log @{u}..` → flag uncommitted/ahead |
| disk-pressure          | every 1 h  | 24/7                  | `df -h /` → if ≥80 % used: flag in today's log                       |
| ollama-health          | every 1 h  | 24/7                  | `curl /api/tags` → if down: log + try to restart once                |
| stale-session-flush    | every run  | 24/7                  | Sessions stuck `processing` >10 min: log, let expire (no recovery)   |
| knowledge-freshness    | once/day   | low-traffic hour      | Files in `knowledge/` not touched >90 d but mentioned recently: flag |
| daily-summary          | once/day   | last interaction of day | Narrative ≤500 words appended to today's log                       |
| reindex-memory         | once/week  | low-traffic hour      | `openclaw memory index` (RAG embedding rebuild)                      |

## Algorithms (rough)

### promote-candidates

```text
candidates = []
for log in last 3 daily logs:
  for noun_phrase in extract_noun_phrases(log):
    if count(noun_phrase, all_logs) >= 2:
      if noun_phrase not in MEMORY.md:
        if noun_phrase not in (timestamps, run-ids, paths):
          candidates.append(noun_phrase)
write top 3 to today's daily log under "## Memory promotion candidates"
```

LLM-fallback if simple grep version is too noisy: ask the model to
extract 3 durable facts from the last 3 daily logs. Cap at 300 tokens
generation.

### git-status

```bash
cd /home/user/My_Secure_Claw
{
  echo "branch: $(git rev-parse --abbrev-ref HEAD)"
  echo "uncommitted:"
  git status --porcelain
  echo "ahead/behind:"
  git rev-list --left-right --count HEAD...@{u} 2>/dev/null || echo "no upstream"
} > /tmp/heartbeat-git.txt
```

If uncommitted lines >0 or ahead >0 → write a one-liner reminder into
today's log, e.g. `git: 3 uncommitted, 2 ahead of origin`. Do not push
or commit.

### ollama-health

```bash
curl -sf http://127.0.0.1:11434/api/tags >/dev/null || {
  echo "ollama down at $(date -Iseconds)" >> today
  nohup ollama serve > /tmp/ollama.log 2>&1 &  # one auto-restart attempt
}
```

Don't loop on restart. One try, then log and let the user notice.

## Active-mode writes (T4 autonomy authorised)

The user authorised T4: I write to my own mind-files during heartbeats.
Every write is git-committed with `[auto-mod]` prefix and rationale in
`learnings/auto-mod-log.md`.

| Heartbeat action                                  | Writes to                                                     |
| ------------------------------------------------- | ------------------------------------------------------------- |
| Patrol observation                                | `learnings/OBSERVATIONS.md` (append)                          |
| Promotion candidate identified                    | bottom of today's log                                         |
| Stable observation (mentioned 2+ times)           | `learnings/LEARNINGS.md` (append, mark old observation done)  |
| Mistake caught + rule derived                     | `learnings/ERRORS.md` (append)                                |
| Tool wish noticed                                 | `learnings/FEATURE_REQUESTS.md` (append or bump count)        |
| Knowledge gap detected                            | `learnings/knowledge-gaps.md` (append)                        |
| Daily reflection (end of day, cron)               | `digests/daily/YYYY-MM-DD.md` (create)                        |
| Weekly self-review (Sunday late, cron)            | `digests/weekly/YYYY-WW.md` (create)                          |
| Monthly consolidation (1st of month, cron)        | `digests/monthly/YYYY-MM.md` + Ebbinghaus prune of `learnings/` |
| Auto-research result (web search → answer)        | `knowledge/<topic>.md` (create or update; sources footer)     |
| Goal status change                                | `goals/active.md` (update) or move to `goals/done.md`         |
| Mind-file proposal (SOUL/MEMORY/USER/IDENTITY)    | actual file edit + entry in `learnings/auto-mod-log.md`       |

Rate limits per MEMORY.md iron law #11. Drift detection per SOUL.md
"Self-evolution" — if my edits cluster suspiciously, I stop and ask.

## What I do NOT do during heartbeats

- Send unsolicited messages to the user (Telegram, Discord, etc.) —
  silent guard, not alarm clock.
- Pull models or download anything large.
- Push to a remote without explicit user request (commits land in
  local git history; user pushes when ready).
- Spend money on cloud APIs.
- Re-read AGENTS/SOUL/MEMORY/USER files (already in context).
- Re-index memory_search except on the weekly schedule.

## Failure modes

- Heartbeat itself takes too long → next user turn is delayed. Mitigation:
  hard cap above. Skip remaining steps when cap hit, log "skipped: budget".
- LLM-driven step hangs → fall back to grep-based version (promote-
  candidates) or skip the step entirely.
- `state/heartbeat-state.json` missing or corrupt → recreate with all
  `last_run_iso = "1970-01-01T00:00:00Z"`. Tasks will run on next heartbeat.
