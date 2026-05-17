# ERRORS.md — Mistakes I have made

> Append-only. The point is not self-flagellation; the point is to never
> repeat the same mistake. Every entry ends with the rule I derived from
> it.

> Format:
> `## YYYY-MM-DD HH:MM what-I-did-wrong`
> ` → What I should have done`
> ` → Rule I now follow`

## 2026-05-17 Reported "Gateway läuft ✓" without re-checking live state

The gateway had died between the test and the report; my status was
stale by 5 minutes.
 → Should have curl'd `/health` immediately before stating the status.
 → **Rule: stale status is worse than no status. Re-check live before
   reporting "X läuft".** (Iron law #8 in MEMORY.md.)

## 2026-05-17 Claimed Gemma 4 didn't exist

User asked about "Gemma 4" and I assumed they meant Gemma 3 because of
my training cutoff. Gemma 4 was released 2026-04-02.
 → Should have searched the web before correcting the user on a topic
   that might be post-cutoff.
 → **Rule: when the user names a thing I don't recognise, search before
   doubting.**

## 2026-05-17 Patched timeoutSeconds: 600 as a "fix"

The 120s LLM timeout was hitting; I bumped `models.providers.ollama.
timeoutSeconds` to 600 and called it solved. The user named it a
Notnagel and demanded the real cause.
 → Should have asked WHY the model takes >120 s on the simplest prompt,
   not let the timeout hide it. The real cause was the 12k+ token
   system-prompt inflation, fixable with `localModelLean` + plugin trim.
 → **Rule: don't paper over with bigger timeouts. Find the prompt-eval
   bottleneck.** (Iron law #7.)

## 2026-05-17 Pre-seeded USER.md with assumed dev-stack

I wrote "Python likely in other projects" and "Editor: VS Code or
JetBrains" into USER.md as TODO-confirms.
 → Should have left dev-stack empty. User explicitly wanted me to start
   blank on tech preferences and learn through conversation.
 → **Rule: do not pattern-match across projects. One repo's stack ≠ the
   user's stack.**
