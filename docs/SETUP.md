# SETUP.md — PC install (WSL2 + RTX 3070)

Three phases: machine prereqs, OpenClaw wizard, mind overlay.

## Phase 1 — Machine prereqs (once per machine)

### 1.1 Windows + WSL2

```powershell
# Windows PowerShell (Admin)
wsl --install -d Ubuntu-24.04
```

Reboot. In WSL: create user + password.

### 1.2 NVIDIA driver

Install the latest **Game Ready** or **Studio** driver for your RTX 3070
from <https://nvidia.com/drivers>. **Not** from WSL repos.

In WSL:
```bash
nvidia-smi                  # must show RTX 3070 + CUDA version
ls /usr/lib/wsl/lib/libcuda.so   # must exist
```

If `nvidia-smi` is empty → Windows driver too old, reinstall, restart Windows.

### 1.3 Toolchain in WSL

```bash
sudo apt update
sudo apt install -y git curl build-essential zstd jq sqlite3 rsync

# Node 22 via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.bashrc
nvm install 22 && nvm use 22 && nvm alias default 22

# pnpm
corepack enable && corepack prepare pnpm@latest --activate

node --version && pnpm --version    # v22.x and 10.x+
```

### 1.4 Ollama (only one — kill any leftover snap install)

```bash
# Remove any old snap install (do it BEFORE the manual install)
sudo snap remove --purge ollama 2>/dev/null

# Official installer (creates /usr/local/bin/ollama + systemd service)
curl -fsSL https://ollama.com/install.sh | sh

# Disable systemd autostart (WSL2 crash-loop mitigation; we start manually)
sudo systemctl disable --now ollama 2>/dev/null

# Start Ollama as your user (models go to ~/.ollama/models)
nohup ollama serve > /tmp/ollama.log 2>&1 &
sleep 4
curl -s http://127.0.0.1:11434/api/tags    # must answer {"models":[]}
grep "inference compute" /tmp/ollama.log   # must show: library=CUDA ...

# Pull the production model + RAG embeddings
ollama pull qwen2.5:7b-instruct-q4_K_M     # ~4.4 GB
ollama pull nomic-embed-text               # ~274 MB

ollama list                                # both must appear
```

## Phase 2 — OpenClaw onboard wizard

```bash
cd ~
git clone --recurse-submodules https://github.com/BEKO2210/My_Secure_Claw.git
cd My_Secure_Claw

(cd openclaw && pnpm install --frozen-lockfile && pnpm run build && pnpm ui:build)
# ~60-90 s; ui:build is what makes the dashboard UI match the gateway

node openclaw/openclaw.mjs onboard
# Pick interactively:
#   - Auth: ollama
#   - Mode: local
#   - Gateway bind: loopback (safest) or lan (if you want LAN access)
#   - Gateway auth: token (generates a token automatically)
#   - Model: ollama/qwen2.5:7b-instruct-q4_K_M
#   - Telegram (optional): paste your @BotFather token
#   - Skills: default
```

Onboard writes `~/.openclaw/openclaw.json` and `~/.openclaw/workspace/`
with framework defaults.

## Phase 3 — Overlay the Clawbot mind

```bash
./scripts/install-mind.sh
```

Backs up the wizard-generated workspace and copies the curated mind
files in. Re-indexes RAG.

## Phase 4 — Open the UI

```bash
node openclaw/openclaw.mjs dashboard
```

If your Windows browser opens `127.0.0.1:18789/?token=...` → done.

If the dashboard prints the URL instead of opening: copy it into your
Windows browser. Use an **incognito window** the first time to avoid
stale cache hitting the protocol-mismatch error.

## Phase 5 — Verify the model runs on GPU

```bash
node openclaw/openclaw.mjs agent --agent main --message "Antworte mit OK."
# Cold ~10-15 s, warm <3 s. Reply should be "OK" or close.

ollama ps
# PROCESSOR column must show 100% GPU. If 100% CPU → see Troubleshooting.
```

## Phase 6 — Telegram pairing (optional)

```bash
# In Telegram: search for your bot (the @BotFather handle), say "hi"
node openclaw/openclaw.mjs pairing list telegram
node openclaw/openclaw.mjs pairing approve telegram <CODE>
node openclaw/openclaw.mjs status     # Telegram row → "ON"
```

Then chat with the bot in Telegram. Same Clawbot, same mind.

## Daily commands

```bash
node openclaw/openclaw.mjs status                          # gateway + channels
node openclaw/openclaw.mjs models list                     # available models
node openclaw/openclaw.mjs models set ollama/<model>       # switch
node openclaw/openclaw.mjs dashboard                       # open UI
node openclaw/openclaw.mjs memory index                    # rebuild RAG
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Dashboard: "protocol mismatch" | UI assets stale | `node openclaw/openclaw.mjs doctor-ui --fix` or rerun `pnpm ui:build` + open in incognito |
| `ollama ps` shows `100% CPU` | GPU not seen / driver | check `nvidia-smi` in WSL, `tail /tmp/ollama.log` for `inference compute=CUDA` |
| `ollama ps` shows empty after restart | wrong OLLAMA_MODELS path | `OLLAMA_MODELS=~/.ollama/models nohup ollama serve > /tmp/ollama.log 2>&1 &` |
| `agent` errors "No target session" | missing flag | add `--agent main` |
| Agent turn >60 s warm | RAM/VRAM pressure | `free -h`, `ollama ps`; pull a smaller model |
| Snap-Ollama errors "transport endpoint" | broken snap | `wsl --shutdown` in PowerShell, then back in WSL: `sudo snap remove --purge ollama` |
