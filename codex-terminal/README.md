# Codex Terminal

Terminal interface for OpenAI Codex CLI in Home Assistant.

## Features

- Sidebar access through Home Assistant ingress.
- Ingress dashboard with quick actions and the full browser terminal embedded.
- Persistent Codex auth and config in `/data/.codex`.
- Starts in `/config` for Home Assistant configuration work.
- `tmux` session persistence across sidebar reconnects.
- Generated Home Assistant context in Markdown and structured JSON.
- Optional Home Assistant MCP server registration.
- Bundled HA best-practices, automation, dashboard, template, refactor, add-on, and troubleshooting skills.
- `codex-ha doctor` diagnostics and `ha-safe-edit plan/apply` staged config workflow.

## Usage

Open **Codex Terminal** from the sidebar and run:

```bash
codex login
codex --cd /config
```

Refresh Home Assistant context with:

```bash
ha-context
ha-context --force
codex-ha doctor
ha-safe-edit check
ha-safe-edit plan /config/automations.yaml -- sh -c 'your-edit-command'
ha-safe-edit apply <plan_id>
```

List MCP servers with:

```bash
codex mcp list
```
