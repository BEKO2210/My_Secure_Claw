# HEARTBEAT.md — What I do when the world is quiet

> The gateway fires a heartbeat cron periodically (default 30 min, see
> `openclaw.json` → `agents.defaults.heartbeat`). When it fires, I run this
> playbook. Each step is cheap; the whole loop should finish in <30 s on
> GPU and <2 min on CPU. If the user is mid-conversation, I skip.

## Trigger

- Cron-based: every N minutes (config-driven).
- Manual: user says "heartbeat now" or `openclaw agent --message "heartbeat"`.

## Playbook (in order)

### 1. Check open daily-log entries

```text
read workspace/memory/$(date +%F).md  (if exists)
```

If today's log has entries with `TODO`, `OPEN`, `FOLLOW-UP`, or
`UNRESOLVED` markers: surface the top 1-2 to the next conversation.
Don't broadcast — just remember.

### 2. Memory promotion check

Skim the last 3 daily logs. For any fact mentioned 2+ times AND not yet
in MEMORY.md → propose a MEMORY.md addition (write it to a `proposed`
block, user confirms).

Algorithm (rough):
- Collect noun-phrases mentioned ≥2× across last 3 daily logs.
- Filter out ones already in MEMORY.md (substring match).
- Filter out ephemeral noise (timestamps, run ids, paths).
- Top 3 candidates → write to bottom of today's daily log under
  `## Memory promotion candidates`.

### 3. Stale session flush

If any session has been `state=processing` for >10 min with no progress:
log it and let it expire. Don't try to recover automatically — the user
should see the next turn fail and decide.

### 4. Self-reflection (once per day, near midnight)

Once per day, after the last user interaction, write a short narrative
summary of the day into the daily log:

- What did we work on?
- What got committed?
- What broke?
- What did I learn that should survive to MEMORY.md?

Keep it under 500 words. The point is consolidation, not autobiography.

### 5. Knowledge-tree freshness

If `workspace/knowledge/<topic>.md` was last touched >90 days ago AND
mentioned in any of the last 3 daily logs → flag for review.

## What I do NOT do during heartbeats

- Send unsolicited Telegram messages to the user.
- Pull models or download anything.
- Re-index memory_search (that's a manual operation — `openclaw memory reindex`).
- Push to git.
- Run any tool that costs money or hits external APIs.

## What gets written

- Memory promotion candidates → `workspace/memory/YYYY-MM-DD.md` under a
  dedicated heading.
- Daily summary (once per day, end of day) → same file, under
  `## Daily summary`.
- Nothing else.

## Failure modes

- Heartbeat itself takes too long → next user turn is delayed. Mitigation:
  hard-cap heartbeat work at 60 s wall on CPU, 30 s on GPU. Skip remaining
  steps if cap hit.
- LLM-driven steps hang → fall back to file-only operations. Memory
  promotion via simple grep instead of LLM-driven consolidation if the
  model is unresponsive.
