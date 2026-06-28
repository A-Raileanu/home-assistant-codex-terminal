# Codex Terminal

Codex Terminal provides a browser terminal for OpenAI Codex CLI inside Home Assistant.

The add-on follows the same usage model as Claude Terminal-style Home Assistant add-ons: open the sidebar item, log in interactively with the AI CLI, and work from `/config`.

## First Run

1. Start the add-on.
2. Open **Codex Terminal** from the sidebar.
3. Run `codex login` if Codex does not prompt automatically.
4. Start Codex with:

```bash
codex --cd /config
```

Authentication and Codex configuration persist in `/data/.codex`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `auto_launch_codex` | `true` | Automatically launch Codex when opening the terminal. |
| `ha_smart_context` | `true` | Generate Home Assistant context and a Home Assistant Codex skill on startup. |
| `ha_context_refresh_minutes` | `30` | Only regenerate automatic context when the cached file is older than this many minutes. |
| `context_detail_level` | `standard` | Context verbosity: `summary`, `standard`, or `full`. |
| `include_addon_logs` | `false` | Include add-on log samples in generated context. |
| `enable_ha_mcp` | `true` | Register the Home Assistant MCP server with Codex. |
| `mcp_mode` | `ha-mcp` | Choose `ha-mcp`, `official`, `both`, or `disabled`. |
| `ha_mcp_version` | `3.5.1` | Version used for `ha-mcp` server registration. |
| `readonly_mode` | `false` | Prevent helper-command edits. |
| `enable_device_control` | `false` | Safety marker for device-control workflows. |
| `codex_full_permissions` | `true` | Launch Codex with `--dangerously-bypass-approvals-and-sandbox` so it does not prompt for approvals. Set to `false` to re-enable per-action confirmation and the sandbox. |
| `safe_edit_backup_retention_days` | `30` | Remove backup files older than this many days. |
| `persistent_apk_packages` | `[]` | Alpine packages to install on every startup. |
| `persistent_pip_packages` | `[]` | Python packages to install on every startup. |

## Home Assistant Context

Run this command to refresh generated context:

```bash
ha-context
ha-context --force
```

It writes:

- `$CODEX_HOME/AGENTS.md`
- `$CODEX_HOME/skills/home-assistant-instance/SKILL.md` — per-installation runtime config and safety flags

Bundled separately by the add-on (synced from `/opt/skills` on version change):

- `$CODEX_HOME/skills/home-assistant/SKILL.md` — compact umbrella index with topic entrypoints (`ha-*.md`), detailed docs under `references/`, and helper scripts under `scripts/`.
- `/data/ha-context/rename_memory.json` — generated runtime memory for renamed devices/entities, derived from Home Assistant registries.

The context includes Home Assistant version, installed add-ons, entity counts, recent errors, and useful API examples.

## MCP Integration

When `enable_ha_mcp` is true, startup runs:

```bash
codex mcp add home-assistant \
  --env HOMEASSISTANT_URL=http://supervisor/core \
  --env HOMEASSISTANT_TOKEN=$SUPERVISOR_TOKEN \
  -- uvx --index-strategy unsafe-best-match ha-mcp@$HA_MCP_VERSION
```

Check it with:

```bash
codex mcp list
```

Run diagnostics with:

```bash
codex-ha doctor
```

Use safe editing with:

```bash
ha-safe-edit backup /config/configuration.yaml
ha-safe-edit check
```

MCP registration is skipped when `readonly_mode` is enabled or `enable_device_control` is false.
The MCP server gives Codex Home Assistant tools. Treat it as broad control over your Home Assistant instance.

## Persistent Packages

Install packages that survive add-on rebuilds and restarts:

```bash
persist-install apk htop
persist-install pip requests
persist-install list
```

## Troubleshooting

- Check add-on logs if the terminal does not load.
- Run `codex-ha doctor` to verify required commands, the HA API, MCP servers, skills, and safety options.
- Run `ha-context` to verify Supervisor API access.
- Disable `enable_ha_mcp` if MCP setup fails and you only need the terminal.
