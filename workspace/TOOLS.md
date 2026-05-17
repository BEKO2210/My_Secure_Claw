# TOOLS.md — What's available and how I use it

> Environment-specific. Each host has its own TOOLS.md. The user's PC will
> override this when production-deployed.

## Models

Production model on the PC = `ollama/qwen2.5:7b-instruct-q4_K_M` (chosen
during `openclaw onboard`, runs fully on RTX 3070, ~4.4 GB VRAM).

Switch model:
```
node openclaw/openclaw.mjs models set ollama/<model>
node openclaw/openclaw.mjs models list
```

The repo carries no custom switcher — OpenClaw's built-in `models set`
is the canonical command and survives upstream updates.

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

## Hosts & access (env-specific)

| Alias       | Host / address               | Purpose                              |
| ----------- | ---------------------------- | ------------------------------------ |
| `dev`       | `127.0.0.1` (this container) | Ephemeral dev sandbox                |
| `pc`        | _TODO: hostname or LAN IP_   | Production target (Windows + WSL2)   |
| `pc-wsl`    | _TODO: WSL2 hostname_        | WSL2 distro on the PC                |
| `tailnet`   | _TODO: <name>.ts.net_        | Tailscale tailnet for remote gateway |
| `ollama`    | `127.0.0.1:11434`            | Local Ollama daemon                  |
| `gateway`   | `127.0.0.1:18789`            | Local OpenClaw gateway               |

SSH preferences: _user fills in when first ssh'ing from Clawbot is
needed._ Until then, I treat the PC as a separate machine I have no
direct access to.

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

The `HEARTBEAT.md` playbook is a **reference** — the wizard does NOT
register cron jobs automatically. When the user wants periodic
self-checks, register them manually:

```
node openclaw/openclaw.mjs cron add --name patrol --cron "*/30 * * * *" \
  --session main --system-event "Run HEARTBEAT.md patrol checklist."
```

See `node openclaw/openclaw.mjs cron --help` for the full schema.

## What I CAN do

- Read/write workspace files (always allowed).
- Read repo files outside workspace (allowed; do not write without explicit
  user request).
- Use `memory_search` to find prior context.
- Send Telegram messages to the paired user only (when channel is up).
- Switch models via `openclaw models set ollama/<model>` (does not need
  user approval — but always reports the switch in the reply).

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
- Changing `agents.defaults.model.primary` mid-conversation unless via
  `openclaw models set` and reported in the reply.
- Modifying SOUL.md or MEMORY.md content (the user owns these; I can
  propose changes but they confirm).

## Diagnostics quick-reference

| Symptom                                    | First check                                       |
| ------------------------------------------ | ------------------------------------------------- |
| Gateway `/health` not responding           | `pgrep -f gateway` + `tail /tmp/gateway.log`      |
| Agent turn timeout                         | `tail /tmp/gateway.log` for `model_call:started`  |
| `ECONNREFUSED 127.0.0.1:11434`             | `pgrep ollama`, restart with `nohup ollama serve` |
| Dashboard "protocol mismatch"              | `node openclaw/openclaw.mjs doctor-ui --fix` or `(cd openclaw && pnpm ui:build)` + open in incognito |
| Onboard fails                              | `openclaw config validate`                         |
| Disk pressure                              | `df -h /` + `ollama list` (largest models first)  |
| memory_search returns nothing              | `ollama list | grep nomic-embed-text`             |
