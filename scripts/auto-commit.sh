#!/usr/bin/env bash
# auto-commit.sh — Clawbot uses this to safely commit its own
# self-modifications. Enforces the disciplines in MEMORY.md iron law #10:
#
#   - Every commit gets the [auto-mod] prefix
#   - Every commit appends a rationale line to learnings/auto-mod-log.md
#   - Never pushes (user does that)
#
# Usage:
#   auto-commit.sh "<subject>" "<rationale-for-log>" <file> [<file> ...]
#
# Example (heartbeat use):
#   ./scripts/auto-commit.sh \
#     "log today's observations" \
#     "heartbeat:patrol — 3 observations: ollama up, disk 73%, no stalled sessions" \
#     workspace/learnings/OBSERVATIONS.md

set -euo pipefail

if [ $# -lt 3 ]; then
  echo "usage: $0 <subject> <rationale> <file> [<file> ...]" >&2
  exit 1
fi

SUBJECT="$1"; shift
RATIONALE="$1"; shift
FILES=("$@")

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Append to auto-mod-log.md BEFORE staging anything, so the log update
# is part of the same commit.
LOG="workspace/learnings/auto-mod-log.md"
SHA_PLACEHOLDER="commit-sha-pending"
TS="$(date -Iseconds)"
{
  printf '\n## %s %s [%s] %s\n' \
    "$TS" "$SHA_PLACEHOLDER" \
    "$(printf '%s ' "${FILES[@]}" | sed 's/workspace\///g')" \
    "$RATIONALE"
} >> "$LOG"

git add "$LOG" "${FILES[@]}"

# Refuse the commit if nothing actually changed in the named files
# (the log alone is not enough — that means we tried to log a no-op).
if [ -z "$(git diff --cached --name-only -- "${FILES[@]}")" ]; then
  echo "auto-commit: no file changes in $* — reverting log append" >&2
  git restore --staged "$LOG"
  git checkout -- "$LOG"
  exit 0
fi

# Commit.
git commit -m "[auto-mod] ${SUBJECT}

${RATIONALE}

Files: $(printf '%s ' "${FILES[@]}")"

# Replace the placeholder SHA in the log with the actual one, amend
# the same commit so the log stays correct.
NEW_SHA=$(git rev-parse --short HEAD)
sed -i.bak "s/${SHA_PLACEHOLDER}/${NEW_SHA}/" "$LOG"
rm -f "${LOG}.bak"
git add "$LOG"
git commit --amend --no-edit
