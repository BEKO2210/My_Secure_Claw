# USER.md — What I know about my human

> **Loaded only in main session** (1:1 with the user). Never in shared
> channels, group chats, or sub-agent contexts. Contains personal context.

## Handle

- GitHub: **BEKO2210**
- Repo home: `github.com/BEKO2210/My_Secure_Claw` (this one)

## Language

- **German is default.** User writes mostly German. Switch to English only on
  request.
- Tone: direct, no-nonsense, technically literate. No need to over-explain
  basics.

## Hardware profile

### Production target (PC)

- **GPU**: NVIDIA RTX 3070, **8 GB VRAM**
- **RAM**: 16 GB (knapp — don't suggest models that need ≥10 GB resident)
- **OS**: not yet declared — assume Linux or Windows + WSL2
- All inference must run **fully on GPU** (no CPU offload — 16 GB RAM is tight)
- Local-only is the rule. Cloud is a documented dormant slot, not in use.

### Development / staging (Claude Code Web container)

- 4 vCPU, 15 GiB RAM, no GPU
- Ephemeral — anything not committed is lost
- Used for config tuning, doc writing, web research, light bench
- NOT a usable agent environment for full turns (200+ s per turn)

## What this project is

**My_Secure_Claw** = wrapper repo around OpenClaw that holds:
- `openclaw.json` — gateway config (lean, CPU-tuned)
- `scripts/claw-model.sh` — single switch point between model slots
  (cpu / gemma / phi / gpu-local / cloud)
- `scripts/bench-model.sh` + `scripts/agent-bench.sh` — measurement tools
- `workspace/` — Clawbot's mind (this directory)
- `docs/` — operator-facing setup guides (NOT bot content)
- OpenClaw itself as a git submodule under `openclaw/`

## What the user has explicitly said matters

- **Privacy / locality first.** Repo stays "voll lokal". OpenRouter slot
  is dormant placeholder, must not be activated without explicit Go.
- **Stable in dev environment first**, then production on PC.
- **No new system on top of OpenClaw** — configure OpenClaw, do not rebuild.
- **Workspace = mind, not setup.** Setup docs belong in `/docs/`.
- **Edge of what's technically possible** for the bot's cognition (logic,
  semantic knowledge, memory). User wants the best they have seen.

## What the user has explicitly rejected

- `gemma4:e4b` on this 4-CPU container — too slow / OOM-risk.
- `qwen3:4b` for short answers — ignores `think:false`, rambles.
- Notnagel-Timeouts as a fix — they mask the real problem.
- Cloud-first defaults.

## Open questions (ask the user when relevant)

- OS of the PC (Linux vs Windows + WSL2) — affects setup-gpu.md
- Which channels will be wired up beyond Telegram? (Discord, Slack, Signal,
  iMessage…?)
- Any specific projects Clawbot should know about (codebases, recurring
  tasks)?
- Languages besides German + English the bot should fluently switch into?

## Anti-patterns this user dislikes

- Status reports based on stale info ("Gateway läuft ✓" without re-checking)
- Asking when you can just do
- Asking the same question twice
- Building a new framework when the existing one has a knob
- Multi-paragraph docstrings, comments that explain WHAT instead of WHY
