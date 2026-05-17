#!/usr/bin/env bash
# Bench an Ollama model with a tiny prompt and report cold + warm timings.
#
# Usage: bench-model.sh <ollama_model_tag> [<prompt>]
# Example: bench-model.sh qwen3:4b
#
# Reports (parsed from Ollama's response JSON):
#   load_ms          time to load model weights into RAM (~0 on warm)
#   prompt_eval_ms   time to process the input prompt
#   eval_ms          time to generate the response tokens
#   total_ms         end-to-end wall clock
#   eval_tps         tokens-per-second during generation

set -euo pipefail

MODEL="${1:?usage: bench-model.sh <model> [prompt]}"
PROMPT="${2:-Antworte mit genau einem Wort: OK}"
HOST="${OLLAMA_HOST:-http://127.0.0.1:11434}"

run_once() {
  local label="$1"
  local raw
  raw=$(curl -sf "$HOST/api/generate" \
    -d "$(jq -nc --arg m "$MODEL" --arg p "$PROMPT" \
            '{model:$m, prompt:$p, stream:false, think:false,
              options:{num_predict:10, num_ctx:1024, temperature:0}}')")
  jq -r --arg label "$label" --arg model "$MODEL" '
    def ms: . / 1000000 | floor;
    [
      "  " + $label + ":",
      "    total_ms         " + (.total_duration | ms | tostring),
      "    load_ms          " + (.load_duration | ms | tostring),
      "    prompt_eval_ms   " + (.prompt_eval_duration | ms | tostring),
      "    eval_ms          " + (.eval_duration | ms | tostring),
      "    eval_tokens      " + (.eval_count | tostring),
      "    eval_tps         " + ((.eval_count / (.eval_duration / 1000000000)) * 100 | floor / 100 | tostring),
      "    response         " + (.response | gsub("\n";" ")[:80])
    ] | .[]' <<<"$raw"
}

echo "model: $MODEL"
echo "prompt: $PROMPT"
run_once "cold"
run_once "warm"
