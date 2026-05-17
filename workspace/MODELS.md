# MODELS.md — Modell-Umschaltung

Clawbot fährt mit **einem** aktiven Modell pro Session. Wechsel = ein Skriptaufruf:
`scripts/claw-model.sh` patcht `openclaw.json` mit `jq`, startet den Gateway neu
und macht einen Smoke-Test gegen das neue Modell.

## Slots

| Slot        | Modell                                  | Wofür                                              | Voraussetzung                              |
| ----------- | --------------------------------------- | -------------------------------------------------- | ------------------------------------------ |
| `cpu`       | `ollama/gemma4:e2b`                     | **Default**, CPU-schnell, multimodal               | `ollama pull gemma4:e2b`                   |
| `gemma`     | `ollama/gemma4:e4b`                     | Qualität bei ≥10 GiB freier RAM                    | `ollama pull gemma4:e4b`                   |
| `phi`       | `ollama/phi4-mini`                      | Text-only Alternative (2.5 GB)                     | `ollama pull phi4-mini`                    |
| `gpu-local` | `ollama/qwen2.5:7b-instruct-q4_K_M`     | **PC-Produktion** mit GPU (RTX 3070 / 8 GB VRAM)   | siehe [`setup-gpu.md`](setup-gpu.md)       |
| `cloud`     | `openrouter/openai/gpt-4o-mini`         | _schlafend, optional, später_                      | `OPENROUTER_API_KEY` — derzeit deaktiviert |

## Benutzung

```bash
./scripts/claw-model.sh              # zeigt aktuellen Stand + Slots
./scripts/claw-model.sh cpu          # zu Gemma 4 e2b wechseln
./scripts/claw-model.sh gpu-local    # auf der PC-Maschine: GPU-Slot aktivieren
./scripts/claw-model.sh ollama/<x>   # beliebigen provider/model-ref direkt setzen
```

Der Switch schreibt `agents.defaults.model.primary` in `openclaw.json`, killt
den laufenden Gateway, startet ihn neu mit `gateway run --force`, wartet bis
`/health` antwortet, und macht einen Smoke-Test („Antworte mit OK.") mit
Wall-Clock-Messung.

## Cloud-Slot

`cloud` ist als **dokumentierter Platzhalter** drin und derzeit **nicht aktiviert**.
Das Repo bleibt explizit „voll lokal". Wenn du später cloud-fallback willst:
`OPENROUTER_API_KEY` in `.env`, dann `./scripts/claw-model.sh cloud`.

## Gemessene Direkt-API-Latenzen (`/api/generate`, `think:false`, `num_predict=10`)

| Slot   | Modell             | Warm-Wall | Eval tok/s | Antwort        |
| ------ | ------------------ | --------- | ---------- | -------------- |
| `cpu`  | gemma4:e2b         | 620 ms    | 28         | „OK"           |
| `phi`  | phi4-mini          | 641 ms    | 10         | „Verstanden."  |
| —      | qwen3:4b           | 1520 ms   | 8.6        | (rambling)     |

`qwen3:4b` ist hier **disqualifiziert**: ignoriert `think:false`, kommt selbst mit
60 Token Budget nie zu „OK".

## Gemessene Agent-Harness-Latenzen

Siehe [`../agent-bench-results.md`](../agent-bench-results.md) — voller
`openclaw agent --message`-Turn inkl. System-Prompt und Tool-Schemas.
Direct-API ≠ Agent-Latenz auf CPU.

## Auf welcher Maschine?

- **Dieser CPU-Container:** `cpu` ist die einzige sinnvolle Live-Option für
  Agent-Turns mit Tool-Calling-Surface. Alles anderen Slots sind hier nur
  Config-Tests.
- **PC mit RTX 3070:** `gpu-local`. Siehe `setup-gpu.md`.
- **Cloud-Slot:** nicht in diesem Repo aktivieren.
