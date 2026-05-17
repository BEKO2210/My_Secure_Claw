#!/usr/bin/env bash
# install-mind.sh — copy this repo's workspace/* into ~/.openclaw/workspace/.
#
# Run AFTER `node openclaw/openclaw.mjs onboard` has finished setting up
# OpenClaw on this machine. The wizard creates a generic workspace; this
# script overlays Clawbot's curated mind files (IDENTITY, SOUL, USER,
# MEMORY, TOOLS, HEARTBEAT, AGENTS + the knowledge / learnings / goals /
# digests trees).
#
# Existing files are backed up to ~/.openclaw/workspace.bak.<timestamp>/
# before being replaced. Re-runnable safely.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}/workspace"
SRC="$REPO_ROOT/workspace"

if [ ! -d "$SRC" ]; then
  echo "error: $SRC missing — wrong repo root?" >&2
  exit 1
fi

if [ ! -d "$DEST" ]; then
  echo "error: $DEST does not exist." >&2
  echo "       Run 'node openclaw/openclaw.mjs onboard' first." >&2
  exit 1
fi

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="${DEST}.bak.${STAMP}"

echo "==> backing up current workspace to $BACKUP"
cp -a "$DEST" "$BACKUP"

echo "==> copying mind files from $SRC into $DEST"
# Skip runtime/state dirs that openclaw owns
rsync -a \
  --exclude='.openclaw/' \
  --exclude='state/' \
  --exclude='memory/' \
  "$SRC/" "$DEST/"

echo "==> rebuilding memory_search index"
node "$REPO_ROOT/openclaw/openclaw.mjs" memory index || {
  echo "warn: memory index failed — run 'node openclaw/openclaw.mjs memory index' manually once Ollama + nomic-embed-text are up." >&2
}

echo
echo "Done."
echo "  Open the UI:    node openclaw/openclaw.mjs dashboard"
echo "  Switch model:   node openclaw/openclaw.mjs models set ollama/qwen2.5:7b-instruct-q4_K_M"
echo "  Rollback mind:  rm -rf $DEST && mv $BACKUP $DEST"
