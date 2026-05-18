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
| `mcp_mode` | `ha-mcp` | MCP mode: `ha-mcp`, `official`, `both`, or `disabled`. |
| `official_mcp_url` | `http://supervisor/core/api/mcp` | Streamable HTTP endpoint for the official HA MCP Server integration. |
| `readonly_mode` | `false` | Refuse helper-command edits when true. |
| `require_backup_before_edit` | `true` | Keep backup-first editing as the expected workflow. |
| `enable_device_control` | `false` | Records whether direct device-control workflows are allowed. |
| `enable_file_tools` | `true` | Records whether file helper workflows are allowed. |
| `enable_yaml_editing` | `true` | Allows `ha-safe-edit` YAML edit workflows. |
| `max_log_lines` | `80` | Limits log samples in generated context and helper commands. |
| `persistent_apk_packages` | `[]` | APK packages to install on startup. |
| `persistent_pip_packages` | `[]` | Python packages to install on startup. |

## Commands

```bash
codex --cd /config
codex login
codex resume --last
codex mcp list
codex-ha doctor
codex-ha check-config
ha-context
ha-safe-edit check
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

Use `mcp_mode: official` to register the official Home Assistant MCP Server integration endpoint, or `mcp_mode: both` to register both the local `ha-mcp` stdio server and official streamable HTTP endpoint.

Disable MCP by setting:

```yaml
mcp_mode: disabled
```

## Bundled Skills

This add-on installs these Codex skills into `/data/.codex/skills` on startup:

- `home-assistant`
- `home-assistant-best-practices`
- `ha-automation-author`
- `ha-dashboard-author`
- `ha-template-debugger`
- `ha-safe-refactor`
- `ha-add-on-developer`
- `ha-troubleshooter`

## Safe Editing

Use `ha-safe-edit` when changing YAML or other Home Assistant config files:

```bash
ha-safe-edit backup /config/configuration.yaml
ha-safe-edit check /config/configuration.yaml
ha-safe-edit /config/automations.yaml -- sh -c 'your-edit-command'
```

Backups are stored under `/data/safe-edit-backups`.

## Security

Codex can read and edit mapped Home Assistant files. The Home Assistant MCP server can also expose broad control of entities, scripts, automations, dashboards, and logs. Review commands before running them on a live home.
