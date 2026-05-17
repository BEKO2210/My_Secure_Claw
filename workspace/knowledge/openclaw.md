# Knowledge: OpenClaw internals

What I know about the framework I live in. Not exhaustive — what I have
actually verified or watched fail.

## Gateway

- WebSocket on `ws://<host>:<port>` (default port 18789, bind configurable
  via `gateway.bind`: `loopback` | `lan` | `tailnet` | `auto` | `custom`).
- Auth: `gateway.auth.mode: "token"` (recommended) or `"password"`. Token
  via env-ref `{ source: "env", id: "OPENCLAW_GATEWAY_TOKEN" }`.
- Subcommands of `openclaw gateway`: `run`, `restart`, `status`. Run with
  `--force` to replace anything bound to its port.
- Startup time scales with plugin count. 9 plugins ≈ 12 s, 3 plugins ≈ 3 s.

## Plugins

- Enabled by default: acpx, browser, canvas, device-pair, file-transfer,
  memory-core, phone-control, talk-voice, telegram (when channel
  configured).
- Disable individually: `plugins.entries.<id>.enabled: false`.
- `acpx` and `memory-core` are core — keep enabled.
- `telegram` (or other channel plugins) — keep enabled if the channel is
  in use.
- Everything else can be safely disabled until needed.

## Agent runtime

- The "embedded" agent path lives in `src/agents/pi-embedded-runner/`.
- Per-turn flow: workspace files → system prompt → tool schemas → user
  message → model call → tool calls in loop → final reply.
- Hard knobs:
  - `agents.defaults.timeoutSeconds` — full agent-run ceiling.
  - `models.providers.<id>.timeoutSeconds` — per-provider request timeout
    (the actual "no reply" watchdog).
  - `agents.defaults.experimental.localModelLean: true` — strips browser,
    cron, message tools from the surface. Reduces prompt size.
  - `tools.profile: "coding"|"minimal"|"messaging"|"full"` — preset bundles.

## Memory

- `memory-core` plugin: loads MEMORY.md, SOUL.md, IDENTITY.md, USER.md,
  TOOLS.md, AGENTS.md into the prompt every turn (main session only for
  MEMORY/USER).
- `memory_search`: semantic search over the workspace. Configure via
  `agents.defaults.memorySearch.{provider, model, remote.baseUrl}`.
- Hard cap per file: **20 000 chars** (truncated if exceeded). Target
  10-15k. Total target ≤150k across bootstrap files.

## Channels

- Telegram: `channels.telegram.{enabled, dmPolicy, allowFrom}`. Token from
  `TELEGRAM_BOT_TOKEN` env or `channels.telegram.botToken` literal.
  Pairing flow: bot DMs user a code → `openclaw pairing approve telegram <CODE>`.
- Discord, Slack, Signal, IRC, Matrix, … same structure, different env vars.

## Skills

- `openclaw skills list` shows available, requires-setup, ready.
- Many skills depend on external CLIs (`gh`, `1password`, `memo`, …).
- Skills install path is `node-manager` (npm | pnpm | bun).

## Useful gotchas

- `${VAR}` substitution does NOT work in `agents.defaults.model.primary`.
  OpenClaw stores the literal string and the slash trips the plugin
  loader. Patch the JSON instead.
- `apiKey` for the Ollama provider can be the literal string
  `"OLLAMA_API_KEY"` (i.e., the env-var name) or `"ollama-local"` for
  loopback/LAN. OpenClaw resolves the marker.
- `agents.defaults.llm.idleTimeoutSeconds` is DEPRECATED — replaced by
  `models.providers.<id>.timeoutSeconds`.
- Bind `lan` adds `controlUi.allowedOrigins` automatically for
  loopback origins on bind ≠ loopback.

## Process title quirk

The gateway process rewrites its `argv[0]` to `openclaw` after start, so
`pgrep -f openclaw.mjs` may miss it. Use `lsof -ti :18789` or
`pgrep -f '^openclaw'` to find the actual PID.

## Where the docs live

- Inside the repo: `openclaw/docs/`
- Live: `https://docs.openclaw.ai`
- Source for the agent runtime: `openclaw/src/agents/pi-embedded-runner/`

When the docs disagree with the source, the source wins.
