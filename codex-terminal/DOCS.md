# Codex Terminal

## About

This add-on provides a web-based terminal with OpenAI Codex CLI preinstalled. It is designed for working on Home Assistant configuration, automations, dashboards, scripts, and add-ons directly from the Home Assistant sidebar.

## Installation

1. Add this repository to the Home Assistant add-on store.
2. Install **Codex Terminal**.
3. Start the add-on.
4. Open **Codex Terminal** from the sidebar.
5. Run `codex login` on first use.

## Configuration

| Option | Default | Description |
| --- | --- | --- |
| `auto_launch_codex` | `true` | Start Codex automatically when opening the terminal. |
| `ha_smart_context` | `true` | Generate Home Assistant context and a Codex skill. |
| `enable_ha_mcp` | `true` | Configure the Home Assistant MCP server for Codex. |
| `persistent_apk_packages` | `[]` | APK packages to install on startup. |
| `persistent_pip_packages` | `[]` | Python packages to install on startup. |

## Commands

```bash
codex --cd /config
codex login
codex resume --last
codex mcp list
ha-context
health-check
persist-install list
```

## Home Assistant MCP

The add-on can register `ha-mcp` with Codex. It uses the Supervisor token automatically:

```bash
codex mcp add home-assistant \
  --env HOMEASSISTANT_URL=http://supervisor/core \
  --env HOMEASSISTANT_TOKEN=$SUPERVISOR_TOKEN \
  -- uvx --index-strategy unsafe-best-match ha-mcp@3.5.1
```

Disable it by setting:

```yaml
enable_ha_mcp: false
```

## Security

Codex can read and edit mapped Home Assistant files. The Home Assistant MCP server can also expose broad control of entities, scripts, automations, dashboards, and logs. Review commands before running them on a live home.
