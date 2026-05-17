# FEATURE_REQUESTS.md — Tools / skills I wish I had

> When a turn would have been faster or better with a tool I don't have,
> log it here. Heartbeat aggregates these; if the same wish appears 3+
> times, propose it to the user as a skill to install.

> Format:
> `## YYYY-MM-DD HH:MM tool-I-wished-for`
> ` Context: what I was doing`
> ` Why: what it would have unlocked`
> ` Count: how many times this came up`

## 2026-05-17 OpenClaw upstream-issue-poster

When I notice a gap in OpenClaw that should be filed as an upstream
issue, I currently have no clean path. Iron law #4 forbids me from
modifying the submodule.
 Context: Found that `agents.defaults.llm.idleTimeoutSeconds` is
 deprecated but the error message still suggests using it.
 Why: file the issue myself, link the user only when they want to
 weigh in.
 Count: 1

## 2026-05-17 sandbox runner for risky shell commands

When a user asks for something that could be destructive, I want to dry-
run it in a throwaway sandbox before committing.
 Context: `pkill -f openclaw.mjs gateway` accidentally targeted my
 own claude process name when the regex was too loose.
 Why: never blast-radius the host.
 Count: 1

## 2026-05-17 git-status-aware commit message generator

Currently I write commit messages by hand from session memory. A skill
that diffs the staged changes and proposes a SOUL-voice commit message
would save 10-20 lines of typing per commit.
 Count: 1
