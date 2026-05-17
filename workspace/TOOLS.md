# TOOLS.md — What's available and how I use it

> Environment-specific. Each host has its own TOOLS.md. The user's PC will
> override this when production-deployed.

## Models (`scripts/claw-model.sh`)

| Slot       | Model                                  | When                           |
| ---------- | -------------------------------------- | ------------------------------ |
| `cpu`      | `ollama/gemma4:e2b`                    | dev container (4 vCPU, 15 GiB) |
| `gemma`    | `ollama/gemma4:e4b`                    | when ≥10 GiB RAM is truly free |
| `phi`      | `ollama/phi4-mini`                     | tight RAM fallback             |
| `gpu-local`| `ollama/qwen2.5:7b-instruct-q4_K_M`    | PC production (RTX 3070)       |
| `cloud`    | `openrouter/openai/gpt-4o-mini`        | DORMANT — do not activate      |

To switch: `./scripts/claw-model.sh <slot>`.
Status: `./scripts/claw-model.sh` (no args).

## Memory & RAG

- **`memory-core` plugin** loads MEMORY.md, USER.md, IDENTITY.md, SOUL.md
  into every main-session turn.
- **`memory_search` tool** (when enabled) does semantic search across the
  workspace using `nomic-embed-text` via Ollama. Use it for any question
  whose answer might be in `workspace/knowledge/`, daily logs, or older
  MEMORY.md entries — DO NOT re-read those files manually if the search
  can find the chunk.

Trigger words for memory_search:
- "what do I/you know about X"
- "have we talked about X"
- "did I tell you X"
- "look up X in your notes"

## Channels (inbound message → me)

- **Telegram** (`channels.telegram`): main human channel. DM policy =
  `pairing`. Pairing codes via `openclaw pairing list telegram` → approve
  with `openclaw pairing approve telegram <CODE>`.
- All other channels: not configured. To enable: `openclaw channels add`.

## Workspace conventions

- All files in `workspace/` (except `state/` and `.openclaw/`) are loaded
  into context budget. **Hard cap 20k chars/file**, target 10-15k.
- Bigger content → `docs/` (loaded on demand via memory_search) or split
  into `workspace/knowledge/<topic>.md` chunks.
- Daily logs in `workspace/memory/YYYY-MM-DD.md`. Don't pollute main
  workspace with date-stamped files.
- Checklists in `workspace/checklists/` — step-by-step for risky ops.

## Heartbeat

- Period: every 30 min (configured in `openclaw.json` → see HEARTBEAT.md
  for the script).
- Job: skim open daily-log entries, summarise into MEMORY.md candidates,
  flush stale model session.

## What I CAN do

- Read/write workspace files (always allowed).
- Read repo files outside workspace (allowed; do not write without explicit
  user request).
- Use `memory_search` to find prior context.
- Send Telegram messages to the paired user only (when channel is up).
- Switch models via `scripts/claw-model.sh` (does not need user approval —
  but always reports the switch in the reply).

## What I CANNOT do (refuse if asked)

- Push to git remotes without explicit user OK.
- Run arbitrary shell commands as root on the host machine outside the
  workspace dir.
- Modify the `openclaw/` submodule.
- Activate the cloud slot.
- Send messages to channels the user hasn't paired with.

## What I have to ASK before doing

- Any `rm` of more than a single file the user just touched.
- Pulling a new model >2 GB (disk pressure check first).
- Changing `agents.defaults.model.primary` mid-conversation unless I'm
  using the switcher script.
- Modifying SOUL.md or MEMORY.md content (the user owns these; I can
  propose changes but they confirm).

## Diagnostics quick-reference

| Symptom                                    | First check                                       |
| ------------------------------------------ | ------------------------------------------------- |
| Gateway `/health` not responding           | `pgrep -f gateway` + `tail /tmp/gateway.log`      |
| Agent turn timeout                         | `tail /tmp/gateway.log` for `model_call:started`  |
| `ECONNREFUSED 127.0.0.1:11434`             | `pgrep ollama`, restart with `nohup ollama serve` |
| Switcher fails to come up                  | `openclaw config validate`                         |
| Disk pressure                              | `df -h /` + `ollama list` (largest models first)  |
| memory_search returns nothing              | `ollama list | grep nomic-embed-text`             |
