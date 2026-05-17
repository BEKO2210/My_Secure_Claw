# Agent-Harness Bench — CPU-Container (4 vCPU, 15 GiB RAM, kein GPU)

Gemessen: Wall-Clock einer **vollen** `openclaw agent --message …`-Invocation,
nicht der rohe Ollama-Call. Der Unterschied ist der Punkt der Übung.

## Tabelle

| Modell              | Tool-Profil | Nachricht                       | Status      | Wall        | Notiz                                                                  |
| ------------------- | ----------- | ------------------------------- | ----------- | ----------- | ---------------------------------------------------------------------- |
| `ollama/gemma4:e2b` | coding      | simple (`"Antworte mit OK"`)    | **TIMEOUT** | 29 752 ms   | Ollama war kurz tot (mid-bench wiederbelebt); auch sonst kein Token   |
| `ollama/gemma4:e2b` | minimal     | simple                          | **TIMEOUT** | 200 067 ms  | Ollama up, Gateway up, `/api/chat` hängt 120 s → Retry → 120 s → kaputt |
| `ollama/phi4-mini`  | minimal     | simple                          | **TIMEOUT** | 200 067 ms  | dasselbe Bild                                                          |
| `ollama/gemma4:e2b` | coding      | tool (`Lies IDENTITY.md…`)      | **TIMEOUT** | ≥120 000 ms | nie ein einziger Token zurück; Auto-Bench abgebrochen                  |
| `ollama/phi4-mini`  | coding      | (alles)                         | nicht beendet | —         | nach 3 Reihen Pattern eindeutig, Auto-Bench gestoppt                   |
| `ollama/*`          | minimal     | tool                            | **n/a**     | —           | `minimal` strippt File-Read; Tool-Call ohne Tool ist sinnlos           |

**Best-Case auf dieser Maschine: >200 s pro Turn. Nicht eine einzige Reply ist je angekommen.**

## Was sagt der Gateway-Log

```
[fetch-timeout]  fetch timeout after 120000ms (elapsed 120001ms)
                 operation=fetchWithSsrFGuard url=http://127.0.0.1:11434/api/chat
[agent/embedded] [llm-idle-timeout] ollama/<model> produced no reply before the
                 idle watchdog; retrying same model
[agent/embedded] embedded run failover decision: …
                 reason=timeout from=ollama/<model> profile=-
```

OpenClaw nutzt für Agent-Turns den `/api/chat`-Endpoint (nicht
`/api/generate`, gegen den der Direkt-Bench gewonnen hat). Über `/api/chat`
geht der **volle Chat-Kontext** — System-Prompt, Tool-Schemas, History — ins
Modell. Der Prompt-Eval-Teil davon kostet auf 4 CPU-Kernen >120 s, **bevor das
Modell ein einziges Token generiert**. Damit triggert OpenClaws hartcodierter
120-s-Idle-Watchdog → Retry → noch mal 120 s → Failover → Aufgabe.

Das ist nicht das Modell. Es ist nicht das Profil. Es ist die Plattform-Last
auf der Hardware.

## Verdikt für diesen CPU-Container

**Voll-lokales Agent-Verhalten ist hier nicht testbar.** Ein nutzbarer
interaktiver Bot braucht Antworten <30 s. Wir kriegen >200 s und keine
Antwort. Konsequenz, wie vom User vorab festgelegt:

> _„Liegt der beste Wert über ~15–20 s, lautet die Konsequenz: in dieser
> CPU-Container-Umgebung wird nur noch Config-/Code-Arbeit gemacht, das
> Testen von echtem Agent-Verhalten wird auf die GPU-Maschine verschoben."_

Damit:

- **Dieser Container:** ausschließlich Repo-, Config- und Skript-Arbeit
  plus Direkt-Ollama-Smoke-Tests (≤1 s). Kein Agent-Roundtrip-Test mehr
  in dieser Umgebung.
- **CPU-Slot `cpu` (gemma4:e2b)** bleibt im Repo als dokumentierter lokaler
  Default für 4-Kern-Boxen, mit dem klaren Warnhinweis hier, dass der
  Voll-Agent-Loop darauf unbrauchbar ist. Sinnvoll für Direkt-Probes,
  System-Mini-Skripte, multimodale Einzelaufrufe — nicht für interaktive
  Multi-Turn-Sessions mit Tool-Surface.
- **GPU-Slot `gpu-local` (qwen2.5:7b-instruct-q4_K_M)** ist als Config-Eintrag
  drin, wird auf der PC-Maschine durchgemessen. Siehe `workspace/setup-gpu.md`.
- **Cloud-Slot bleibt schlafend.** Voll-lokal-Ziel unverändert.

## Direkt-API als Kontrast (zur Erinnerung)

| Modell      | `/api/generate` warm | Eval tok/s | Antwort       |
| ----------- | -------------------- | ---------- | ------------- |
| gemma4:e2b  | 620 ms               | 28         | „OK"          |
| phi4-mini   | 641 ms               | 10         | „Verstanden." |

Das Modell selbst ist also schnell genug. Die Agent-Harness mit ihrer
Prompt-Last ist es nicht — auf 4 CPU-Kernen.
