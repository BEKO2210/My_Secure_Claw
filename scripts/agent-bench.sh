#!/usr/bin/env bash
# agent-bench.sh — measure full-agent-turn wall clock per (model, tool-profile, message).
#
# Differs from bench-model.sh which only measures the raw Ollama /api/generate call.
# This script drives the actual `openclaw agent --message ...` path so the numbers
# include the system prompt, tool schemas, and the full agent loop — i.e. what a
# user actually pays per turn.
#
# Usage: agent-bench.sh [out_file]
#   out_file defaults to ./agent-bench-results.md
#
# Matrix:
#   models   = ollama/gemma4:e2b, ollama/phi4-mini
#   profiles = coding (full), minimal
#   msgs     = "simple" (no tool needed), "tool" (needs file-read)
# = 8 turns. Each capped at 240s.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$REPO_ROOT/openclaw.json"
GATEWAY_LOG="${GATEWAY_LOG:-/tmp/gateway.log}"
OUT="${1:-$REPO_ROOT/agent-bench-results.md}"
PER_CALL_TIMEOUT="${PER_CALL_TIMEOUT:-240}"

cd "$REPO_ROOT"
[ -f .env ] && { set -a; . ./.env; set +a; }
export OPENCLAW_CONFIG_PATH="$CONFIG"
export OLLAMA_API_KEY="${OLLAMA_API_KEY:-ollama-local}"
export OPENCLAW_GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-$(openssl rand -hex 32)}"

patch_config() {
  local model="$1" profile="$2" tmp
  tmp=$(mktemp)
  jq --arg m "$model" --arg p "$profile" \
    '.agents.defaults.model.primary = $m | .tools.profile = $p' \
    "$CONFIG" > "$tmp"
  mv "$tmp" "$CONFIG"
}

restart_gateway() {
  pkill -f "openclaw.mjs gateway" 2>/dev/null || true
  sleep 1
  nohup node openclaw/openclaw.mjs gateway run --force > "$GATEWAY_LOG" 2>&1 &
  for _ in $(seq 1 30); do
    sleep 1
    curl -sf http://127.0.0.1:18789/health >/dev/null && return 0
  done
  return 1
}

run_turn() {
  local model="$1" profile="$2" msg_label="$3" message="$4"
  local session_id="bench-$(date +%s)-$RANDOM"
  local t0 t1 wall_ms rc reply

  t0=$(date +%s%3N)
  if reply=$(timeout "$PER_CALL_TIMEOUT" node openclaw/openclaw.mjs agent \
              --agent main --model "$model" --thinking off \
              --session-id "$session_id" --timeout $((PER_CALL_TIMEOUT - 10)) \
              --message "$message" 2>/dev/null | tr '\n' ' '); then
    rc="ok"
  else
    rc="TIMEOUT"
    reply="-"
  fi
  t1=$(date +%s%3N)
  wall_ms=$((t1 - t0))
  reply="${reply:0:60}"
  printf '| `%s` | %s | %s | %s | %s ms | %s |\n' \
    "$model" "$profile" "$msg_label" "$rc" "$wall_ms" "$reply" \
    | tee -a "$OUT"
}

models=("ollama/gemma4:e2b" "ollama/phi4-mini")
profiles=("coding" "minimal")
msg_simple="Antworte mit einem Wort: OK"
msg_tool="Lies die Datei IDENTITY.md aus dem Workspace und sag mir den Wert hinter '- **Name:**' in genau einem Wort."

{
  echo "# Agent-Harness Bench"
  echo
  echo "Per-call timeout: ${PER_CALL_TIMEOUT}s. Each turn is a fresh session-id (no warmup advantage)."
  echo "Wall = full \`openclaw agent --message\` invocation including gateway round-trip + system prompt + tool schemas."
  echo
  echo "| Model | Profile | Message | Status | Wall | Reply (first 60 chars) |"
  echo "|---|---|---|---|---|---|"
} > "$OUT"

for model in "${models[@]}"; do
  for profile in "${profiles[@]}"; do
    patch_config "$model" "$profile"
    if ! restart_gateway; then
      printf '| `%s` | %s | (any) | GATEWAY_DOWN | - | gateway failed to come up |\n' \
        "$model" "$profile" | tee -a "$OUT"
      continue
    fi
    run_turn "$model" "$profile" "simple" "$msg_simple"
    run_turn "$model" "$profile" "tool"   "$msg_tool"
  done
done

# leave the gateway on a sane default
patch_config "ollama/gemma4:e2b" "coding"
restart_gateway || true

echo >> "$OUT"
echo "Done. Results: $OUT" 1>&2
