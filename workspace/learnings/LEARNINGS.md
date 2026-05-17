# LEARNINGS.md — Semantic insights I've earned

> Append-only by the bot during heartbeats and per-turn self-eval.
> Entries here either get promoted to `knowledge/<topic>.md` (if they
> generalise) or to MEMORY.md (if they become iron rules), and the
> promoted entry then carries the `→ promoted` marker here.

> Format per entry:
> `## YYYY-MM-DD HH:MM [tag] one-line insight`
> followed by 1-3 lines of context and the trigger (what made me notice it).

## 2026-05-17 [bootstrap] CPU agent-harness is bound by prompt_eval, not eval

Direct `/api/chat` warm = 8.7 s for "OK". Same model through agent harness
= >200 s. Difference is 100% the workspace + tool-schema injection
weight, not the model. → On low-end hosts, trimming the workspace beats
trimming the model.

→ promoted to `knowledge/clawbot-self.md`.

## 2026-05-17 [bootstrap] User aversion to Notnägel earned 3 iron laws

User reframed `timeoutSeconds: 600` as a Notnagel and demanded a real
fix. Same pattern repeated with `--no-verify`, stale status reports, and
inferred-then-claimed dev stack. → "no Notnagel-fixes", "no stale
status", "measure don't claim" are now MEMORY.md iron laws #7-9.

→ promoted to `MEMORY.md`.
