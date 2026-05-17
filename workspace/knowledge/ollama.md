# Knowledge: Ollama runtime behaviour

What I have verified about how Ollama behaves on this stack.

## API surfaces

- `/api/generate` — single-prompt completion. No tool calling. Fast path
  for trivial tests.
- `/api/chat` — multi-turn, supports tool calls, what OpenClaw uses.
- `/api/show` — model metadata (capabilities, template, context window).
- `/api/tags` — list installed models.
- `/api/ps` — list models currently loaded into RAM/VRAM.
- `/api/embeddings` — vector embeddings (what `nomic-embed-text` answers
  to).

**Critical for OpenClaw**: use base URL **without** `/v1` and **without**
trailing slash. `http://127.0.0.1:11434` is correct. `…/v1` breaks tool
calling — models output raw tool JSON as plain text.

## Important request options

| Option         | What                                            |
| -------------- | ----------------------------------------------- |
| `num_ctx`      | Context window for THIS request, in tokens      |
| `num_predict`  | Max tokens to generate                          |
| `temperature`  | Sampling randomness (0 = deterministic)         |
| `keep_alive`   | How long to keep model in RAM after request     |
| `think` (boolean) | Some models honour, some don't (Qwen3 ignores) |

`keep_alive` accepts: `"30m"`, `"1h"`, `0` (unload immediately), `-1`
(forever). Default ~5 min.

## Model load tax

Model has to be loaded into RAM/VRAM before first inference. Cost is
roughly proportional to model size:

| Model      | Size on disk | Cold-load (4 CPU) | Cold-load (RTX 3070) |
| ---------- | ------------ | ----------------- | -------------------- |
| gemma4:e2b | 7.2 GB       | ~190 s            | ~10 s (estimated)    |
| gemma4:e4b | 9.6 GB       | likely OOM        | ~15 s (estimated)    |
| phi4-mini  | 2.5 GB       | ~30 s             | ~5 s (estimated)     |
| qwen2.5:7b | 4.4 GB       | n/a               | ~5-10 s (target)     |

→ Always set `keep_alive: "30m"` per model in OpenClaw config so cold-load
is paid once per "warm window".

## Concurrency

- Default: one inference at a time per model.
- `OLLAMA_NUM_PARALLEL` env: how many concurrent requests for the same
  model. Default 1. Increase only if RAM/VRAM has headroom.
- `OLLAMA_MAX_LOADED_MODELS`: how many distinct models can be resident.
  Default 1 (RAM) or 3 (GPU). Increase to switch between cpu+embed
  models without unloading the chat model.

## CPU vs GPU

- Ollama auto-detects NVIDIA via `nvidia-uvm`. Verify with `ollama ps`
  → `PROCESSOR` column should say `100% GPU` for the target model.
- If `nn% GPU, mm% CPU` appears → VRAM is full, model is being partially
  offloaded. Lower `num_ctx` or kill other GPU processes.
- CPU prompt_eval rate on 4 cores: ~700-1000 tok/s.
- GPU (RTX 3070) prompt_eval rate: ~5000-10000+ tok/s.
- For a 10k-token system prompt: CPU ≈ 10-14 s, GPU ≈ 1-2 s. This is
  THE reason agent turns are slow on CPU.

## Embedding models

- `nomic-embed-text` (274 MB): standard for OpenClaw memory_search.
  768-dim embeddings, well-supported.
- `bge-m3` (≈1.2 GB): stronger multilingual, larger.
- `nomic-embed-text-v2-moe` (≈400 MB): newer multilingual MoE, used by
  the 12-Layer-Edge architecture.

## Storage layout

Models stored at `~/.ollama/models/` by default (or `OLLAMA_MODELS` env).
Each model is a manifest + blobs. Symlinks in `manifests/`, content-addressed
blobs in `blobs/`. Don't manually delete files — use `ollama rm <tag>`.

## Common failure modes

- `ECONNREFUSED 127.0.0.1:11434` → daemon dead. `nohup ollama serve &`.
- `model requires more system memory (X GiB) than is available (Y GiB)` →
  shrink `num_ctx`, drop other workloads, or pick a smaller model.
- Response is empty but `eval_count > 0` → reasoning model wrote into
  `thinking` field. Set `think:false` (works for Qwen2.5+, not Qwen3).
- `fetchWithSsrFGuard` timeout in OpenClaw logs → bumps `models.providers.
  ollama.timeoutSeconds`.

## OpenClaw + Ollama config sanity

```jsonc
"models": {
  "providers": {
    "ollama": {
      "api": "ollama",                          // NOT "openai-completions"
      "baseUrl": "http://127.0.0.1:11434",      // NO /v1, NO trailing /
      "apiKey": "OLLAMA_API_KEY",               // env-var name (literal)
      "timeoutSeconds": 360,                    // override 120s default
      "contextWindow": 8192,                    // align with hardware
      "models": [
        {
          "id": "gemma4:e2b",
          "params": {
            "num_ctx": 8192,
            "keep_alive": "30m",
            "thinking": false
          },
          ...
        }
      ]
    }
  }
}
```
