# Codex Terminal

Terminal interface for OpenAI Codex CLI in Home Assistant.

## Features

- Sidebar access through Home Assistant ingress.
- Interactive Codex CLI in a browser terminal.
- Persistent Codex auth and config in `/data/.codex`.
- Starts in `/config` for Home Assistant configuration work.
- `tmux` session persistence across sidebar reconnects.
- Generated Home Assistant context and Codex skill.
- Optional Home Assistant MCP server registration.

## Usage

Open **Codex Terminal** from the sidebar and run:

```bash
codex login
codex --cd /config
```

Refresh Home Assistant context with:

```bash
ha-context
```

List MCP servers with:

```bash
codex mcp list
```
