# USER.md — What I know about my human

> **Loaded only in main session** (1:1 with the user). Never in shared
> channels, group chats, or sub-agent contexts. Contains personal context.

Entries marked **(TODO confirm)** are seeded based on observation and need
the user's nod or correction before I treat them as iron.

## Handle

- GitHub: **BEKO2210**
- Repo home: `github.com/BEKO2210/My_Secure_Claw`

## Language

- **German is default.** User writes mostly German, mixed with English
  technical vocabulary. Switch to English only on request.
- Tone: direct, no-nonsense, technically literate. No need to over-explain
  basics. Idioms are fine ("Notnagel", "Wahrheits-Moment", "Wegwerf-
  Container").

## Hardware

### Production target (PC)

- **GPU**: NVIDIA RTX 3070, **8 GB VRAM** (Ampere architecture, CUDA 8.6)
- **RAM**: 16 GB (tight — don't suggest models that need ≥10 GB resident)
- **OS**: **Windows + WSL2** with NVIDIA CUDA passthrough (confirmed
  2026-05-17). Native Windows-Treiber installiert, Linux-CLI über WSL.
- All inference must run **fully on GPU** (no CPU offload — 16 GB RAM is
  tight)
- Local-only is the rule. Cloud is a documented dormant slot, not in use.

### Development / staging (Claude Code Web container)

- 4 vCPU, 15 GiB RAM, no GPU
- Ephemeral — anything not committed is lost
- Used for config tuning, doc writing, web research, light bench
- NOT usable for full agent turns (>200 s per turn)

## Dev stack & style

**I start empty here.** The user has "viel installiert was Coden angeht"
and prefers to teach me their stack through conversation, not have me
assume from one repo.

What I have observed *in this repo only* (not generalised, do not extend
to other projects unless the user confirms):

- This project uses Bash + Node.js/TypeScript and pnpm (per
  `openclaw.json` → `skills.install.nodeManager`).
- Git workflow on this repo: feature-branch → PR → user merges manually.
  Never push to main directly (per MEMORY.md iron law).
- Commit style on this repo: imperative subject ~70 chars, optional body
  with bullets explaining WHY.

When the user mentions a new language, framework, editor, shell, project,
or workflow → I log it to today's daily note and propose a USER.md
update next heartbeat. I do not pattern-match across projects.

Open invitation: when the user wants me to know something durably about
their setup, they say so or paste it in.

## Working style with me

What I have learned from this session:

- **Direct, no smalltalk.** No "Hallo", no closing pleasantries.
- **Pushes for measurements.** "Schwarz auf weiß", "miss das", "mit
  Zeitmessung" — wants concrete numbers, not estimates.
- **Aversion to Notnägel.** When I tried `timeoutSeconds: 600` as a
  workaround, the user named it Notnagel and demanded a real fix.
- **Asks back instead of guessing.** If something is ambiguous, expects
  me to ask — and gets impatient when I ask too much for trivial
  decisions.
- **Wants live verification.** "Ist das Gateway wirklich an?" → check it,
  don't report stale status.
- **Iron-rules**: voll lokal, kein Cloud-Slot aktivieren, kein
  Notnagel-Fix, kein willkürlicher Commit, kein Umbau von OpenClaw selbst.
- **Architecture discussions welcome.** When I propose tiers (A/B/C) or
  trade-offs, user reads and picks decisively. Doesn't want me to
  pre-decide silently.

## What this project is

**My_Secure_Claw** = repo that ships ONE thing on top of stock OpenClaw:
the curated mind under `workspace/`. Plus:
- `openclaw/` as an untouched git submodule (no overrides)
- `scripts/install-mind.sh` — overlays `workspace/` into
  `~/.openclaw/workspace/` after the user runs `openclaw onboard`
- `docs/` — operator-facing setup + reference

No custom `openclaw.json`, no custom switcher, no cron-installer. The
user runs the upstream wizard, we drop the mind in.

## Other projects the user is working on

**(TODO seed)** — user has not yet named other active projects. I'll
populate as they come up in conversation.

## What the user has explicitly said matters

- **Privacy / locality first.** Repo stays "voll lokal". OpenRouter slot
  is dormant placeholder, must not be activated without explicit Go.
- **Stable in dev environment first**, then production on PC.
- **No new system on top of OpenClaw** — configure OpenClaw, do not
  rebuild.
- **Workspace = mind, not setup.** Setup docs belong in `/docs/`.
- **Edge of what's technically possible** for the bot's cognition. Picked
  Tier B (Sweet Spot) for now — keeps door open to Tier C
  (12-Layer-Edge with LightRAG + facts.db) later.

## What the user has explicitly rejected

- `gemma4:e4b` on this 4-CPU container — too slow / OOM-risk.
- `qwen3:4b` for short answers — ignores `think:false`, rambles.
- Notnagel-Timeouts as a fix — they mask the real problem.
- Cloud-first defaults.

## Anti-patterns this user dislikes

- Status reports based on stale info ("Gateway läuft ✓" without
  re-checking)
- Asking when you can just do (for trivial decisions)
- Asking the same question twice
- Building a new framework when the existing one has a knob
- Multi-paragraph docstrings, comments that explain WHAT instead of WHY
- Wallpapering over real bugs with longer timeouts

## Open questions for the user (still open)

- **Other channels** beyond Telegram (Discord, Slack, Signal, iMessage…?)
- **Existing projects** the user wants me to know about (only if and when
  they decide — see "Dev stack" above; I do not infer)
- **Working hours / timezone** (so heartbeat doesn't fire at 3 AM
  uselessly — low-stakes since the heartbeat is silent by default)
- **Tailscale tailnet name** (for production gateway bind)
