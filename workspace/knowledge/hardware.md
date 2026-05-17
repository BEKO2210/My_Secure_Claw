# Knowledge: Host hardware profiles

What hardware I run on, and what each profile can/can't do.

## Profile A — Dev container (Claude Code Web session)

**Live as of build time.** Ephemeral — wiped on session end.

| | |
| --- | --- |
| CPU | 4 vCPU (Linux 6.x x86_64) |
| RAM | 15 GiB |
| GPU | none |
| Disk | 252 GB block device, ~5-15 GB free typical |
| Network | outbound only, no inbound |
| User | runs as root (see SECURITY.md for migration plan) |

**Capability**:
- Pull and run Ollama models up to ~10 GB resident.
- Direct `/api/chat` warm: ~9 s for trivial.
- Agent harness turn: **>200 s** typical (system prompt + tools too
  heavy for 4 cores). → use this box for config, code, doc, bench —
  NOT for live agent chat.

**Disk-budget warning**: 252 GB total but only ~15 GB regularly free
because of model storage. `ollama rm <unused>` before pulling anything new.

## Profile B — PC production target

User-owned. Where Clawbot will actually live.

| | |
| --- | --- |
| CPU | not specified (assume mid-range x86_64) |
| RAM | **16 GB** (tight — model must stay GPU-resident) |
| GPU | **NVIDIA RTX 3070, 8 GB VRAM** |
| Disk | not specified |
| Network | full home LAN, internet via ISP |
| OS | not yet declared (Linux native or Windows + WSL2) |

**Capability** (targets, not yet measured):
- `qwen2.5:7b-instruct-q4_K_M` at Q4_K_M ≈ 4.4 GB + KV cache @ 8k ctx
  ≈ 5.5-6 GB total VRAM → fits with headroom.
- Eval rate: 40-70 tok/s warm (typical for 7B Q4 on RTX 3070).
- Agent turn target: **<10 s** for simple, <30 s for tool-using.
- Cold-load: 5-15 s on first use.

**Rules for this profile**:
1. Model stays fully GPU-resident. NO CPU offload (16 GB RAM is too tight
   to safely host model layers AND OS AND other workloads).
2. `num_ctx` ≤ 16384 to keep KV cache in VRAM budget.
3. `keep_alive: "-1"` once stable (model never unloaded).
4. Disable plugins not in active use to keep system prompt small (lean
   profile inherited from dev config).

## Profile C — Future possibilities

Not configured. Listed so we know what we'd reach for.

- Tailscale-mesh access from phone → `gateway.bind: "tailnet"`,
  `gateway.tailscale.mode: "serve"`.
- External Postgres + LightRAG for 12-Layer-Edge — needs another box or
  Docker on the PC.
- Voice (talk-voice plugin) — needs ElevenLabs or Deepgram key + audio
  device.

## What does NOT exist

- No CI runner.
- No monitoring/observability stack.
- No backup target. (`openclaw backup create` is available; nothing
  scheduled.)
- No second GPU for embedding model isolation (we share the 3070 for
  both chat and `nomic-embed-text`).

## Where each profile reads its config from

- Dev container: `/home/user/My_Secure_Claw/openclaw.json` + `.env` in
  same dir.
- PC: `~/clawbot/openclaw.json` (or wherever the user clones the repo)
  + `~/clawbot/.env` (or `/etc/openclaw/gateway.env` for systemd).

State directory: `~/.openclaw/` in both cases unless `OPENCLAW_STATE_DIR`
overrides.

## Decisions to revisit on the PC

- Should the gateway bind `loopback` (max private) or `lan` (phone reach)?
  → If phone reach needed: prefer `tailnet` over `lan` to avoid
  open-on-LAN.
- Should we pre-warm both chat model AND embedding model at boot?
  → Yes; set `keep_alive` accordingly so neither evicts the other.
- Should heartbeat self-reflection use the chat model or a separate small
  one? → Initially the same model; if it slows interactive turns, split.
