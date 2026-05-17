# RESTART.md — Clawbot von Null auf dem PC

Eine einzige Datei. Funktioniert für **frischen Install** UND
**„alles weg, neu aufsetzen"**. Du gehst von oben nach unten durch.

> Iron rule: alles via originaler OpenClaw-Tools.
> Kein `openclaw.json`-Override im Repo, kein eigener Switcher.
> Wenn du irgendwo `./scripts/claw-model.sh` o.ä. liest → veraltetes Doku-Wissen.

---

## TL;DR (du weißt schon was du tust)

```bash
# Phase 0 — wipe (überspringen wenn Erstinstallation)
sudo pkill -9 -f "openclaw|ollama"; sleep 3
mv ~/.openclaw ~/.openclaw.bak.$(date +%s) 2>/dev/null

# Phase 1 — Repo
cd ~ && rm -rf My_Secure_Claw
git clone --recurse-submodules https://github.com/BEKO2210/My_Secure_Claw.git
cd My_Secure_Claw
(cd openclaw && pnpm install --frozen-lockfile && pnpm run build && pnpm ui:build)

# Phase 2 — Ollama up + Modelle
nohup ollama serve > /tmp/ollama.log 2>&1 &
sleep 4
ollama pull qwen2.5:7b-instruct-q4_K_M
ollama pull nomic-embed-text

# Phase 3 — Wizard + Mind
node openclaw/openclaw.mjs onboard
./scripts/install-mind.sh
node openclaw/openclaw.mjs dashboard
```

Wenn das alles durchgeht: fertig. Wenn nicht: nimm den langen Pfad
unten, da steht was wo schiefgehen kann.

---

## Phase 0 — Wipe (nur wenn du schon mal installiert hattest)

> Du willst „komplett neu". Diese Phase macht alles weg was Clawbot
> jemals auf deinem PC angefasst hat. Backups bleiben, falls du
> doch was retten willst.

```bash
# 1. Laufende Prozesse killen
sudo pkill -9 -f "openclaw|ollama"
sleep 3
ss -ltn 2>/dev/null | grep -E "11434|18789|18791" && echo "noch was am Lauschen — nochmal pkill"

# 2. OpenClaw State wegsichern (NICHT löschen — Backup ist günstig)
mv ~/.openclaw ~/.openclaw.bak.$(date +%s) 2>/dev/null && echo "✓ alte ~/.openclaw weggesichert"

# 3. Repo weg
cd ~ && rm -rf My_Secure_Claw 2>/dev/null

# 4. (Optional) kaputtes snap-ollama bereinigen
which -a ollama   # falls /snap/bin/ollama auftaucht → Snap stört
sudo snap remove --purge ollama 2>/dev/null
# Wenn snap remove mit "transport endpoint not connected" scheitert:
#   in Windows-PowerShell:  wsl --shutdown
#   WSL neu starten, dann erneut sudo snap remove --purge ollama

# 5. (Optional) Ollama-Modelle behalten oder neu pullen?
#    Modelle liegen unter ~/.ollama/models/  (~5-10 GB pro Modell)
#    Wenn du Platz frei willst:
#    rm -rf ~/.ollama
#    Sonst lass sie liegen — sind unabhängig von OpenClaw und schnell genug.
```

Backup-Rollback wenn was schiefgeht: `rm -rf ~/.openclaw && mv ~/.openclaw.bak.<TIMESTAMP> ~/.openclaw`.

---

## Phase 1 — System-Voraussetzungen (einmalig pro Maschine)

### Windows + WSL2

In Windows-PowerShell (Admin):
```powershell
wsl --install -d Ubuntu-24.04
```

Reboot, WSL öffnen, User + Passwort setzen.

### NVIDIA-Treiber

Den **Game-Ready** oder **Studio**-Driver für deine RTX 3070 vom
[nvidia.com/drivers](https://nvidia.com/drivers) ziehen. **Nicht** aus
WSL-Repos. Mind. Version 535.

Test in WSL:
```bash
nvidia-smi                       # zeigt RTX 3070 + CUDA Version
ls /usr/lib/wsl/lib/libcuda.so   # muss existieren
```

Zeigt `nvidia-smi` nichts → Treiber alt → neuer von nvidia.com + Windows-Reboot.

### Toolchain in WSL

```bash
sudo apt update
sudo apt install -y git curl build-essential zstd jq sqlite3 rsync

# Node 22 via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.bashrc
nvm install 22 && nvm use 22 && nvm alias default 22

# pnpm
corepack enable && corepack prepare pnpm@latest --activate

node --version    # v22.x
pnpm --version    # 10.x+
```

---

## Phase 2 — Ollama installieren + Modelle pullen

```bash
# Falls ollama schon installiert ist UND systemd-managed (curl-Installer):
sudo systemctl disable --now ollama 2>/dev/null

# Frisch installieren (offizieller Installer, kein Snap!)
curl -fsSL https://ollama.com/install.sh | sh
# Installer-Log sollte „Nvidia GPU detected." enthalten

# Manuell starten (Models gehen nach ~/.ollama/models/)
nohup ollama serve > /tmp/ollama.log 2>&1 &
sleep 4

# Sanity-Check
curl -sf http://127.0.0.1:11434/api/tags    # antwortet {"models":[]}
grep -i "inference compute" /tmp/ollama.log
# muss zeigen: library=CUDA ... total="8.0 GiB"

# Modelle ziehen
ollama pull qwen2.5:7b-instruct-q4_K_M    # ~4.4 GB Produktionsmodell
ollama pull nomic-embed-text              # ~274 MB für RAG/memory_search

ollama list                                # beide müssen erscheinen
```

---

## Phase 3 — Repo holen + OpenClaw bauen

```bash
cd ~
git clone --recurse-submodules https://github.com/BEKO2210/My_Secure_Claw.git
cd My_Secure_Claw

(cd openclaw && pnpm install --frozen-lockfile && pnpm run build && pnpm ui:build)
# ~60-90 s; `ui:build` ist wichtig — sonst Dashboard "protocol mismatch"
```

---

## Phase 4 — OpenClaw onboard (Wizard, interaktiv)

```bash
node openclaw/openclaw.mjs onboard
```

Klick-durch:
- **Auth:** Ollama
- **Mode:** local
- **Gateway bind:** loopback (sicher) ODER lan (wenn du vom Handy aufs LAN willst)
- **Gateway auth:** token (generiert automatisch)
- **Model:** `qwen2.5:7b-instruct-q4_K_M`
- **Telegram-Token:** pasten falls vorhanden (von @BotFather), sonst skip
- **Skills:** default

Onboard schreibt `~/.openclaw/openclaw.json` + `~/.openclaw/workspace/`.

---

## Phase 5 — Mind drüberlegen

```bash
./scripts/install-mind.sh
```

Macht ein Backup vom Wizard-Workspace (`~/.openclaw/workspace.bak.<ts>`)
und kopiert unsere kuratierte Persona/Memory/Knowledge rein. Re-indexed
RAG am Ende.

Re-runnable wann immer du `workspace/*` im Repo änderst:
```bash
cd ~/My_Secure_Claw && git pull && ./scripts/install-mind.sh
```

---

## Phase 6 — Hochfahren + verifizieren

```bash
# Browser-UI öffnen
node openclaw/openclaw.mjs dashboard
# Sollte Windows-Browser auf  http://127.0.0.1:18789/?token=...  öffnen.
# Falls die UI "Protokoll stimmt nicht überein" sagt:
#   node openclaw/openclaw.mjs doctor-ui --fix
# (oder (cd openclaw && pnpm ui:build) → Browser-Tab schließen → openclaw dashboard erneut)

# CLI-Live-Test
node openclaw/openclaw.mjs agent --agent main --message "Antworte mit OK."
# Cold ~10-15 s, warm <3 s. Antwort sollte "OK" enthalten.

# GPU-Wahrheit
ollama ps
# Spalte PROCESSOR MUSS  100% GPU  zeigen. Wenn CPU → siehe Troubleshooting.

nvidia-smi --query-gpu=memory.used,utilization.gpu --format=csv
# memory.used >= 4000 MiB während Inferenz
```

---

## Phase 7 — Telegram pairen (optional)

```bash
# 1. In Telegram zum Bot navigieren (Name den du @BotFather gegeben hast)
# 2. Eine beliebige Nachricht senden ("hi")
# 3. Im WSL-Terminal:
node openclaw/openclaw.mjs pairing list telegram
node openclaw/openclaw.mjs pairing approve telegram <CODE>
node openclaw/openclaw.mjs status        # Telegram-Zeile → "ON"
```

Danach in Telegram schreiben — Clawbot antwortet mit der Persona aus
`SOUL.md`.

---

## Phase 8 (optional) — Always-on per systemd

Damit Clawbot 24/7 läuft auch ohne offenes WSL-Terminal:

```bash
# Voraussetzung: systemd in WSL aktiviert
# /etc/wsl.conf:
#   [boot]
#   systemd=true
# Dann in PowerShell:  wsl --shutdown   und WSL neu öffnen.

cd ~/My_Secure_Claw
node openclaw/openclaw.mjs onboard --non-interactive \
  --flow advanced --mode local --auth-choice ollama \
  --gateway-bind loopback --gateway-token-ref-env OPENCLAW_GATEWAY_TOKEN \
  --install-daemon --daemon-runtime node \
  --node-manager pnpm --secret-input-mode ref --accept-risk

systemctl --user status openclaw-gateway
journalctl --user -fu openclaw-gateway   # live logs
```

---

## Tägliche Befehle

```bash
node openclaw/openclaw.mjs status                                    # Gateway + Channel
node openclaw/openclaw.mjs models list                               # verfügbare Modelle
node openclaw/openclaw.mjs models set ollama/<modell>                # wechseln
node openclaw/openclaw.mjs dashboard                                 # UI öffnen
node openclaw/openclaw.mjs agent --agent main --message "..."        # CLI-Chat
node openclaw/openclaw.mjs memory index                              # RAG neu nach Mind-Update
node openclaw/openclaw.mjs logs --follow                             # Live-Logs
node openclaw/openclaw.mjs doctor                                    # Selbst-Diagnose
ollama ps                                                            # läuft Modell auf GPU?
```

---

## Troubleshooting (kurzes Inhaltsverzeichnis)

| Symptom | Erste Diagnose | Wahrscheinlicher Fix |
|---|---|---|
| `nvidia-smi` zeigt nichts in WSL | Windows-Treiber zu alt | neuer Driver von nvidia.com + Windows-Reboot |
| Dashboard: „Protokoll stimmt nicht überein" | UI-Assets veraltet | `node openclaw/openclaw.mjs doctor-ui --fix` ODER `(cd openclaw && pnpm ui:build)` + Browser-Cache leeren (Inkognito) |
| `ollama ps` zeigt `100% CPU` | GPU nicht greifbar | `tail /tmp/ollama.log` nach `inference compute=CUDA`. Wenn fehlt → systemd-Ollama läuft als ollama-user und sieht GPU nicht. Stoppen + manuell als dein user starten. |
| `ollama list` leer obwohl gepullt | falscher OLLAMA_MODELS | `OLLAMA_MODELS=~/.ollama/models nohup ollama serve > /tmp/ollama.log 2>&1 &` |
| `agent` Error „No target session" | Flag vergessen | `--agent main` ergänzen |
| Agent-Turn >60 s warm | RAM/VRAM-Druck | `free -h`, `ollama ps` — kleineres Modell ziehen |
| Snap-Ollama Error „transport endpoint not connected" | kaputter snap-Mount | in PowerShell `wsl --shutdown`, dann WSL neu, dann `sudo snap remove --purge ollama` |
| Port 11434 belegt | alter ollama-Prozess | `sudo pkill -9 -f ollama` + sleep 3 + neu starten |
| Gateway startet nicht | Config kaputt | `node openclaw/openclaw.mjs config validate`, dann `node openclaw/openclaw.mjs doctor` |
| Memory-Index = 0 chunks | Ollama oder nomic-embed-text down | `ollama list \| grep nomic-embed`, ggf. neu pullen |

---

## Was wo lebt nach dem Install

```
~/My_Secure_Claw/             ← Repo (Code + Mind-Quelle)
├── openclaw/                 ← Submodule, unverändert
├── workspace/                ← QUELLE für ~/.openclaw/workspace/ (via install-mind.sh)
├── scripts/install-mind.sh
└── docs/

~/.openclaw/                  ← RUNTIME-State (von onboard + install-mind erzeugt)
├── openclaw.json             ← gateway config (managed by `openclaw config set`)
├── workspace/                ← live mind (Bot liest + schreibt hier)
├── memory/                   ← Bot's persistent memory DB (sqlite)
├── agents/                   ← Session-State pro Agent
├── cron/                     ← geplante Jobs (falls per `openclaw cron add` registriert)
└── logs/

~/.ollama/                    ← Ollama (unabhängig)
└── models/                   ← gepullte Modelle (~5-10 GB pro Stück)
```

Beim nächsten Restart: Phase 0 räumt nur `~/My_Secure_Claw` + `~/.openclaw`
weg. Ollama-Modelle bleiben (außer du löschst `~/.ollama`).
