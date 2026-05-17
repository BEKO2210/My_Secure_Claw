# MEMORY.md — Iron-law rules + curated long-term memory

> Distilled from daily logs. **Only load in main session.** Update when a fact
> proves durable across multiple sessions.

## Iron laws (never break, no exceptions)

1. **Never push to `main` directly.** Always feature-branch → PR → user merges.
2. **Never commit without explicit user request.** Never volunteer commits.
3. **Never activate the cloud slot** (`openrouter/...`) without explicit user
   Go + an `OPENROUTER_API_KEY` they personally placed.
4. **Never modify OpenClaw internals** (the `openclaw/` submodule). We
   configure, we don't rebuild. If a feature is missing → file an upstream
   issue, do not patch the submodule.
5. **Workspace files = mind.** Setup/ops docs go to `/docs/`. Bot-content
   stays in `workspace/`.
6. **No state in MEMORY.md that doesn't belong to the user.** No
   self-aggrandizing entries, no model-version trivia, no session noise.

## Things I have learned about how Clawbot behaves on CPU

- `gemma4:e2b` cold-load on 4-CPU CPU = **~190 s** (model weights from disk
  into RAM via mmap). Warm = **~9 s** for trivial chat call. → Always set
  `params.keep_alive: "30m"` (or longer) per model so we pay the load tax
  only once.
- The OpenClaw agent-harness injects ~10-20k+ tokens of system prompt
  (workspace files + tool schemas + memory + safety). On 4 CPU cores this
  alone is ≥30 s prompt_eval. On a real GPU it's <5 s. → CPU container is
  for config + writing + light bench, NOT for live agent turns.
- `tools.profile: "coding"` adds many tool schemas. `localModelLean: true`
  strips browser/cron/message tools. Use lean unless we actually need them.
- 3 plugins is enough for a basic chat bot (acpx, memory-core, telegram).
  Disable: canvas, browser, talk-voice, phone-control, file-transfer,
  device-pair when not in active use.
- `models.providers.ollama.timeoutSeconds` is the real watchdog knob. The
  old `agents.defaults.llm.idleTimeoutSeconds` is deprecated.
- `${VAR}` substitution in `agents.defaults.model.primary` does NOT work —
  must be a literal string. Switcher patches the JSON with jq instead.

## Things I have learned about Gemma 4 + Qwen on Ollama

- `gemma4:e4b` (9.6 GB) needs ~10 GiB free RAM resident. On a 16 GB box,
  with any other process running, risk of OOM is real.
- `gemma4:e2b` (7.2 GB) fits comfortably and is faster per token on CPU
  (~28 tok/s warm direct API).
- `qwen3:*` is a **reasoning model**: `think:false` field is ignored. The
  budget gets burned in the `thinking` field, response stays empty. → Use
  `qwen2.5:*` instead for predictable short answers.
- `phi4-mini` (3.8B, 2.5 GB) is a viable text-only alternative on CPU —
  smaller footprint, ~10 tok/s, gives clean short answers.

## Switcher slots and their intended use

- `cpu` → `ollama/gemma4:e2b` — daily driver on CPU dev container.
- `gemma` → `ollama/gemma4:e4b` — quality, requires real RAM headroom.
- `phi` → `ollama/phi4-mini` — fallback when RAM is tight.
- `gpu-local` → `ollama/qwen2.5:7b-instruct-q4_K_M` — **production target on
  the PC (RTX 3070 / 8 GB VRAM)**. Fits Q4_K_M ~4.4 GB + KV cache.
- `cloud` → dormant placeholder. Never activate without user Go.

## Decisions the user has locked in

- **2026-05-17:** "voll lokal" — repo stays local, cloud slot dormant.
- **2026-05-17:** GPU production target = RTX 3070 / 8 GB VRAM / 16 GB RAM.
  Model must stay fully GPU-resident (no CPU offload).
- **2026-05-17:** Workspace = bot mind, not setup. Setup docs live in `/docs/`.
- **2026-05-17:** Edge-of-possible cognition: RAG + self-reflection +
  conversation summarization + curated knowledge tree.

## Long-running threads / open work

- Workspace cognitive build: SOUL/USER/MEMORY/TOOLS/HEARTBEAT/AGENTS +
  knowledge/-tree (this commit).
- nomic-embed-text install + memory_search wiring (this commit).
- Heartbeat cron for nightly self-reflection (this commit).
- Test agent-turn through full new workspace — only practical on the PC.

## What to write into MEMORY.md vs daily logs

| Goes here (MEMORY.md) | Goes to memory/YYYY-MM-DD.md |
| --- | --- |
| Iron laws, durable rules | Today's events, conversations |
| Things true across many sessions | Things true for one session |
| User-confirmed preferences | Hypotheses, in-progress findings |
| Repeatedly-violated lessons | Single mistakes |

When in doubt → daily log first. Promote to MEMORY.md only after the same
fact survives two or three daily logs.
