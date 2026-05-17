#!/usr/bin/env bash
# Local bootstrap for My_Secure_Claw (OpenClaw + Gemma 4 via Ollama).
#
# What it does:
#   1. Pulls the openclaw submodule
#   2. Installs the openclaw Node deps (pnpm)
#   3. Ensures Ollama is installed and running
#   4. Pulls the configured Gemma 4 model
#   5. Copies .env.example -> .env if missing
#
# Prereqs: bash, curl, git, Node >= 22.16 (or 24), pnpm.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

MODEL="${OPENCLAW_PRIMARY_MODEL_TAG:-gemma4:e4b}"
OLLAMA_HOST_URL="${OLLAMA_HOST:-http://127.0.0.1:11434}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

log "Syncing openclaw submodule"
git submodule update --init --recursive openclaw

log "Installing openclaw dependencies (pnpm)"
( cd openclaw && pnpm install --frozen-lockfile )

if ! command -v ollama >/dev/null 2>&1; then
  log "Installing Ollama"
  curl -fsSL https://ollama.com/install.sh | sh
fi

if ! curl -sf "$OLLAMA_HOST_URL/api/tags" >/dev/null 2>&1; then
  log "Starting Ollama daemon (background)"
  nohup ollama serve >/tmp/ollama.log 2>&1 &
  for _ in $(seq 1 20); do
    sleep 1
    curl -sf "$OLLAMA_HOST_URL/api/tags" >/dev/null 2>&1 && break
  done
fi

log "Pulling model $MODEL"
ollama pull "$MODEL"

if [ ! -f "$REPO_ROOT/.env" ]; then
  log "Creating .env from .env.example"
  cp "$REPO_ROOT/.env.example" "$REPO_ROOT/.env"
fi

log "Done. Start the gateway with: (cd openclaw && pnpm run start --config $REPO_ROOT/openclaw.json)"
