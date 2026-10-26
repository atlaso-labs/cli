# Atlaso CLI

One command gives every AI tool on your computer a shared memory.

```sh
curl -fsSL https://atlaso.ai/install.sh | bash
```

Windows (PowerShell):

```powershell
irm https://atlaso.ai/install.ps1 | iex
```

The installer links this device to your Atlaso account (your browser opens to
approve), then walks you through connecting your tools — Claude Code, Codex,
Antigravity, OpenCode, Claude Desktop. No commands to paste, no sign-in per
tool.

## Why this exists
One command installs Atlaso, links this machine to your account, and wires up the AI tools you pick, so every tool on the computer shares one memory. Everything the command does, and every `atlaso` subcommand, is in the docs. [Install](https://docs.atlaso.ai/install) · [CLI reference](https://docs.atlaso.ai/cli)

## Commands

| Command | What it does |
|---|---|
| `atlaso connect` | Link this device to your account (opens your browser) |
| `atlaso setup` | Choose which AI tools share this device's memory |
| `atlaso status` | Device, plan, and per-tool memory state (`--json` for machines) |
| `atlaso disconnect` | Disconnect this device — memories stay safe |

## What Atlaso is

A memory layer for the AI era: everything your AI tools learn about you and
your work, remembered once and carried across every tool you use.
[atlaso.ai](https://atlaso.ai) · [dashboard](https://app.atlaso.ai)

---

**Links:** [atlaso.ai](https://www.atlaso.ai) ·
[What is an AI memory layer?](https://www.atlaso.ai/what-is-an-ai-memory-layer) ·
[Docs](https://docs.atlaso.ai) ·
[Research](https://www.atlaso.ai/lab) ·
[Pricing](https://www.atlaso.ai/pricing)
