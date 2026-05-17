# My_Secure_Claw

OpenClaw — personal AI assistant — wired up to run locally with **Gemma 4** via **Ollama**.

OpenClaw itself lives as a git submodule under `./openclaw/`. This repo only carries:

- `openclaw.json` — Gateway config pointing OpenClaw at a local Ollama daemon and `gemma4:e4b`
- `.env.example` — environment variables (gateway token, Ollama host, model)
- `scripts/setup.sh` — one-shot bootstrap (submodule sync, pnpm install, Ollama install, model pull)

## Requirements

- Linux / macOS / Windows + WSL2
- Node **22.16+** or **24**
- pnpm 10+
- ~6 GB free disk for the `gemma4:e4b` model
- 8 GB RAM minimum (16 GB recommended for the e4b model on CPU)

## Quick start

```bash
git clone --recurse-submodules https://github.com/BEKO2210/My_Secure_Claw.git
cd My_Secure_Claw
./scripts/setup.sh
cp .env.example .env       # generate a gateway token: openssl rand -hex 32
(cd openclaw && pnpm run start --config ../openclaw.json)
```

The setup script:

1. Initialises the `openclaw` submodule
2. Runs `pnpm install` in `openclaw/`
3. Installs Ollama if missing and starts the daemon
4. Pulls `gemma4:e4b` (~4 GB)

## Switching the model

Edit `openclaw.json` → `agents.defaults.model.primary` and pull the new tag with `ollama pull <tag>`. Suggested variants:

| Tag             | Params | Use case               |
| --------------- | ------ | ---------------------- |
| `gemma4:e2b`    | 2B     | mobile / very low RAM  |
| `gemma4:e4b`    | 4B     | edge / 8–16 GB RAM     |
| `gemma4:26b`    | 26B (MoE, 4B active) | consumer GPU |
| `gemma4:31b`    | 31B dense | workstation GPU     |

## Verifying

```bash
curl -s http://127.0.0.1:11434/api/tags | jq '.models[].name'
(cd openclaw && node openclaw.mjs models list --provider ollama)
```

## Updating OpenClaw

```bash
git submodule update --remote openclaw
(cd openclaw && pnpm install --frozen-lockfile)
```
