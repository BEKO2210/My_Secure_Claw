#!/usr/bin/env bash
# claw-model.sh — switch the active Clawbot model and restart the gateway.
#
# Usage:
#   claw-model.sh                # show current + available slots
#   claw-model.sh <slot|model>   # switch
#
# Slots:
#   cloud         openrouter/openai/gpt-4o-mini   (needs OPENROUTER_API_KEY)
#   gemma         ollama/gemma4:e4b               (10 GiB RAM, quality)
#   cpu           ollama/gemma4:e2b               (CPU-fast default)
#   phi           ollama/phi4-mini                (text-only alternative)
#
# Anything that contains "/" is passed through as a raw provider/model ref.
# After updating, the script restarts the gateway in the background and runs
# a one-token smoke test against the new model. Exit non-zero on failure.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"
CONFIG_FILE="$REPO_ROOT/openclaw.json"
GATEWAY_LOG="${GATEWAY_LOG:-/tmp/gateway.log}"
OLLAMA_HOST="${OLLAMA_HOST:-http://127.0.0.1:11434}"

resolve_slot() {
  case "$1" in
    cloud)  echo "openrouter/openai/gpt-4o-mini" ;;
    gemma)  echo "ollama/gemma4:e4b" ;;
    cpu)    echo "ollama/gemma4:e2b" ;;
    phi)    echo "ollama/phi4-mini" ;;
    */*)    echo "$1" ;;
    *)      return 1 ;;
  esac
}

show_status() {
  local cur
  cur=$(jq -r '.agents.defaults.model.primary // "<unset>"' "$CONFIG_FILE")
  echo "Current agents.defaults.model.primary: $cur"
  echo
  echo "Slots:"
  echo "  cloud   → openrouter/openai/gpt-4o-mini   (needs OPENROUTER_API_KEY)"
  echo "  gemma   → ollama/gemma4:e4b               (10 GiB RAM, quality)"
  echo "  cpu     → ollama/gemma4:e2b               (CPU-fast default)"
  echo "  phi     → ollama/phi4-mini                (text-only alternative)"
}

patch_config() {
  local model="$1"
  local tmp
  tmp=$(mktemp)
  jq --arg m "$model" '.agents.defaults.model.primary = $m' "$CONFIG_FILE" > "$tmp"
  mv "$tmp" "$CONFIG_FILE"
}

restart_gateway() {
  pkill -f "openclaw.mjs gateway" 2>/dev/null || true
  sleep 1
  [ -f "$ENV_FILE" ] && { set -a; . "$ENV_FILE"; set +a; }
  export OPENCLAW_CONFIG_PATH="$CONFIG_FILE"
  nohup node "$REPO_ROOT/openclaw/openclaw.mjs" gateway run --force \
    > "$GATEWAY_LOG" 2>&1 &
  for _ in $(seq 1 30); do
    sleep 1
    curl -sf http://127.0.0.1:18789/health >/dev/null && return 0
  done
  return 1
}

smoke_test() {
  local model="$1"
  local provider="${model%%/*}"
  local model_id="${model#*/}"

  case "$provider" in
    ollama)
      curl -sf "$OLLAMA_HOST/api/generate" -d "$(jq -nc --arg m "$model_id" \
        '{model:$m, prompt:"Antworte mit OK.", stream:false, think:false,
          options:{num_predict:5, temperature:0}}')" | jq -r '.response'
      ;;
    openrouter)
      [ -z "${OPENROUTER_API_KEY:-}" ] && { echo "(skipped: OPENROUTER_API_KEY not set)"; return 0; }
      curl -sf https://openrouter.ai/api/v1/chat/completions \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$(jq -nc --arg m "$model_id" '{model:$m, max_tokens:5,
              messages:[{role:"user", content:"Antworte mit OK."}]}')" \
        | jq -r '.choices[0].message.content'
      ;;
    *) echo "(unknown provider for smoke test: $provider)"; return 0 ;;
  esac
}

main() {
  if [ $# -eq 0 ]; then
    show_status
    exit 0
  fi

  local model
  if ! model=$(resolve_slot "$1"); then
    echo "error: unknown slot '$1'" >&2
    show_status >&2
    exit 1
  fi

  echo "==> active model: $model"
  patch_config "$model"

  echo "==> restarting gateway"
  if ! restart_gateway; then
    echo "error: gateway did not come up; see $GATEWAY_LOG" >&2
    exit 2
  fi

  echo "==> smoke test"
  local t0 t1 reply
  t0=$(date +%s%3N)
  reply=$(smoke_test "$model" || echo "(call failed)")
  t1=$(date +%s%3N)
  printf 'reply: %s\n' "${reply:-<empty>}"
  printf 'wall_ms: %s\n' "$((t1 - t0))"
}

main "$@"
