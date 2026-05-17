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
- **OS**: **(TODO confirm)** — Linux native or Windows + WSL2 with CUDA
  passthrough?
- All inference must run **fully on GPU** (no CPU offload — 16 GB RAM is
  tight)
- Local-only is the rule. Cloud is a documented dormant slot, not in use.

### Development / staging (Claude Code Web container)

- 4 vCPU, 15 GiB RAM, no GPU
- Ephemeral — anything not committed is lost
- Used for config tuning, doc writing, web research, light bench
- NOT usable for full agent turns (>200 s per turn)

## Dev stack & style **(TODO confirm)**

Inferred from this repo + the way the user writes. Confirm or correct in
next turn:

- **Languages**: Bash + Node.js/TypeScript heavy (this project), Python
  likely in other projects
- **Editor**: unknown — maybe VS Code, maybe nvim, maybe JetBrains
- **Shell**: zsh or bash; no shell-prompt customisation observed
- **Git workflow**: feature-branch → PR → user merges manually. **Never
  push to main directly.** Likes squash-merge (small commit graph on
  main).
- **Commit style**: imperative subject, max ~70 chars, optional body
  with bullet points explaining WHY. No emoji prefixes.
- **PR style**: short summary, bullet test plan, link to session.
- **CI**: not configured in this repo. Externally maybe relies on local
  validation + CodeRabbit for review.
- **Containerisation**: comfortable with Docker, has used ephemeral
  cloud containers (Claude Code Web).
- **Package manager preference**: pnpm (configured in `openclaw.json` →
  `skills.install.nodeManager`).

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

**My_Secure_Claw** = wrapper repo around OpenClaw that holds:
- `openclaw.json` — gateway config (lean, CPU-tuned)
- `scripts/claw-model.sh` — single switch point between model slots
- `scripts/bench-model.sh` + `scripts/agent-bench.sh` — measurement tools
- `workspace/` — Clawbot's mind (this directory)
- `docs/` — operator-facing setup guides (NOT bot content)
- OpenClaw itself as a git submodule under `openclaw/`

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

## Open questions for the user

- **OS on the PC** (Linux native vs Windows + WSL2)
- **Other channels** beyond Telegram (Discord, Slack, Signal, iMessage…?)
- **Existing projects** Clawbot should know about (codebase paths,
  recurring tasks, languages beyond German+English)
- **Editor / IDE** (so I know whether to suggest VS Code tasks vs
  Makefile targets vs zellij keybinds)
- **Working hours / timezone** (so heartbeat doesn't fire at 3 AM
  uselessly — though I just won't notify, so this is low-stakes)
