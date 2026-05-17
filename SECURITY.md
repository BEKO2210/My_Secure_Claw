# SECURITY.md — Was läuft als root, und wie kommen wir davon weg

Diese Datei dokumentiert das aktuelle Sicherheitsprofil und die Schritte,
um die Produktiv-Installation auf einem Nicht-Root-User aufzusetzen.
**In diesem Wegwerf-Container (Claude-Code-Web-Session) wird NICHTS gefixt** —
das hier ist die Anleitung für deine PC-Maschine.

## Ist-Zustand (Container, ephemer)

| Komponente            | Läuft als | State-Pfad                             |
| --------------------- | --------- | -------------------------------------- |
| `ollama serve`        | `root`    | `/root/.ollama/` (Modelle ~9 GB)       |
| `openclaw gateway`    | `root`    | `/root/.openclaw/` (config, sessions)  |
| Modell-Inferenz       | `root`    | erbt vom ollama-Prozess                |
| Tool-Ausführung (Bash, file ops) | `root` | erbt vom gateway-Prozess  |
| Telegram-Sidecar      | `root`    | erbt vom gateway-Prozess               |

Bind: `lan` auf `0.0.0.0:18789`. Im Container ohne externe NIC harmlos, auf
einer echten Maschine im LAN exponiert (Token-Auth aktiv, aber Angriffsfläche
größer als nötig).

## Konkrete Risiken

1. **Privilege-Eskalation durch Bot:** Wenn der Agent eine Skill wie
   `coding-agent`, `github`, oder Shell-Tools nutzt, läuft alles als root.
   Bug in einem Plugin = root-RCE in deinem Heimnetz.
2. **Symlink-Surface:** OpenClaw materialisiert `plugin-skills/`-Symlinks ins
   Repo. Als root kann der Bot überall schreiben — auch `/etc`, `/root/.ssh`,
   etc.
3. **Secrets-Permissions inkonsistent:** `/root/.openclaw/identity/` ist
   `0700`, `/root/.openclaw/acpx/` ist `0755`. Beides als root, aber das
   `0755` ist trotzdem unsauber für die spätere Migration.
4. **Telegram-Bot als root:** Eingehende Nachrichten triggern Code, der
   alle Tools auf root-Privilegien hat. Wer auch immer den Bot anschreibt,
   spricht effektiv mit deinem `root`.
5. **`pkill -f openclaw.mjs gateway`** im Switcher ist root-only sicher;
   unter unprivilegiertem User vermeidbar via PID-File.
6. **Gateway-Token war im `.env` als plaintext.** Auf der PC-Maschine via
   `--secret-input-mode ref` und `OPENCLAW_GATEWAY_TOKEN`-Env aus einem
   geschützten Source (systemd `EnvironmentFile=`, gnome-keyring, age).

## Soll-Zustand (PC-Produktion)

### 1. Dedizierten Systemuser anlegen

```bash
sudo adduser --system --group --home /home/openclaw --shell /bin/bash openclaw
sudo usermod -aG video openclaw       # NVIDIA-GPU-Zugriff
sudo usermod -aG ollama openclaw      # falls Ollama als eigener User läuft
```

### 2. State-Verzeichnis isolieren

```bash
sudo install -d -o openclaw -g openclaw -m 0750 /home/openclaw/.openclaw
sudo install -d -o openclaw -g openclaw -m 0750 /home/openclaw/.ollama
```

Im Repo / in `.env`:
```bash
OPENCLAW_STATE_DIR=/home/openclaw/.openclaw
OLLAMA_MODELS=/home/openclaw/.ollama/models
```

### 3. Ollama als eigenen User laufen lassen

Der Ollama-Installer legt schon einen `ollama`-Systemuser an. **NICHT
deaktivieren.** Stattdessen den Daemon dort lassen und Clawbot nur lesend
auf den Socket zugreifen lassen.

### 4. OpenClaw Gateway als systemd-User-Service

```ini
# /etc/systemd/system/openclaw-gateway.service
[Unit]
Description=OpenClaw Gateway
After=network.target ollama.service

[Service]
Type=simple
User=openclaw
Group=openclaw
WorkingDirectory=/home/openclaw/clawbot
EnvironmentFile=/etc/openclaw/gateway.env
ExecStart=/usr/bin/node /home/openclaw/clawbot/openclaw/openclaw.mjs gateway run
Restart=on-failure
RestartSec=5

# Hardening
NoNewPrivileges=yes
PrivateTmp=yes
ProtectHome=read-only
ProtectSystem=strict
ReadWritePaths=/home/openclaw/.openclaw /home/openclaw/clawbot
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
RestrictNamespaces=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM

[Install]
WantedBy=multi-user.target
```

Aktivieren:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now openclaw-gateway
```

### 5. Gateway-Bind auf loopback einschränken, dann Reverse-Proxy

`openclaw.json`:
```json
"gateway": { "bind": "loopback", ... }
```

Wenn Mobil/LAN-Zugriff nötig: nginx oder Caddy mit TLS + Auth davor, oder
Tailscale-only (`gateway.bind: "tailnet"` + `gateway.tailscale.mode: "serve"`).

### 6. Gateway-Token rotieren + sicher hinterlegen

```bash
sudo install -d -m 0700 /etc/openclaw
sudo touch /etc/openclaw/gateway.env
sudo chmod 0600 /etc/openclaw/gateway.env
sudo chown root:openclaw /etc/openclaw/gateway.env
echo "OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)" | sudo tee /etc/openclaw/gateway.env
```

Der Service liest `EnvironmentFile=/etc/openclaw/gateway.env`. `openclaw`-User
darf die Datei nur lesen, nicht überschreiben.

### 7. Channel-Tokens (Telegram, Slack, …)

Selbe Schiene: in `/etc/openclaw/channels.env`, mode 0640, group `openclaw`,
service liest beide via `EnvironmentFile=`.

### 8. Repo-Schreibrechte einschränken

```bash
sudo chown -R openclaw:openclaw /home/openclaw/clawbot
sudo find /home/openclaw/clawbot -type d -exec chmod 0750 {} \;
sudo find /home/openclaw/clawbot -type f -exec chmod 0640 {} \;
sudo chmod +x /home/openclaw/clawbot/scripts/*.sh
```

Damit kann auch ein erfolgreicher Plugin-Exploit den Bot-Code nicht modifizieren
(write geht nur in `~/.openclaw/`).

### 9. Skill-Sandboxen

Wo möglich: `openclaw sandbox`-Subcommand für Skills nutzen, die externe CLIs
laufen lassen (z.B. `coding-agent`, `gh`). Docs:
<https://docs.openclaw.ai/cli/sandbox>.

### 10. Backup

```bash
openclaw backup create --output /var/backups/openclaw/$(date +%F).tar.zst
```

Per cron + offsite (rsync to Tailnet-Peer oder restic to S3). Sessions-Memory
ist die wertvollste Datei.

## Was im Container _trotzdem_ stimmen muss

Auch wenn nichts produktiv hier läuft, vermeiden wir:
- `--secret-input-mode plaintext` (wir nutzen `ref` ✓)
- Bot-Tokens im commit (`.env` ist in `.gitignore` ✓)
- Workspace-Bootstrap-Templates im commit (`/workspace/HEARTBEAT.md` etc.
  gitignored ✓)

## Quellen

- [systemd unit hardening](https://systemd.io/SECURITY/)
- [OpenClaw Gateway docs](https://docs.openclaw.ai/gateway/security/)
- [Ollama Production deployment](https://github.com/ollama/ollama/blob/main/docs/linux.md)
