# Knowledge: Clawbot's own architecture

Self-knowledge. Loaded on demand via memory_search.

## What I am, in stack-order

```
┌─────────────────────────────────────────────────────────────┐
│  User (Telegram, CLI, eventually more channels)             │
├─────────────────────────────────────────────────────────────┤
│  OpenClaw Gateway (ws://127.0.0.1:18789)                    │
│   ├─ channel sidecars (telegram, …)                          │
│   ├─ agent runtime (embedded pi-embedded-runner)             │
│   ├─ plugins: acpx, memory-core, telegram (lean default)     │
│   └─ memory_search (semantic, nomic-embed-text)              │
├─────────────────────────────────────────────────────────────┤
│  Ollama (http://127.0.0.1:11434)                            │
│   ├─ chat model (gemma4:e2b / qwen2.5:7b / …, via slot)     │
│   └─ embed model (nomic-embed-text)                          │
└─────────────────────────────────────────────────────────────┘
```

## Configuration ground truth

All ground truth lives in two files:
- `openclaw.json` — gateway config (declarative)
- `workspace/` — mind (this directory)

If runtime behaviour disagrees with these → runtime is wrong.

## Model slots

Five named slots in `scripts/claw-model.sh` → patches
`agents.defaults.model.primary` in `openclaw.json` + restarts gateway.

| Slot       | Provider/Model                              |
| ---------- | ------------------------------------------- |
| `cpu`      | `ollama/gemma4:e2b`                         |
| `gemma`    | `ollama/gemma4:e4b`                         |
| `phi`      | `ollama/phi4-mini`                          |
| `gpu-local`| `ollama/qwen2.5:7b-instruct-q4_K_M`         |
| `cloud`    | `openrouter/openai/gpt-4o-mini` (DORMANT)   |

## Memory model

- **memory-core** plugin: auto-injects MEMORY.md / SOUL.md / IDENTITY.md /
  USER.md (main session only) on every turn.
- **memory_search**: semantic search over the whole workspace using
  embeddings from `nomic-embed-text` via Ollama. Index rebuilt with
  `openclaw memory reindex`. Auto-incremental on file change in newer
  OpenClaw versions.
- **Daily logs** (`memory/YYYY-MM-DD.md`): raw, ephemeral, not auto-loaded.
  Searched via memory_search, summarised by heartbeat.
- **knowledge/**: long-lived semantic notes, one topic per file. Not
  auto-loaded; searched on demand.

## Self-reflection loop

- **Heartbeat** (every 30 min): playbook in HEARTBEAT.md. Skim today's
  daily log, surface follow-ups, propose MEMORY.md promotions.
- **End-of-day summary** (once per 24h): narrative ~500 words written into
  the day's log.
- **Conversation summarization**: at session end, key takeaways extracted
  into daily log. (Not wired up yet — open follow-up.)

## What I do NOT have (yet)

- LightRAG / graph memory (Tier C upgrade)
- facts.db with Hebbian decay (Tier C)
- Vector DB beyond memory_search default index (default is good enough
  until >500 files)
- Voice (talk-voice plugin disabled by default)
- Browser automation (disabled by default; enable per skill if needed)

## Boot/runtime invariants

1. `openclaw.json` validates clean (`openclaw config validate`).
2. Ollama daemon up at `127.0.0.1:11434`.
3. Active model resident in RAM/VRAM (`ollama ps`).
4. Gateway `/health` returns `{"ok":true,"status":"live"}`.
5. `nomic-embed-text` available for memory_search.

If any of these fails: see the diagnostics table in TOOLS.md.
