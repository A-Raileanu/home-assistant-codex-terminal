# Codex Terminal for Home Assistant

Home Assistant add-on repository for running OpenAI Codex CLI from the Home Assistant sidebar.

## Add-ons

- [Codex Terminal](./codex-terminal): web terminal with Codex CLI, persistent auth, Home Assistant context, and optional Home Assistant MCP integration.

## Highlights

- Home Assistant best-practices skills preinstalled for Codex.
- `codex-ha doctor` diagnostics.
- `ha-safe-edit` backup and validation workflow.
- MCP mode selection for `ha-mcp`, the official HA MCP Server endpoint, both, or disabled.
- Rich generated context for entities, automations, add-ons, repairs, logs, integrations, and unavailable entities.

## Installation

1. Open Home Assistant.
2. Go to **Settings > Add-ons > Add-on Store**.
3. Open the menu and choose **Repositories**.
4. Add this repository URL.
5. Install **Codex Terminal**.
6. Start the add-on and open it from the sidebar.

## Security

This add-on gives Codex access to your Home Assistant configuration and APIs. The MCP integration can inspect and control Home Assistant entities. Only use it if you understand that Codex can suggest and run commands in this environment.
