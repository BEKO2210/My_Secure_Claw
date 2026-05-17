# MODELS.md — Modell-Umschaltung

Clawbot fährt mit **einem** aktiven Modell pro Session. Das wird über die
Umgebungsvariable `CLAW_PRIMARY_MODEL` gesteuert, die `openclaw.json` per
`${CLAW_PRIMARY_MODEL:-…}` einliest. Wechsel = Variable setzen + Gateway
neustarten.

`scripts/claw-model.sh` macht beides in einem Schritt und prüft das neue
Modell sofort mit einem Mini-Prompt.

## Slots

| Slot     | Modell                           | Wofür                                      | Voraussetzung                |
| -------- | -------------------------------- | ------------------------------------------ | ---------------------------- |
| `cpu`    | `ollama/gemma4:e2b`              | **Default**, CPU-schnell, multimodal       | Ollama + `ollama pull gemma4:e2b` |
| `gemma`  | `ollama/gemma4:e4b`              | Qualität wenn ≥10 GiB freier RAM           | Ollama + `ollama pull gemma4:e4b` |
| `phi`    | `ollama/phi4-mini`               | Text-only Alternative, sehr klein (2.5 GB) | Ollama + `ollama pull phi4-mini` |
| `cloud`  | `openrouter/openai/gpt-4o-mini`  | Schnellster, am stärksten                  | `OPENROUTER_API_KEY` in `.env` |

## Benutzung

```bash
./scripts/claw-model.sh              # zeigt aktuellen Stand + Slots
./scripts/claw-model.sh cpu          # zu Gemma 4 e2b wechseln
./scripts/claw-model.sh cloud        # zu OpenRouter wechseln
./scripts/claw-model.sh ollama/qwen3:4b   # beliebigen provider/model-ref direkt setzen
```

Der Switch schreibt `CLAW_PRIMARY_MODEL=<ref>` in `.env`, killt den
laufenden Gateway, startet ihn neu mit `gateway run --force`, wartet bis
`/health` antwortet, und macht einen Smoke-Test ("Antworte mit OK.") mit
Wall-Clock-Messung.

## Gemessene Direkt-API-Latenzen (think:false, num_predict=10, num_ctx=1024)

| Slot   | Modell             | Warm-Wall | Eval tok/s | Antwort        |
| ------ | ------------------ | --------- | ---------- | -------------- |
| `cpu`  | gemma4:e2b         | 620 ms    | 28         | „OK"           |
| `phi`  | phi4-mini          | 641 ms    | 10         | „Verstanden."  |
| —      | qwen3:4b           | 1520 ms   | 8.6        | (rambling)     |

Cloud-Slot: nicht hier gemessen — variiert je nach OpenRouter-Route und Netz,
typisch <800 ms Erste-Token-Latenz, deutlich schneller in der weiteren Generation.

## Disclaimer Agent-Harness-Latenz

Diese Zahlen sind **direkter Ollama-Call**. Wenn das Modell durch den
OpenClaw-Agent-Loop läuft (System-Prompt + Tool-Schemas + Memory), wird der
`prompt_eval`-Teil deutlich teurer — auf 4 CPU-Kernen kann ein voll bestückter
Agent-Turn 30-90s dauern. Lösungen: Tool-Surface mit `tools.profile: minimal`
einschränken, `num_ctx` runter, oder Cloud-Slot benutzen.

## Wann welcher Slot?

- **Default:** `cpu` — schnell genug für tägliche Q/A, multimodal, läuft offline.
- **Wenn du tieferes Reasoning brauchst und 10 GiB frei sind:** `gemma`.
- **Wenn der Container nur 4 GiB RAM hat:** `phi` (kleiner als gemma4:e2b).
- **Wenn Latenz oder Qualität wichtiger sind als Privacy/Cost:** `cloud`.
