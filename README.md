# My_Secure_Claw — Clawbot

A fully local personal AI assistant. **OpenClaw stays original** — we add
only one thing: a curated cognitive workspace (persona + memory +
semantic knowledge) that gets dropped into a vanilla OpenClaw install.

No custom `openclaw.json`. No custom switcher. No autonomy cron. Use the
upstream wizard, then layer the mind on top.

## Layout

```
.
├── openclaw/         git submodule — upstream OpenClaw, untouched
├── workspace/        Clawbot's MIND (this is the only authored content)
│   ├── IDENTITY.md
│   ├── SOUL.md       persona, voice, working style
│   ├── USER.md       what the bot knows about its human
│   ├── MEMORY.md     iron-law rules + curated long-term memory
│   ├── TOOLS.md      what the bot can do, what it can't
│   ├── HEARTBEAT.md  reference playbook (manual cron later)
│   ├── AGENTS.md     boot sequence + per-turn loop
│   ├── knowledge/    semantic notes (loaded on demand via RAG)
│   ├── learnings/    structured self-learning files
│   ├── goals/        explicit goal queue
│   └── digests/      daily / weekly / monthly reflections (empty)
├── docs/             operator-facing reference
│   └── MIND.md       what each workspace file is for
└── scripts/
    └── install-mind.sh   overlay workspace into ~/.openclaw/workspace
```

## 3-step install on your PC (WSL2 + RTX 3070)

```bash
# 1. Toolchain (one time): WSL2 Ubuntu 24.04, NVIDIA driver on Windows
#    (https://nvidia.com/drivers), Node 22 (via nvm), pnpm, Ollama.
#    See docs/SETUP.md for the full list.

# 2. Clone + build OpenClaw + onboard with the upstream wizard
git clone --recurse-submodules https://github.com/BEKO2210/My_Secure_Claw.git
cd My_Secure_Claw
(cd openclaw && pnpm install --frozen-lockfile && pnpm run build && pnpm ui:build)

ollama pull qwen2.5:7b-instruct-q4_K_M    # ~4.4 GB
ollama pull nomic-embed-text              # ~274 MB

node openclaw/openclaw.mjs onboard
# Pick: Ollama provider, qwen2.5:7b-instruct-q4_K_M model,
# generate gateway token, optional Telegram bot token

# 3. Overlay the Clawbot mind
./scripts/install-mind.sh
node openclaw/openclaw.mjs dashboard
```

The dashboard opens in your browser. Done.

## Daily commands

```bash
node openclaw/openclaw.mjs status                          # gateway + channels
node openclaw/openclaw.mjs models list                     # available models
node openclaw/openclaw.mjs models set ollama/<model>       # switch model
node openclaw/openclaw.mjs dashboard                       # open UI
node openclaw/openclaw.mjs agent --agent main --message "Wer bist du?"
node openclaw/openclaw.mjs memory index                    # rebuild RAG after mind edits
```

## Updating the mind

Edit any file under `workspace/`, commit, push. On the PC pull, then:

```bash
./scripts/install-mind.sh    # re-overlays + re-indexes
```

The script backs up your current `~/.openclaw/workspace/` first; rollback
shown at the end of its output.

## Updating OpenClaw

```bash
git submodule update --remote openclaw
(cd openclaw && pnpm install --frozen-lockfile && pnpm run build && pnpm ui:build)
node openclaw/openclaw.mjs dashboard    # re-verify UI protocol matches
```

## Why no custom openclaw.json

OpenClaw is a moving target. Every custom override is a future merge
conflict and a candidate for breakage. The onboard wizard generates a
config that matches the installed gateway version exactly. We layer
content (`workspace/`), not config.

If a setting truly needs to change permanently, use `openclaw config
set <path> <value>` — that survives upstream updates.
