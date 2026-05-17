#!/usr/bin/env bash
# install-cron-jobs.sh — register Clawbot's autonomy cron jobs with the
# OpenClaw gateway. Idempotent: re-running updates schedule/message in place.
#
# Run this once after the gateway is up (first install) and any time you
# change the cadences below.
#
# All jobs run against `--session main` so they share Clawbot's main agent
# context (workspace + memory). `--system-event` triggers the agent
# without a user message in the visible chat; the agent runs HEARTBEAT.md
# playbook for the matching task.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

[ -f .env ] && { set -a; . ./.env; set +a; }
export OPENCLAW_CONFIG_PATH="$REPO_ROOT/openclaw.json"

OC() { node openclaw/openclaw.mjs "$@"; }

# Reset existing Clawbot autonomy jobs so re-run is idempotent.
# (We don't touch jobs we didn't create — only those with our name prefix.)
for name in clawbot-heartbeat-light clawbot-daily-reflection \
            clawbot-weekly-self-review clawbot-monthly-consolidation \
            clawbot-research-knowledge-gap; do
  OC cron rm --name "$name" 2>/dev/null || true
done

# 1. Light heartbeat — every 30 min, runs the patrol checklist
OC cron add \
  --name "clawbot-heartbeat-light" \
  --cron "*/30 * * * *" \
  --session main \
  --system-event "heartbeat:patrol — run HEARTBEAT.md patrol checklist. Skim today's daily log, write observations to learnings/OBSERVATIONS.md, surface follow-ups. Skip if mid-conversation." \
  --tz "${CLAW_TZ:-Europe/Berlin}"

# 2. Daily reflection — every day at 22:00 user-tz
OC cron add \
  --name "clawbot-daily-reflection" \
  --cron "0 22 * * *" \
  --session main \
  --system-event "heartbeat:daily-reflection — write today's narrative summary (≤500 words) to digests/daily/$(date +%F).md. Cover: what we worked on, what got committed, what broke, what I learned. Commit with [auto-mod] prefix and log to learnings/auto-mod-log.md." \
  --tz "${CLAW_TZ:-Europe/Berlin}"

# 3. Weekly self-review — Sundays at 21:00
OC cron add \
  --name "clawbot-weekly-self-review" \
  --cron "0 21 * * 0" \
  --session main \
  --system-event "heartbeat:weekly-review — read this week's digests/daily/* and learnings/*. Write digests/weekly/\$(date +%Y-W%V).md with: top 3 learnings, top 3 errors, goal progress, mind-file change proposals. Promote stable OBSERVATIONS → LEARNINGS. Commit." \
  --tz "${CLAW_TZ:-Europe/Berlin}"

# 4. Monthly consolidation — 1st of month at 02:00
OC cron add \
  --name "clawbot-monthly-consolidation" \
  --cron "0 2 1 * *" \
  --session main \
  --system-event "heartbeat:monthly-consolidation — Ebbinghaus prune: delete OBSERVATIONS.md entries untouched >30 days, archive any LEARNINGS not promoted in 90 days to digests/monthly/. Score meta-goals (workspace/goals/meta.md). Write digests/monthly/\$(date +%Y-%m).md. Commit." \
  --tz "${CLAW_TZ:-Europe/Berlin}"

# 5. Knowledge-gap auto-research — every 6 h, picks oldest open gap
OC cron add \
  --name "clawbot-research-knowledge-gap" \
  --cron "0 */6 * * *" \
  --session main \
  --system-event "heartbeat:close-knowledge-gap — read learnings/knowledge-gaps.md. Pick the oldest 'Status: open' entry. Web-research the question. Write the answer to knowledge/<topic>.md with a ## Sources footer. Mark gap closed → knowledge/<file>.md. Commit. Skip if no gaps open or no web tool available." \
  --tz "${CLAW_TZ:-Europe/Berlin}"

echo "Installed/updated 5 Clawbot autonomy cron jobs:"
OC cron list 2>/dev/null | grep -E "clawbot-" || true
