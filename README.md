# My_Secure_Claw — Clawbot

Fully local personal AI assistant. **OpenClaw stays original.** This repo
adds exactly one thing on top: a curated cognitive workspace
(persona + memory + semantic knowledge) that overlays a vanilla
`openclaw onboard` install.

No custom `openclaw.json`. No custom switcher. No autonomy cron.
Use the upstream wizard, then layer the mind on top.

## Get me running on the PC

→ **[`docs/RESTART.md`](docs/RESTART.md)** — one document, two flows:
    fresh install AND "wipe everything and start over". Copy-paste.

→ **[`docs/MIND.md`](docs/MIND.md)** — what each file in `workspace/`
    does and how to evolve it.

## Layout

```
.
├── openclaw/                 git submodule — upstream OpenClaw, untouched
├── workspace/                Clawbot's MIND (the only authored content)
│   ├── IDENTITY.md           who I am (300-600 chars)
│   ├── SOUL.md               persona, voice, working style
│   ├── USER.md               what the bot knows about its human
│   ├── MEMORY.md             iron-law rules + curated long-term memory
│   ├── TOOLS.md              what the bot can / can't do
│   ├── AGENTS.md             boot sequence + per-turn loop
│   ├── HEARTBEAT.md          playbook for periodic self-checks (opt-in)
│   ├── knowledge/            on-demand semantic notes (RAG)
│   ├── learnings/            structured self-learning files
│   ├── goals/                explicit goal queue
│   └── digests/              daily / weekly / monthly reflections (empty)
├── docs/
│   ├── RESTART.md            the install / re-install guide
│   └── MIND.md               what each workspace file is for
└── scripts/
    └── install-mind.sh       overlay workspace/ → ~/.openclaw/workspace/
```

## The only commands you actually need

Everything goes through OpenClaw's own CLI:

| What you want | Command |
|---|---|
| Initial setup | `node openclaw/openclaw.mjs onboard` |
| Overlay the mind | `./scripts/install-mind.sh` |
| Open the UI | `node openclaw/openclaw.mjs dashboard` |
| Switch model | `node openclaw/openclaw.mjs models set ollama/<model>` |
| Change any config | `node openclaw/openclaw.mjs config set <path> <value>` |
| Rebuild RAG index | `node openclaw/openclaw.mjs memory index` |
| Self-diagnose | `node openclaw/openclaw.mjs doctor` |
| Status | `node openclaw/openclaw.mjs status` |
| Live logs | `node openclaw/openclaw.mjs logs --follow` |

If you find yourself wanting to write a wrapper script for any of
these → don't. Use the original tool. That's iron law #12 in
`workspace/MEMORY.md`.

## Updating the mind

Edit anything under `workspace/`, commit, push. On the PC:
```bash
cd ~/My_Secure_Claw && git pull && ./scripts/install-mind.sh
```

## Updating OpenClaw

```bash
cd ~/My_Secure_Claw
git submodule update --remote openclaw
(cd openclaw && pnpm install --frozen-lockfile && pnpm run build && pnpm ui:build)
node openclaw/openclaw.mjs doctor
```
