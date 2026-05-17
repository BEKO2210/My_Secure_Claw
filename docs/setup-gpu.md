# setup-gpu.md — Clawbot auf dem PC mit RTX 3070 (8 GB VRAM)

Ziel: `gpu-local`-Slot in Betrieb nehmen, mit `qwen2.5:7b-instruct-q4_K_M`
**vollständig** auf der GPU. Kein CPU-Offload (16 GB RAM ist knapp).

**Modell-Begründung in Kürze:**
- Qwen 2.5 (nicht 3) — **kein Thinking-Mode**, also kein Wiederholungs-Risiko
  des qwen3:4b-Problems (das hat `think:false` ignoriert).
- Q4_K_M ≈ 4.4 GB → passt in 8 GB VRAM, lässt Platz für KV-Cache bis ~8k Kontext.
- Höchstes HumanEval (76.0) und renommiertes Tool-Calling unter 8B Parametern.

---

## 1. Voraussetzung: NVIDIA-Treiber + CUDA

### Linux (nativ)

```bash
nvidia-smi
# Erwartet: NVIDIA GeForce RTX 3070, Driver Version >= 535, CUDA Version >= 12.1
```

Wenn `nvidia-smi` nicht antwortet → `sudo ubuntu-drivers autoinstall && sudo reboot`.

### Windows: WSL2 mit CUDA-Passthrough

1. Windows-Treiber **vom NVIDIA-Site** installieren (NICHT den aus WSL-Repos).
2. WSL2 + Ubuntu 24.04:
   ```powershell
   wsl --install -d Ubuntu-24.04
   ```
3. In WSL prüfen:
   ```bash
   nvidia-smi   # muss die 3070 zeigen
   ```
   Antwortet's nicht: Windows-Treiber alt → von [nvidia.com/drivers](https://www.nvidia.com/drivers) neuen ziehen + Windows neu starten.

> **Achtung:** Native Windows-Ollama läuft auch, aber für saubere Linux-CLI-Tooling
> empfehle ich WSL2.

## 2. Ollama installieren

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Installer erkennt die GPU automatisch (Log enthält `nvidia-uvm`, `compute=8.6`).

## 3. Modell ziehen

```bash
ollama pull qwen2.5:7b-instruct-q4_K_M
```

Dauert je nach Bandbreite 3-5 Minuten (Modell ist ~4.4 GB).

## 4. **Verifizieren, dass die GPU wirklich genutzt wird**

Erste Inferenz starten, parallel in zweitem Terminal beobachten.

**Terminal A — Inferenz:**
```bash
ollama run qwen2.5:7b-instruct-q4_K_M "Antworte mit OK."
```

**Terminal B — `ollama ps` (zeigt, wo das Modell residiert):**
```bash
ollama ps
```

Erwartete Ausgabe:
```
NAME                                ID    SIZE     PROCESSOR    UNTIL
qwen2.5:7b-instruct-q4_K_M:latest   ...   ~5.5 GB  100% GPU     4 minutes from now
```

**Wenn `PROCESSOR` `CPU` oder `<100% GPU` zeigt → Stopp.** Mögliche Ursachen:
- VRAM zu klein (anderer GPU-Prozess läuft). Prüf mit `nvidia-smi`.
- Kontext zu groß. Default ist OK, aber `num_ctx > 16384` sprengt 8 GB.
- Quantisierung falsch (Q5/Q6 statt Q4_K_M).

**Zusätzlich nvidia-smi:**
```bash
nvidia-smi --query-gpu=name,memory.used,memory.free,utilization.gpu --format=csv
```
Erwartet: `memory.used ≥ 5000 MiB`, `utilization.gpu` springt auf 80-100 % während
des Tokens-Generierens.

## 5. Tokens/s benchmarken

Aus dem Repo-Root:

```bash
./scripts/bench-model.sh qwen2.5:7b-instruct-q4_K_M
```

Auf RTX 3070 typisch erwartet:
- `eval_tps`: **40-70 tokens/s** warm
- `warm total_ms`: 300-800 ms für 10-Token-Antwort
- Cold-Load: 5-15 s (Modell in VRAM laden)

Liegt `eval_tps < 10` → die GPU wird nicht voll genutzt (siehe Schritt 4).

## 6. Clawbot auf den GPU-Slot umschalten

```bash
./scripts/claw-model.sh gpu-local
```

Ausgabe sollte enden mit:
```
reply: OK
wall_ms: <unter 2000>
```

## 7. Agent-Turn live testen

```bash
node openclaw/openclaw.mjs agent \
  --agent main \
  --message "Lies workspace/IDENTITY.md und sag mir meinen Namen in einem Wort." \
  --thinking off
```

Auf der RTX 3070 sollte das **unter 10 Sekunden** liegen. Wenn nicht → Tool-Profil
auf `minimal` setzen:

```bash
jq '.tools.profile = "minimal"' openclaw.json > /tmp/oc && mv /tmp/oc openclaw.json
./scripts/claw-model.sh gpu-local    # restart picks new profile up
```

## 8. Daemon-Service (24/7)

```bash
cd openclaw
node openclaw.mjs onboard --non-interactive \
  --flow advanced --mode local --auth-choice ollama \
  --gateway-bind lan --gateway-token-ref-env OPENCLAW_GATEWAY_TOKEN \
  --install-daemon --daemon-runtime node \
  --node-manager pnpm --secret-input-mode ref --accept-risk
```

Auf Linux landet das in `systemd --user`. Status:
```bash
systemctl --user status openclaw-gateway
journalctl --user -fu openclaw-gateway
```

## Troubleshooting

| Symptom | Ursache | Fix |
| --- | --- | --- |
| `ollama ps` zeigt `100% CPU` | GPU nicht erreichbar | `nvidia-smi`, Treiber, reboot |
| `ollama ps` zeigt `xx% GPU, yy% CPU` | VRAM voll | `num_ctx` runter, andere GPU-Prozesse killen |
| Erste Antwort 30 s, dann schnell | normaler Cold-Load | ignorieren, ist einmalig |
| `eval_tps < 15` | Quant zu hoch oder CPU-Offload | exakt `:q4_K_M` Tag prüfen |
| Tool-Calls flackrig | Profil zu fett | `tools.profile: minimal` setzen |
