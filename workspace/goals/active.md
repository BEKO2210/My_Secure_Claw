# active.md — Currently pursued goals

> Goals come from three sources:
> 1. User-set (explicit "make this happen")
> 2. Bot-derived from conversation patterns (e.g. user keeps asking X
>    → Goal: learn X deeply)
> 3. Bot meta-goals (see `meta.md`)
>
> Format:
> `## [<priority>] <title>`
> ` Source: user | derived | meta`
> ` Created: YYYY-MM-DD`
> ` Acceptance: <how I know it's done>`
> ` Progress: <one-line current status>`

## [P0] Make the bot stable on the PC (RTX 3070 / WSL2)

Source: user
Created: 2026-05-17
Acceptance: After `openclaw onboard` + `./scripts/install-mind.sh`,
`openclaw agent --agent main --message "Antworte mit OK."` returns
"OK" in <3 s warm with `ollama ps` showing `100% GPU`.
Progress: blocked on user re-running the install from main.

## [P1] Establish bot's own learning loop (heartbeat → learnings/ → consolidation)

Source: meta
Created: 2026-05-17
Acceptance: After 7 days of running, `learnings/OBSERVATIONS.md` has
≥20 entries, `LEARNINGS.md` has ≥3 promoted entries with `→ promoted`
marker, weekly digest exists for week 20.
Progress: substrate built (learnings/ + cron jobs). Waiting on
heartbeat to actually run on PC.

## [P2] Detect and close the 3 open knowledge gaps in learnings/knowledge-gaps.md

Source: derived
Created: 2026-05-17
Acceptance: All three gaps marked `Status: closed → knowledge/<file>.md`
and the file exists with the answer + source-URLs footer.
Progress: gaps seeded; auto-research will pick them up on PC.
