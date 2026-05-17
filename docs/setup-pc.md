# setup-pc.md — Clawbot auf dem PC in Betrieb nehmen

Komplette Schritt-für-Schritt für Windows + WSL2 + RTX 3070 / 16 GB RAM.
Ersetzt die ältere `setup-gpu.md` (die bleibt als reine GPU-Verifikations-
Referenz erhalten).

> Voll-lokales Setup. Keine Cloud-Calls. Cloud-Slot bleibt dormant.

---

## Phase 1 — Windows-Basics

```powershell
# Windows PowerShell (Admin)
wsl --install -d Ubuntu-24.04
```

Nach Reboot in WSL einloggen, User + Passwort setzen.

**Voraussetzung:** aktueller NVIDIA-Treiber für Windows (von
[nvidia.com/drivers](https://nvidia.com/drivers), **NICHT** aus
WSL-Repos). RTX 3070 → „Game Ready" oder „Studio", Version 535+.

**Check in WSL:**
```bash
nvidia-smi          # zeigt die 3070 + CUDA Version
```

Zeigt sie nichts → Windows-Treiber zu alt, neuer ziehen + Windows
neu starten.

## Phase 2 — Toolchain in WSL

```bash
sudo apt update
sudo apt install -y git curl build-essential zstd jq sqlite3

# Node 22 via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.bashrc
nvm install 22 && nvm use 22 && nvm alias default 22

# pnpm
corepack enable
corepack prepare pnpm@latest --activate

node --version    # v22.x
pnpm --version    # 10.x
```

## Phase 3 — Repo klonen & bauen

```bash
cd ~
git clone --recurse-submodules https://github.com/BEKO2210/My_Secure_Claw.git
cd My_Secure_Claw

(cd openclaw && pnpm install --frozen-lockfile && pnpm run build)
# ~45 s; Ende: "Done in XXs using pnpm vYY"
```

## Phase 4 — Ollama installieren + Modelle pullen

```bash
curl -fsSL https://ollama.com/install.sh | sh
# Installer erkennt 3070 automatisch ("NVIDIA GPU detected")

nohup ollama serve > /tmp/ollama.log 2>&1 &
sleep 3

ollama pull qwen2.5:7b-instruct-q4_K_M    # ~4.4 GB
ollama pull nomic-embed-text              # ~274 MB für RAG

ollama list                                # beide müssen erscheinen
```

## Phase 5 — `.env` Secrets

```bash
cp .env.example .env

echo "OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)" >> .env
grep -q OLLAMA_API_KEY .env || echo "OLLAMA_API_KEY=ollama-local" >> .env
echo "TELEGRAM_BOT_TOKEN=DEIN_TOKEN_HIER" >> .env    # von @BotFather
echo "CLAW_TZ=Europe/Berlin" >> .env

chmod 600 .env
```

## Phase 6 — GPU-Slot aktivieren

```bash
./scripts/claw-model.sh gpu-local
```

Erwartete Ausgabe:
```
==> active model: ollama/qwen2.5:7b-instruct-q4_K_M
==> restarting gateway
==> smoke test
reply: OK
wall_ms: 800-2000     # cold sub-2s, warm <1s
```

**GPU-Verifikation (zweites Terminal):**
```bash
ollama ps
# qwen2.5:7b-instruct-q4_K_M  ...  100% GPU

nvidia-smi --query-gpu=memory.used,utilization.gpu --format=csv
# memory.used >= 5000 MiB
# utilization.gpu >0 % während Inferenz
```

Bei `100% CPU` oder gemischtem `xx% GPU + yy% CPU` → Stopp,
troubleshoot per `setup-gpu.md` (Treiber, VRAM-Konkurrenz, `num_ctx`).

## Phase 7 — Memory-Index bauen (RAG)

```bash
node openclaw/openclaw.mjs memory index
# "Memory index updated (main)."

sqlite3 ~/.openclaw/memory/main.sqlite "SELECT COUNT(*) FROM chunks;"
# erwartet: 30+ chunks
```

## Phase 8 — Autonomie-Cron-Jobs installieren

Voraussetzung: Gateway läuft (Phase 6 hat ihn gestartet).

```bash
./scripts/install-cron-jobs.sh

node openclaw/openclaw.mjs cron list
```

Aktive Schedules ab jetzt:

| Job | Schedule | Was passiert |
|---|---|---|
| `clawbot-heartbeat-light` | alle 30 min | Patrol, OBSERVATIONS schreiben |
| `clawbot-daily-reflection` | täglich 22:00 | Daily-Narrative → `digests/daily/` |
| `clawbot-weekly-self-review` | So 21:00 | Wochen-Digest + Mind-Vorschläge |
| `clawbot-monthly-consolidation` | 1. des Monats 02:00 | Ebbinghaus-Prune |
| `clawbot-research-knowledge-gap` | alle 6 h | Nächste offene `knowledge-gap` schließen |

## Phase 9 — Telegram pairen

```bash
# In Telegram: zum Bot navigieren, irgendwas senden ("hi")
node openclaw/openclaw.mjs pairing list telegram
# Zeigt deinen Pairing-Code, gültig 1 h

node openclaw/openclaw.mjs pairing approve telegram <CODE>
# "approved"

node openclaw/openclaw.mjs status
# Telegram-Zeile zeigt "ON", nicht "SETUP"
```

Dann in Telegram: schreib „Wer bist du?" — er antwortet als Clawbot.

## Phase 10 — Erster CLI-Test (ohne Telegram)

```bash
export OPENCLAW_GATEWAY_TOKEN=$(grep OPENCLAW_GATEWAY_TOKEN .env | cut -d= -f2)
export OLLAMA_API_KEY=ollama-local
export OPENCLAW_CONFIG_PATH=$PWD/openclaw.json

node openclaw/openclaw.mjs agent --message "Wer bist du? Antworte in einem Satz."
# Erwartet: "Ich bin Clawbot, dein Tech-Sparring-Partner..."
# Cold ~10-15 s, warm <3 s
```

## Phase 11 (optional) — Always-on per systemd

Damit Clawbot 24/7 läuft, auch ohne offenes WSL-Terminal:

```bash
cd openclaw
node openclaw.mjs onboard --non-interactive \
  --flow advanced --mode local --auth-choice ollama \
  --gateway-bind lan --gateway-token-ref-env OPENCLAW_GATEWAY_TOKEN \
  --install-daemon --daemon-runtime node \
  --node-manager pnpm --secret-input-mode ref --accept-risk

systemctl --user status openclaw-gateway
journalctl --user -fu openclaw-gateway    # live logs
```

Volle Härtung (dedizierter `openclaw` System-User, `ProtectHome`,
`NoNewPrivileges`, ...) → `SECURITY.md`.

WSL2-Caveat: `systemctl --user` braucht aktivierten systemd in WSL.
In `/etc/wsl.conf`:
```ini
[boot]
systemd=true
```
Danach `wsl --shutdown` in PowerShell, neu starten.

## Quick-Reference: tägliche Befehle

```bash
./scripts/claw-model.sh                   # aktiver Slot
./scripts/claw-model.sh gpu-local         # auf GPU
./scripts/bench-model.sh qwen2.5:7b-instruct-q4_K_M    # Latenz-Check
node openclaw/openclaw.mjs status         # Gateway + Channel state
node openclaw/openclaw.mjs cron list      # Cron-Jobs anzeigen
node openclaw/openclaw.mjs memory index   # RAG-Index neu bauen
git log --oneline --grep "auto-mod"       # Was der Bot selbst geändert hat
git log --oneline -- workspace/digests    # Daily/Weekly/Monthly reflections
```

## Troubleshooting

| Symptom | First check | Fix |
|---|---|---|
| `nvidia-smi` zeigt nichts in WSL | Windows-Treiber alt | von nvidia.com/drivers neu ziehen + reboot |
| `ollama ps` → `100% CPU` | VRAM voll oder Treiber | siehe `setup-gpu.md` |
| Gateway startet nicht | `tail /tmp/gateway.log` | meist Config-Validierung — `node openclaw/openclaw.mjs config validate` |
| Agent-Turn timeout | RAM-Druck? | `free -h` + `ollama ps` — anderes Modell laden? |
| Telegram bleibt `SETUP` | Token falsch | Token nochmal von @BotFather, `.env` updaten, `./scripts/claw-model.sh gpu-local` (Restart) |
| Cron-Jobs feuern nicht | `cron.enabled: true`? | `node openclaw/openclaw.mjs cron get clawbot-heartbeat-light` |
| Bot driftet (Voice ändert sich) | git log nach `[auto-mod]` | `git revert <sha>` der problematischen SOUL-Edits |
