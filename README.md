# My_Secure_Claw — Clawbot

A fully local personal AI assistant. OpenClaw shell around a Gemma 4 brain via
Ollama, with a curated cognitive workspace (persona + memory + semantic
knowledge), nomic-embed-text RAG, and a single-point model switcher between
local CPU, local GPU, and a dormant cloud slot.

OpenClaw itself lives as a git submodule under `./openclaw/`. We **configure**
OpenClaw — we never modify its internals.

## Layout

```
.
├── openclaw/               # git submodule — upstream OpenClaw
├── openclaw.json           # gateway config (lean, CPU-tuned)
├── workspace/              # Clawbot's MIND (loaded into agent context)
│   ├── IDENTITY.md         # who I am
│   ├── SOUL.md             # persona, voice, values, working style
│   ├── USER.md             # what I know about the human (main session only)
│   ├── MEMORY.md           # iron-law rules + curated long-term memory
│   ├── TOOLS.md            # what I can do, what I can't
│   ├── HEARTBEAT.md        # periodic self-reflection playbook
│   ├── AGENTS.md           # boot sequence + operating rules
│   ├── memory/YYYY-MM-DD.md   # daily session logs
│   └── knowledge/          # semantic knowledge tree (RAG)
│       ├── clawbot-self.md
│       ├── openclaw.md
│       ├── ollama.md
│       └── hardware.md
├── docs/                   # operator-facing docs (NOT bot content)
│   ├── MODELS.md           # model-switcher reference
│   └── setup-gpu.md        # PC + RTX 3070 production install guide
├── scripts/
│   ├── setup.sh            # one-shot bootstrap (submodule + pnpm + Ollama + models)
│   ├── claw-model.sh       # single switch point between model slots
│   ├── bench-model.sh      # direct Ollama API latency check
│   └── agent-bench.sh      # full agent-harness latency matrix
└── SECURITY.md             # what runs as root, migration plan to non-root
```

## Requirements

- Linux / macOS / Windows + WSL2
- Node **22.16+** or **24**
- pnpm 10+
- ~12 GB free disk (Gemma 4 e2b + phi4-mini + nomic-embed-text)
- 16 GB RAM minimum; PC production target = RTX 3070 / 8 GB VRAM

## Quick start

```bash
git clone --recurse-submodules https://github.com/BEKO2210/My_Secure_Claw.git
cd My_Secure_Claw
./scripts/setup.sh
cp .env.example .env       # then: openssl rand -hex 32 → OPENCLAW_GATEWAY_TOKEN
ollama pull nomic-embed-text                                # RAG embeddings
ollama pull qwen2.5:7b-instruct-q4_K_M                      # if you have GPU
(cd openclaw && node openclaw.mjs memory index)             # build RAG index
./scripts/claw-model.sh cpu        # or `gpu-local` on the PC
```

## Model slots

| Slot       | Model                                  | When                           |
| ---------- | -------------------------------------- | ------------------------------ |
| `cpu`      | `ollama/gemma4:e2b`                    | CPU box, multimodal            |
| `gemma`    | `ollama/gemma4:e4b`                    | when ≥10 GiB RAM is truly free |
| `phi`      | `ollama/phi4-mini`                     | tight RAM fallback             |
| `gpu-local`| `ollama/qwen2.5:7b-instruct-q4_K_M`    | RTX 3070 production target     |
| `cloud`    | `openrouter/openai/gpt-4o-mini`        | **dormant** — do not activate  |

See `docs/MODELS.md` for measured latencies and the trade-offs.

## Memory & RAG

- **Always-loaded** into the system prompt by the `memory-core` plugin:
  IDENTITY.md, SOUL.md, MEMORY.md (main session only), USER.md (main session
  only), TOOLS.md, AGENTS.md, HEARTBEAT.md.
- **Searched on demand** via `memory_search` (semantic + keyword hybrid,
  768-dim embeddings from `nomic-embed-text`): all of `workspace/knowledge/`,
  daily logs in `workspace/memory/`, and checklists.
- **Hard caps**: 20 000 chars per file, ~150 000 chars total for the
  bootstrap set. Spillover goes to `knowledge/` or `docs/`.
- **Rebuild the index**: `node openclaw/openclaw.mjs memory index`.

## Self-reflection

Heartbeat fires every 30 min (configurable in `openclaw.json` →
`agents.defaults.heartbeat`). It runs the playbook in
`workspace/HEARTBEAT.md`: skims today's daily log, surfaces follow-ups,
proposes MEMORY.md promotions. End-of-day summary is appended to the day's
log. Nothing is sent to the user without an explicit prompt.

## Updating OpenClaw

```bash
git submodule update --remote openclaw
(cd openclaw && pnpm install --frozen-lockfile && pnpm run build)
node openclaw/openclaw.mjs config validate
```

## Security

See `SECURITY.md`. The dev container runs everything as root and bind `lan`.
For the PC install: dedicated `openclaw` system user, `systemd --user` with
hardening (`NoNewPrivileges`, `ProtectHome=read-only`, …), token from
`EnvironmentFile=/etc/openclaw/gateway.env` (mode 0600, owned root:openclaw).
